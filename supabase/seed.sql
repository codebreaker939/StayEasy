-- Re-runnable StayEasy demo catalog for October 2026. Seeded reviews deliberately
-- have NULL user_id: they represent imported demo content, never fabricated auth users.

insert into public.hotels (id, name, slug, city, address, description, latitude, longitude, rating, review_count, amenities, image_urls, is_active)
values
  ('10000000-0000-4000-8000-000000000001', 'Harbour House Mumbai', 'harbour-house-mumbai', 'Mumbai', 'Marine Drive, Mumbai', 'A quiet sea-facing stay near the promenade.', 18.9430, 72.8230, 4.6, 4, array['Wi-Fi','Breakfast','Sea view','Airport transfer'], array['https://images.unsplash.com/photo-1564501049412-61c2a3083791'], true),
  ('10000000-0000-4000-8000-000000000002', 'Palm Grove Goa', 'palm-grove-goa', 'Goa', 'Candolim, North Goa', 'Relaxed rooms a short walk from the beach.', 15.5150, 73.7680, 4.7, 4, array['Pool','Wi-Fi','Beach access','Breakfast'], array['https://images.unsplash.com/photo-1542314831-068cd1dbfeeb'], true),
  ('10000000-0000-4000-8000-000000000003', 'Lakeview Haveli Udaipur', 'lakeview-haveli-udaipur', 'Udaipur', 'Lal Ghat, Udaipur', 'Heritage-inspired rooms overlooking the old city.', 24.5760, 73.6820, 4.8, 4, array['Lake view','Restaurant','Wi-Fi','Rooftop'], array['https://images.unsplash.com/photo-1609947017136-9daf32a5eb16'], true),
  ('10000000-0000-4000-8000-000000000004', 'Cedar Ridge Manali', 'cedar-ridge-manali', 'Manali', 'Old Manali Road, Manali', 'Warm mountain rooms with valley views.', 32.2396, 77.1887, 4.5, 4, array['Mountain view','Heating','Wi-Fi','Bonfire'], array['https://images.unsplash.com/photo-1518022525094-218670c9b745'], true)
on conflict (id) do update set
  name = excluded.name, slug = excluded.slug, city = excluded.city, address = excluded.address,
  description = excluded.description, latitude = excluded.latitude, longitude = excluded.longitude,
  rating = excluded.rating, review_count = excluded.review_count, amenities = excluded.amenities,
  image_urls = excluded.image_urls, is_active = excluded.is_active;

insert into public.rooms (id, hotel_id, name, description, price_per_night, capacity, bed_type, room_size, amenities, image_urls, total_inventory, is_active)
values
  ('20000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','Harbour Queen','Sea-facing queen room',4299,2,'Queen',26,array['Wi-Fi','Sea view','Air conditioning'],array[]::text[],3,true),
  ('20000000-0000-4000-8000-000000000002','10000000-0000-4000-8000-000000000001','Marine Family Suite','Two-room suite for families',7499,4,'King + sofa bed',42,array['Wi-Fi','Living area','Sea view'],array[]::text[],2,true),
  ('20000000-0000-4000-8000-000000000003','10000000-0000-4000-8000-000000000001','City Compact','Comfortable city-side stay',3199,2,'Double',20,array['Wi-Fi','Air conditioning'],array[]::text[],4,true),
  ('20000000-0000-4000-8000-000000000004','10000000-0000-4000-8000-000000000002','Garden King','King room beside the palms',3899,2,'King',28,array['Pool access','Wi-Fi','Balcony'],array[]::text[],4,true),
  ('20000000-0000-4000-8000-000000000005','10000000-0000-4000-8000-000000000002','Poolside Studio','Spacious studio with pool access',5599,3,'King + daybed',36,array['Pool access','Wi-Fi','Breakfast'],array[]::text[],2,true),
  ('20000000-0000-4000-8000-000000000006','10000000-0000-4000-8000-000000000002','Beach Balcony','Bright room with a private balcony',4699,2,'Queen',25,array['Beach access','Wi-Fi','Balcony'],array[]::text[],3,true),
  ('20000000-0000-4000-8000-000000000007','10000000-0000-4000-8000-000000000003','Lake Heritage Room','Traditional room with lake glimpses',5299,2,'King',30,array['Lake view','Wi-Fi','Breakfast'],array[]::text[],3,true),
  ('20000000-0000-4000-8000-000000000008','10000000-0000-4000-8000-000000000003','Courtyard Suite','Large suite around a quiet courtyard',7999,4,'King + sofa bed',48,array['Rooftop','Wi-Fi','Living area'],array[]::text[],2,true),
  ('20000000-0000-4000-8000-000000000009','10000000-0000-4000-8000-000000000003','Old City Twin','Twin beds for friends',4199,2,'Twin',24,array['Wi-Fi','Air conditioning'],array[]::text[],3,true),
  ('20000000-0000-4000-8000-000000000010','10000000-0000-4000-8000-000000000004','Cedar King','Heated king room with a valley view',4499,2,'King',27,array['Heating','Mountain view','Wi-Fi'],array[]::text[],3,true),
  ('20000000-0000-4000-8000-000000000011','10000000-0000-4000-8000-000000000004','Alpine Family Loft','Loft room for a small family',6899,4,'King + loft beds',40,array['Heating','Wi-Fi','Bonfire'],array[]::text[],2,true),
  ('20000000-0000-4000-8000-000000000012','10000000-0000-4000-8000-000000000004','Pine Compact','Cosy room for two',3299,2,'Double',19,array['Heating','Wi-Fi'],array[]::text[],4,true)
on conflict (id) do update set
  hotel_id = excluded.hotel_id, name = excluded.name, description = excluded.description,
  price_per_night = excluded.price_per_night, capacity = excluded.capacity, bed_type = excluded.bed_type,
  room_size = excluded.room_size, amenities = excluded.amenities, image_urls = excluded.image_urls,
  total_inventory = excluded.total_inventory, is_active = excluded.is_active;

insert into public.room_availability (room_id, date, available_rooms, price_override)
select r.id, d::date, r.total_inventory,
  case when d::date in ('2026-10-17','2026-10-18','2026-10-19') then round(r.price_per_night * 1.15, 2) else null end
from public.rooms r
cross join generate_series(date '2026-10-01', date '2026-10-31', interval '1 day') d
where r.id between '20000000-0000-4000-8000-000000000001' and '20000000-0000-4000-8000-000000000012'
on conflict (room_id, date) do update set available_rooms = excluded.available_rooms, price_override = excluded.price_override;

-- Deliberate sold-out examples for date-selection validation.
update public.room_availability set available_rooms = 0
where (room_id, date) in (
  ('20000000-0000-4000-8000-000000000001', date '2026-10-20'),
  ('20000000-0000-4000-8000-000000000005', date '2026-10-18'),
  ('20000000-0000-4000-8000-000000000008', date '2026-10-22'),
  ('20000000-0000-4000-8000-000000000010', date '2026-10-24')
);

insert into public.reviews (id, hotel_id, room_id, user_id, rating, title, body, stay_date, is_verified, helpful_count, created_at)
values
  ('30000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','20000000-0000-4000-8000-000000000001',null,5,'Sunrise on the bay','The harbour view made an October weekend memorable.',date '2026-10-12',true,18,'2026-10-15T08:00:00Z'),
  ('30000000-0000-4000-8000-000000000002','10000000-0000-4000-8000-000000000001',null,null,4,'Great promenade base','Friendly team and an easy walk to the waterfront.',date '2026-10-04',false,5,'2026-10-06T09:00:00Z'),
  ('30000000-0000-4000-8000-000000000003','10000000-0000-4000-8000-000000000001','20000000-0000-4000-8000-000000000002',null,5,'Roomy family stay','The suite worked well for a short monsoon break.',date '2026-09-17',true,11,'2026-09-21T10:00:00Z'),
  ('30000000-0000-4000-8000-000000000004','10000000-0000-4000-8000-000000000001',null,null,4,'Reliable city hotel','A comfortable older stay with kind service.',date '2026-06-08',true,3,'2026-06-10T12:00:00Z'),
  ('30000000-0000-4000-8000-000000000005','10000000-0000-4000-8000-000000000002','20000000-0000-4000-8000-000000000004',null,5,'Palm-lined calm','The garden king was peaceful and spotless.',date '2026-10-09',true,20,'2026-10-13T08:00:00Z'),
  ('30000000-0000-4000-8000-000000000006','10000000-0000-4000-8000-000000000002',null,null,4,'Easy beach holiday','Pool and breakfast made this a very easy trip.',date '2026-10-21',false,7,'2026-10-23T08:00:00Z'),
  ('30000000-0000-4000-8000-000000000007','10000000-0000-4000-8000-000000000002','20000000-0000-4000-8000-000000000006',null,5,'Balcony breeze','Loved the balcony after a day at the beach.',date '2026-11-02',true,9,'2026-11-05T08:00:00Z'),
  ('30000000-0000-4000-8000-000000000008','10000000-0000-4000-8000-000000000002',null,null,4,'Good rainy-season value','A pleasant August escape before the crowds.',date '2026-08-16',true,4,'2026-08-18T08:00:00Z'),
  ('30000000-0000-4000-8000-000000000009','10000000-0000-4000-8000-000000000003','20000000-0000-4000-8000-000000000007',null,5,'Lake at dusk','The heritage room had a wonderful evening atmosphere.',date '2026-10-16',true,24,'2026-10-19T08:00:00Z'),
  ('30000000-0000-4000-8000-000000000010','10000000-0000-4000-8000-000000000003',null,null,5,'Thoughtful heritage stay','Rooftop dinner and warm staff stood out.',date '2026-10-02',false,6,'2026-10-04T08:00:00Z'),
  ('30000000-0000-4000-8000-000000000011','10000000-0000-4000-8000-000000000003','20000000-0000-4000-8000-000000000008',null,4,'Courtyard quiet','The suite was spacious for our September visit.',date '2026-09-28',true,12,'2026-10-01T08:00:00Z'),
  ('30000000-0000-4000-8000-000000000012','10000000-0000-4000-8000-000000000003',null,null,5,'A favourite old-city stay','Still thinking about the view from a spring trip.',date '2026-04-12',true,8,'2026-04-15T08:00:00Z'),
  ('30000000-0000-4000-8000-000000000013','10000000-0000-4000-8000-000000000004','20000000-0000-4000-8000-000000000010',null,5,'Cosy October mountains','Heating and the valley view were both excellent.',date '2026-10-14',true,17,'2026-10-17T08:00:00Z'),
  ('30000000-0000-4000-8000-000000000014','10000000-0000-4000-8000-000000000004',null,null,4,'Warm and welcoming','The bonfire was a lovely touch on our arrival.',date '2026-10-25',false,5,'2026-10-27T08:00:00Z'),
  ('30000000-0000-4000-8000-000000000015','10000000-0000-4000-8000-000000000004','20000000-0000-4000-8000-000000000011',null,5,'Family loft success','Children enjoyed the loft and everyone slept well.',date '2026-11-06',true,10,'2026-11-09T08:00:00Z'),
  ('30000000-0000-4000-8000-000000000016','10000000-0000-4000-8000-000000000004',null,null,4,'Fresh mountain air','A dependable winter getaway from last year.',date '2025-12-21',true,14,'2025-12-24T08:00:00Z')
on conflict (id) do update set
  hotel_id = excluded.hotel_id, room_id = excluded.room_id, rating = excluded.rating,
  title = excluded.title, body = excluded.body, stay_date = excluded.stay_date,
  is_verified = excluded.is_verified, helpful_count = excluded.helpful_count, created_at = excluded.created_at;
