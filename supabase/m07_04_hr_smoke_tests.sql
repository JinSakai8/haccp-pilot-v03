-- Manual smoke tests for M07 HR DB contract.
-- Run in SQL editor after applying M07 migrations.

-- 0) Context: replace with real zone ids from one venue.
-- select id, name, venue_id from public.zones order by created_at desc;

-- 1) Positive create (should return employee id + non-null venue_id)
-- select public.create_employee(
--   name_input => 'Smoke Test M07',
--   pin_hash_input => '1111111111111111111111111111111111111111111111111111111111111111',
--   role_input => 'cook',
--   sanepid_input => now() + interval '365 days',
--   zone_ids_input => array['<ZONE_ID_1>'::uuid],
--   is_active_input => true
-- );

-- 2) Duplicate pin (should fail with M07_PIN_DUPLICATE)
-- select public.create_employee(
--   name_input => 'Smoke Duplicate Pin',
--   pin_hash_input => '1111111111111111111111111111111111111111111111111111111111111111',
--   role_input => 'cook',
--   sanepid_input => now() + interval '365 days',
--   zone_ids_input => array['<ZONE_ID_1>'::uuid],
--   is_active_input => true
-- );

-- 3) Multi-venue zones (should fail with M07_ZONE_MULTI_VENUE)
-- select public.create_employee(
--   name_input => 'Smoke Multi Venue',
--   pin_hash_input => '2222222222222222222222222222222222222222222222222222222222222222',
--   role_input => 'cook',
--   sanepid_input => now() + interval '365 days',
--   zone_ids_input => array['<ZONE_ID_1>'::uuid, '<ZONE_ID_FROM_OTHER_VENUE>'::uuid],
--   is_active_input => true
-- );

-- 4) Update pin via RPC (should succeed)
-- select public.update_employee_pin(
--   employee_id => '<EMPLOYEE_ID>'::uuid,
--   new_pin_hash => '3333333333333333333333333333333333333333333333333333333333333333'
-- );

-- 5) Verify venue_id is set
-- select id, full_name, venue_id
-- from public.employees
-- where id = '<EMPLOYEE_ID>'::uuid;
