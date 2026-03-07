-- Sprint 1 hotfix: align GHP form_id constraint with app contract (ghp_*)
-- Keep legacy form ids for backward compatibility.

begin;

alter table public.haccp_logs
  drop constraint if exists haccp_logs_form_id_check;

alter table public.haccp_logs
  add constraint haccp_logs_form_id_check
  check (
    (category = 'gmp' and form_id in (
      'food_cooling',
      'meat_roasting',
      'delivery_control',
      'meat_roasting_daily',
      'delivery_control_daily'
    ))
    or
    (category = 'ghp' and form_id in (
      'ghp_personnel',
      'ghp_rooms',
      'ghp_maintenance',
      'ghp_chemicals',
      'personnel',
      'rooms',
      'maintenance',
      'chemicals'
    ))
  ) not valid;

commit;