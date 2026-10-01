-- StayEasy security boundary, auth profile provisioning, and transactional booking RPCs.

alter table public.profiles
  drop constraint profiles_role_not_blank,
  add constraint profiles_role_allowed check (role in ('user', 'admin'));

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.profiles
    where id = (select auth.uid())
      and role = 'admin'
  );
$$;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name, email, role)
  values (
    new.id,
    nullif(btrim(new.raw_user_meta_data ->> 'full_name'), ''),
    nullif(btrim(new.email), ''),
    'user'
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Column privileges prevent self-service changes to role, identifiers, and audit columns.
revoke all on table public.profiles, public.hotels, public.rooms,
  public.room_availability, public.reviews, public.bookings
  from anon, authenticated;

grant select on public.hotels, public.rooms, public.room_availability, public.reviews
  to anon, authenticated;
grant select, update (full_name, avatar_url) on public.profiles to authenticated;
grant insert, update, delete on public.hotels, public.rooms,
  public.room_availability, public.reviews, public.bookings to authenticated;

alter table public.profiles enable row level security;
alter table public.hotels enable row level security;
alter table public.rooms enable row level security;
alter table public.room_availability enable row level security;
alter table public.reviews enable row level security;
alter table public.bookings enable row level security;

create policy profiles_select_own_or_admin on public.profiles
  for select to authenticated
  using ((select auth.uid()) = id or (select public.is_admin()));

create policy profiles_update_own_safe_fields on public.profiles
  for update to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

create policy hotels_select_active on public.hotels
  for select to anon, authenticated
  using (is_active);
create policy hotels_admin_manage on public.hotels
  for all to authenticated
  using ((select public.is_admin()))
  with check ((select public.is_admin()));

create policy rooms_select_active_hotel on public.rooms
  for select to anon, authenticated
  using (
    (is_active and exists (
      select 1 from public.hotels h where h.id = hotel_id and h.is_active
    ))
  );
create policy rooms_admin_manage on public.rooms
  for all to authenticated
  using ((select public.is_admin()))
  with check ((select public.is_admin()));

create policy room_availability_select on public.room_availability
  for select to anon, authenticated
  using (
    exists (
      select 1
      from public.rooms r
      join public.hotels h on h.id = r.hotel_id
      where r.id = room_id and r.is_active and h.is_active
    )
  );
create policy room_availability_admin_manage on public.room_availability
  for all to authenticated
  using ((select public.is_admin()))
  with check ((select public.is_admin()));

create policy reviews_select_public on public.reviews
  for select to anon, authenticated
  using (true);
create policy reviews_insert_own_unverified on public.reviews
  for insert to authenticated
  with check (
    (select auth.uid()) = user_id
    and is_verified = false
    and helpful_count = 0
  );
create policy reviews_admin_manage on public.reviews
  for all to authenticated
  using ((select public.is_admin()))
  with check ((select public.is_admin()));

create policy bookings_select_own_or_admin on public.bookings
  for select to authenticated
  using ((select auth.uid()) = user_id or (select public.is_admin()));
create policy bookings_admin_insert on public.bookings
  for insert to authenticated
  with check ((select public.is_admin()));
create policy bookings_admin_manage on public.bookings
  for update to authenticated
  using ((select public.is_admin()))
  with check ((select public.is_admin()));
create policy bookings_admin_delete on public.bookings
  for delete to authenticated
  using ((select public.is_admin()));

create or replace function public.create_booking(
  p_room_id uuid,
  p_check_in date,
  p_check_out date,
  p_guest_count integer,
  p_guest_name text,
  p_guest_email text,
  p_guest_phone text default null
)
returns table (
  booking_id uuid,
  booking_code text,
  subtotal numeric(10, 2),
  taxes numeric(10, 2),
  discount numeric(10, 2),
  total_price numeric(10, 2),
  status text
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_hotel_id uuid;
  v_capacity integer;
  v_base_price numeric(10, 2);
  v_night date;
  v_availability integer;
  v_night_price numeric(10, 2);
  v_subtotal numeric(10, 2) := 0;
  v_taxes numeric(10, 2);
  v_discount numeric(10, 2);
  v_total numeric(10, 2);
  v_booking_id uuid;
  v_booking_code text;
  v_attempt integer := 0;
begin
  if v_user_id is null then
    raise exception 'authentication is required' using errcode = '28000';
  end if;
  if p_check_in is null or p_check_out is null or p_check_in >= p_check_out then
    raise exception 'check_out must be after check_in' using errcode = '22007';
  end if;
  if p_guest_count is null or p_guest_count <= 0 then
    raise exception 'guest_count must be positive' using errcode = '22023';
  end if;
  if nullif(btrim(p_guest_name), '') is null or nullif(btrim(p_guest_email), '') is null then
    raise exception 'guest name and email are required' using errcode = '22023';
  end if;

  select r.hotel_id, r.capacity, r.price_per_night
    into v_hotel_id, v_capacity, v_base_price
  from public.rooms r
  join public.hotels h on h.id = r.hotel_id
  where r.id = p_room_id and r.is_active and h.is_active
  for update of r, h;

  if not found then
    raise exception 'room is unavailable' using errcode = 'P0001';
  end if;
  if p_guest_count > v_capacity then
    raise exception 'guest_count exceeds room capacity' using errcode = '22023';
  end if;

  for v_night in select generate_series(p_check_in, p_check_out - 1, interval '1 day')::date loop
    select a.available_rooms, coalesce(a.price_override, v_base_price)
      into v_availability, v_night_price
    from public.room_availability a
    where a.room_id = p_room_id and a.date = v_night
    for update;

    if not found then
      raise exception 'availability is not configured for %', v_night using errcode = 'P0001';
    end if;
    if v_availability <= 0 then
      raise exception 'room is sold out for %', v_night using errcode = 'P0001';
    end if;
    v_subtotal := v_subtotal + v_night_price;
  end loop;

  v_subtotal := round(v_subtotal, 2);
  v_taxes := round(v_subtotal / 6, 2);
  v_discount := least(500.00::numeric, v_subtotal + v_taxes);
  v_total := round(v_subtotal + v_taxes - v_discount, 2);

  update public.room_availability
  set available_rooms = available_rooms - 1
  where room_id = p_room_id and date >= p_check_in and date < p_check_out;

  loop
    v_attempt := v_attempt + 1;
    v_booking_code := 'SE-' || to_char(current_date, 'YYYYMMDD') || '-'
      || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8));
    begin
      insert into public.bookings (
        booking_code, user_id, hotel_id, room_id, check_in, check_out,
        guest_count, guest_name, guest_email, guest_phone,
        subtotal, taxes, discount, total_price, status
      )
      values (
        v_booking_code, v_user_id, v_hotel_id, p_room_id, p_check_in, p_check_out,
        p_guest_count, btrim(p_guest_name), btrim(p_guest_email), nullif(btrim(p_guest_phone), ''),
        v_subtotal, v_taxes, v_discount, v_total, 'confirmed'
      )
      returning id into v_booking_id;
      exit;
    exception when unique_violation then
      if v_attempt >= 5 then
        raise;
      end if;
    end;
  end loop;

  return query select v_booking_id, v_booking_code, v_subtotal, v_taxes,
    v_discount, v_total, 'confirmed'::text;
end;
$$;

create or replace function public.cancel_booking(p_booking_id uuid)
returns table (booking_id uuid, status text, inventory_restored boolean)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_room_id uuid;
  v_check_in date;
  v_check_out date;
  v_status text;
  v_night date;
begin
  if v_user_id is null then
    raise exception 'authentication is required' using errcode = '28000';
  end if;

  select b.room_id, b.check_in, b.check_out, b.status
    into v_room_id, v_check_in, v_check_out, v_status
  from public.bookings b
  where b.id = p_booking_id and b.user_id = v_user_id
  for update;

  if not found then
    raise exception 'booking not found' using errcode = 'P0001';
  end if;
  if v_status = 'cancelled' then
    return query select p_booking_id, v_status, false;
    return;
  end if;
  if v_status <> 'confirmed' then
    raise exception 'booking is not eligible for cancellation' using errcode = 'P0001';
  end if;

  -- Lock every consumed availability row before returning inventory.
  for v_night in select generate_series(v_check_in, v_check_out - 1, interval '1 day')::date loop
    perform 1
    from public.room_availability a
    where a.room_id = v_room_id and a.date = v_night
    for update;
    if not found then
      raise exception 'availability is missing for %', v_night using errcode = 'P0001';
    end if;
  end loop;

  update public.room_availability
  set available_rooms = available_rooms + 1
  where room_id = v_room_id and date >= v_check_in and date < v_check_out;
  update public.bookings set status = 'cancelled' where id = p_booking_id;

  return query select p_booking_id, 'cancelled'::text, true;
end;
$$;

revoke all on function public.is_admin() from public, anon, authenticated;
revoke all on function public.handle_new_user() from public, anon, authenticated;
revoke all on function public.create_booking(uuid, date, date, integer, text, text, text) from public, anon, authenticated;
revoke all on function public.cancel_booking(uuid) from public, anon, authenticated;
grant execute on function public.is_admin() to authenticated;
grant execute on function public.create_booking(uuid, date, date, integer, text, text, text) to authenticated;
grant execute on function public.cancel_booking(uuid) to authenticated;
