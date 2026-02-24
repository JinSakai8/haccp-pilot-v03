begin;
do $$
declare
  auth_manager_id uuid := '00000000-0000-0000-0000-000000000001';
  auth_cook_id uuid := '00000000-0000-0000-0000-000000000002';
  employee_manager_id uuid := '00000000-0000-0000-0000-000000000011';
  employee_cook_id uuid := '00000000-0000-0000-0000-000000000012';
  zone_id_input uuid := '00000000-0000-0000-0000-000000000021';
  venue_id_input uuid := '00000000-0000-0000-0000-000000000031';
  other_venue_id_input uuid := '00000000-0000-0000-0000-000000000032';
  old_name text;
  old_nip text;
  old_address text;
  old_logo_url text;
  old_temp_interval integer;
  old_temp_threshold numeric(5,2);
  test_name text := 'M08_SMOKE_' || to_char(clock_timestamp(), 'YYYYMMDDHH24MISS');
  test_product_id uuid;
  rows_affected bigint;
begin
  if auth_manager_id::text like '00000000-%'
     or auth_cook_id::text like '00000000-%'
     or employee_manager_id::text like '00000000-%'
     or employee_cook_id::text like '00000000-%'
     or zone_id_input::text like '00000000-%'
     or venue_id_input::text like '00000000-%'
     or other_venue_id_input::text like '00000000-%' then
    raise exception 'Uzupełnij wszystkie UUID w sekcji parametrów.';
  end if;

  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', auth_manager_id::text, 'role', 'authenticated')::text,
    true
  );

  perform public.set_kiosk_context(employee_manager_id, zone_id_input);

  select v.name, v.nip, v.address, v.logo_url, v.temp_interval, v.temp_threshold
    into old_name, old_nip, old_address, old_logo_url, old_temp_interval, old_temp_threshold
  from public.venues v
  where v.id = venue_id_input;

  if old_name is null and old_address is null and old_logo_url is null and old_nip is null then
    raise exception 'Nie znaleziono venue dla venue_id_input=%', venue_id_input;
  end if;

  update public.venues
  set name = test_name,
      temp_interval = 15,
      temp_threshold = 8.0,
      nip = '1234567890',
      updated_at = now()
  where id = venue_id_input;
  get diagnostics rows_affected = row_count;
  if rows_affected <> 1 then
    raise exception 'Manager update venues: oczekiwano 1 zmodyfikowanego wiersza, otrzymano %', rows_affected;
  end if;

  begin
    update public.venues set temp_threshold = 30 where id = venue_id_input;
    raise exception 'Brak expected fail dla invalid temp_threshold.';
  exception
    when check_violation then null;
  end;

  begin
    update public.venues set temp_interval = 10 where id = venue_id_input;
    raise exception 'Brak expected fail dla invalid temp_interval.';
  exception
    when check_violation then null;
  end;

  begin
    update public.venues set nip = 'ABC-123' where id = venue_id_input;
    raise exception 'Brak expected fail dla invalid NIP.';
  exception
    when check_violation then null;
  end;

  insert into public.products(name, type, venue_id)
  values ('M08 Produkt Test', 'cooling', venue_id_input)
  returning id into test_product_id;

  update public.products
  set name = 'M08 Produkt Test Updated'
  where id = test_product_id;
  get diagnostics rows_affected = row_count;
  if rows_affected <> 1 then
    raise exception 'Manager update products: oczekiwano 1 zmodyfikowanego wiersza, otrzymano %', rows_affected;
  end if;

  delete from public.products where id = test_product_id;
  get diagnostics rows_affected = row_count;
  if rows_affected <> 1 then
    raise exception 'Manager delete products: oczekiwano 1 usuniętego wiersza, otrzymano %', rows_affected;
  end if;

  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', auth_cook_id::text, 'role', 'authenticated')::text,
    true
  );

  perform public.set_kiosk_context(employee_cook_id, zone_id_input);

  update public.venues
  set name = 'M08_COOK_ILLEGAL_UPDATE'
  where id = venue_id_input;
  get diagnostics rows_affected = row_count;
  if rows_affected <> 0 then
    raise exception 'Cook update venues: oczekiwano 0 zmodyfikowanych wierszy, otrzymano %', rows_affected;
  end if;

  begin
    insert into public.products(name, type, venue_id)
    values ('M08 Cook Illegal Insert', 'cooling', venue_id_input);
    raise exception 'Brak expected fail dla cook insert products.';
  exception
    when insufficient_privilege then null;
    when check_violation then null;
    when others then
      if position('row-level security' in lower(sqlerrm)) > 0 then
        null;
      else
        raise;
      end if;
  end;

  begin
    insert into public.products(name, type, venue_id)
    values ('M08 Manager Wrong Venue Insert', 'cooling', other_venue_id_input);
    raise exception 'Brak expected fail dla cross-venue insert products.';
  exception
    when insufficient_privilege then null;
    when check_violation then null;
    when others then
      if position('row-level security' in lower(sqlerrm)) > 0 then
        null;
      else
        raise;
      end if;
  end;

  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', auth_manager_id::text, 'role', 'authenticated')::text,
    true
  );

  perform public.set_kiosk_context(employee_manager_id, zone_id_input);
  update public.venues
  set name = old_name,
      nip = old_nip,
      address = old_address,
      logo_url = old_logo_url,
      temp_interval = old_temp_interval,
      temp_threshold = old_temp_threshold,
      updated_at = now()
  where id = venue_id_input;
  get diagnostics rows_affected = row_count;
  if rows_affected <> 1 then
    raise exception 'Przywrócenie danych venue nie powiodło się.';
  end if;

  perform public.clear_kiosk_context();
  perform set_config('request.jwt.claims', '{}', true);
end;
$$ language plpgsql;

rollback;
