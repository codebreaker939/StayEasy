create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text,
  email text,
  role text not null default 'user',
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_full_name_not_blank check (
    full_name is null or char_length(btrim(full_name)) > 0
  ),
  constraint profiles_email_not_blank check (
    email is null or char_length(btrim(email)) > 0
  ),
  constraint profiles_role_not_blank check (char_length(btrim(role)) > 0)
);

create table public.hotels (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  city text not null,
  address text,
  description text,
  latitude double precision,
  longitude double precision,
  rating numeric,
  review_count integer not null default 0,
  amenities text[] not null default '{}',
  image_urls text[] not null default '{}',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint hotels_name_not_blank check (char_length(btrim(name)) > 0),
  constraint hotels_slug_not_blank check (char_length(btrim(slug)) > 0),
  constraint hotels_city_not_blank check (char_length(btrim(city)) > 0),
  constraint hotels_latitude_range check (latitude is null or latitude between -90 and 90),
  constraint hotels_longitude_range check (longitude is null or longitude between -180 and 180),
  constraint hotels_rating_range check (rating is null or rating between 0 and 5),
  constraint hotels_review_count_nonnegative check (review_count >= 0)
);

create table public.rooms (
  id uuid primary key default gen_random_uuid(),
  hotel_id uuid not null references public.hotels (id) on delete cascade,
  name text not null,
  description text,
  price_per_night numeric(10, 2) not null,
  capacity integer not null,
  bed_type text,
  room_size numeric,
  amenities text[] not null default '{}',
  image_urls text[] not null default '{}',
  virtual_tour_url text,
  total_inventory integer not null default 1,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint rooms_name_not_blank check (char_length(btrim(name)) > 0),
  constraint rooms_price_per_night_nonnegative check (price_per_night >= 0),
  constraint rooms_capacity_positive check (capacity > 0),
  constraint rooms_room_size_positive check (room_size is null or room_size > 0),
  constraint rooms_total_inventory_nonnegative check (total_inventory >= 0)
);

create table public.room_availability (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms (id) on delete cascade,
  date date not null,
  available_rooms integer not null,
  price_override numeric(10, 2),
  constraint room_availability_room_date_key unique (room_id, date),
  constraint room_availability_available_rooms_nonnegative check (available_rooms >= 0),
  constraint room_availability_price_override_nonnegative check (
    price_override is null or price_override >= 0
  )
);

create table public.reviews (
  id uuid primary key default gen_random_uuid(),
  hotel_id uuid not null references public.hotels (id) on delete cascade,
  room_id uuid references public.rooms (id) on delete set null,
  user_id uuid references auth.users (id) on delete set null,
  rating integer not null,
  title text,
  body text,
  stay_date date,
  is_verified boolean not null default false,
  helpful_count integer not null default 0,
  created_at timestamptz not null default now(),
  constraint reviews_rating_range check (rating between 1 and 5),
  constraint reviews_helpful_count_nonnegative check (helpful_count >= 0),
  constraint reviews_title_not_blank check (
    title is null or char_length(btrim(title)) > 0
  ),
  constraint reviews_body_not_blank check (
    body is null or char_length(btrim(body)) > 0
  )
);

create table public.bookings (
  id uuid primary key default gen_random_uuid(),
  booking_code text not null unique,
  user_id uuid references auth.users (id) on delete set null,
  hotel_id uuid not null references public.hotels (id) on delete restrict,
  room_id uuid not null references public.rooms (id) on delete restrict,
  check_in date not null,
  check_out date not null,
  guest_count integer not null,
  guest_name text not null,
  guest_email text not null,
  guest_phone text,
  subtotal numeric(10, 2) not null,
  taxes numeric(10, 2) not null,
  discount numeric(10, 2) not null default 0,
  total_price numeric(10, 2) not null,
  status text not null default 'confirmed',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint bookings_booking_code_not_blank check (char_length(btrim(booking_code)) > 0),
  constraint bookings_dates_ordered check (check_out > check_in),
  constraint bookings_guest_count_positive check (guest_count > 0),
  constraint bookings_guest_name_not_blank check (char_length(btrim(guest_name)) > 0),
  constraint bookings_guest_email_not_blank check (char_length(btrim(guest_email)) > 0),
  constraint bookings_subtotal_nonnegative check (subtotal >= 0),
  constraint bookings_taxes_nonnegative check (taxes >= 0),
  constraint bookings_discount_nonnegative check (discount >= 0),
  constraint bookings_total_price_nonnegative check (total_price >= 0),
  constraint bookings_status_not_blank check (char_length(btrim(status)) > 0),
  constraint bookings_total_price_matches_components check (
    total_price = subtotal + taxes - discount
  )
);

create index rooms_hotel_id_idx on public.rooms (hotel_id);
create index rooms_active_hotel_price_idx
  on public.rooms (hotel_id, price_per_night)
  where is_active;

create index hotels_active_city_rating_idx
  on public.hotels (city, rating desc nulls last)
  where is_active;

create index room_availability_date_room_id_idx
  on public.room_availability (date, room_id);

create index reviews_hotel_created_at_idx
  on public.reviews (hotel_id, created_at desc);
create index reviews_room_id_idx
  on public.reviews (room_id)
  where room_id is not null;
create index reviews_user_id_idx
  on public.reviews (user_id)
  where user_id is not null;

create index bookings_user_id_idx
  on public.bookings (user_id)
  where user_id is not null;
create index bookings_hotel_check_in_idx
  on public.bookings (hotel_id, check_in);
create index bookings_room_check_in_check_out_idx
  on public.bookings (room_id, check_in, check_out);

create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

create trigger hotels_set_updated_at
before update on public.hotels
for each row execute function public.set_updated_at();

create trigger rooms_set_updated_at
before update on public.rooms
for each row execute function public.set_updated_at();

create trigger bookings_set_updated_at
before update on public.bookings
for each row execute function public.set_updated_at();
