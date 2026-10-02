-- RLS already limits rows to the current customer or an administrator.
grant select on table public.bookings to authenticated;
