drop extension if exists "pg_net";

create type "public"."user_role" as enum ('owner', 'manager', 'cook', 'cleaner');


  create table "public"."annotations" (
    "id" uuid not null default gen_random_uuid(),
    "sensor_id" uuid not null,
    "label" text not null,
    "comment" text,
    "created_by" uuid,
    "created_at" timestamp with time zone default now()
      );


alter table "public"."annotations" enable row level security;


  create table "public"."checklists_templates" (
    "id" uuid not null default gen_random_uuid(),
    "name" text not null,
    "type" text not null,
    "version" integer default 1,
    "definition" jsonb not null,
    "created_at" timestamp with time zone default now()
      );


alter table "public"."checklists_templates" enable row level security;


  create table "public"."employee_zones" (
    "employee_id" uuid not null,
    "zone_id" uuid not null
      );


alter table "public"."employee_zones" enable row level security;


  create table "public"."employees" (
    "id" uuid not null default gen_random_uuid(),
    "full_name" text not null,
    "pin_hash" text not null,
    "role" public.user_role not null default 'cook'::public.user_role,
    "is_active" boolean not null default true,
    "created_at" timestamp with time zone default now(),
    "sanepid_expiry" date,
    "venue_id" uuid,
    "updated_at" timestamp with time zone
      );



  create table "public"."generated_reports" (
    "id" uuid not null default gen_random_uuid(),
    "venue_id" uuid,
    "report_type" text not null,
    "generation_date" date not null,
    "created_at" timestamp with time zone not null default now(),
    "created_by" uuid,
    "storage_path" text not null,
    "metadata" jsonb default '{}'::jsonb
      );


alter table "public"."generated_reports" enable row level security;


  create table "public"."ghp_logs" (
    "id" uuid not null default gen_random_uuid(),
    "template_id" uuid,
    "template_version" integer,
    "employee_id" uuid,
    "zone_id" uuid,
    "checklist_data" jsonb not null,
    "status" text default 'compliant'::text,
    "created_at" timestamp with time zone default now()
      );


alter table "public"."ghp_logs" enable row level security;


  create table "public"."gmp_logs" (
    "id" uuid not null default gen_random_uuid(),
    "template_id" uuid,
    "template_version" integer,
    "employee_id" uuid,
    "zone_id" uuid,
    "entry_data" jsonb not null,
    "status" text default 'completed'::text,
    "created_at" timestamp with time zone default now()
      );


alter table "public"."gmp_logs" enable row level security;


  create table "public"."haccp_logs" (
    "id" uuid not null default gen_random_uuid(),
    "venue_id" uuid not null,
    "user_id" uuid not null,
    "category" text not null,
    "form_id" text not null,
    "data" jsonb not null,
    "status" text default 'OK'::text,
    "created_at" timestamp with time zone default now(),
    "zone_id" uuid
      );


alter table "public"."haccp_logs" enable row level security;


  create table "public"."products" (
    "id" uuid not null default gen_random_uuid(),
    "name" text not null,
    "type" text not null,
    "created_at" timestamp with time zone default now(),
    "venue_id" uuid
      );


alter table "public"."products" enable row level security;


  create table "public"."sensors" (
    "id" uuid not null default gen_random_uuid(),
    "name" text not null,
    "zone_id" uuid,
    "is_active" boolean default true,
    "interval_minutes" integer default 15,
    "created_at" timestamp with time zone default now()
      );


alter table "public"."sensors" enable row level security;


  create table "public"."temperature_logs" (
    "id" uuid not null default gen_random_uuid(),
    "sensor_id" uuid,
    "temperature_celsius" numeric(5,2) not null,
    "recorded_at" timestamp with time zone default now(),
    "is_alert" boolean default false,
    "is_acknowledged" boolean default false,
    "acknowledged_by" uuid,
    "acknowledged_at" timestamp with time zone
      );


alter table "public"."temperature_logs" enable row level security;


  create table "public"."venues" (
    "id" uuid not null default gen_random_uuid(),
    "name" text not null,
    "address" text,
    "nip" text,
    "logo_url" text,
    "created_at" timestamp with time zone default now(),
    "updated_at" timestamp with time zone
      );


alter table "public"."venues" enable row level security;


  create table "public"."waste_records" (
    "id" uuid not null default gen_random_uuid(),
    "venue_id" uuid not null,
    "zone_id" uuid,
    "user_id" uuid,
    "waste_type" text not null,
    "waste_code" text not null,
    "mass_kg" numeric(10,2) not null,
    "recipient_company" text not null,
    "kpo_number" text,
    "photo_url" text,
    "created_at" timestamp with time zone default now()
      );


alter table "public"."waste_records" enable row level security;


  create table "public"."zones" (
    "id" uuid not null default gen_random_uuid(),
    "name" text not null,
    "venue_id" uuid
      );


alter table "public"."zones" enable row level security;

CREATE UNIQUE INDEX annotations_pkey ON public.annotations USING btree (id);

CREATE UNIQUE INDEX checklists_templates_pkey ON public.checklists_templates USING btree (id);

CREATE UNIQUE INDEX employee_zones_pkey ON public.employee_zones USING btree (employee_id, zone_id);

CREATE UNIQUE INDEX employees_pkey ON public.employees USING btree (id);

CREATE UNIQUE INDEX generated_reports_pkey ON public.generated_reports USING btree (id);

CREATE UNIQUE INDEX ghp_logs_pkey ON public.ghp_logs USING btree (id);

CREATE UNIQUE INDEX gmp_logs_pkey ON public.gmp_logs USING btree (id);

CREATE UNIQUE INDEX haccp_logs_pkey ON public.haccp_logs USING btree (id);

CREATE UNIQUE INDEX products_name_venue_unique ON public.products USING btree (name, venue_id) NULLS NOT DISTINCT;

CREATE UNIQUE INDEX products_pkey ON public.products USING btree (id);

CREATE UNIQUE INDEX sensors_pkey ON public.sensors USING btree (id);

CREATE UNIQUE INDEX temperature_logs_pkey ON public.temperature_logs USING btree (id);

CREATE UNIQUE INDEX venues_pkey ON public.venues USING btree (id);

CREATE UNIQUE INDEX waste_records_pkey ON public.waste_records USING btree (id);

CREATE UNIQUE INDEX zones_name_key ON public.zones USING btree (name);

CREATE UNIQUE INDEX zones_pkey ON public.zones USING btree (id);

alter table "public"."annotations" add constraint "annotations_pkey" PRIMARY KEY using index "annotations_pkey";

alter table "public"."checklists_templates" add constraint "checklists_templates_pkey" PRIMARY KEY using index "checklists_templates_pkey";

alter table "public"."employee_zones" add constraint "employee_zones_pkey" PRIMARY KEY using index "employee_zones_pkey";

alter table "public"."employees" add constraint "employees_pkey" PRIMARY KEY using index "employees_pkey";

alter table "public"."generated_reports" add constraint "generated_reports_pkey" PRIMARY KEY using index "generated_reports_pkey";

alter table "public"."ghp_logs" add constraint "ghp_logs_pkey" PRIMARY KEY using index "ghp_logs_pkey";

alter table "public"."gmp_logs" add constraint "gmp_logs_pkey" PRIMARY KEY using index "gmp_logs_pkey";

alter table "public"."haccp_logs" add constraint "haccp_logs_pkey" PRIMARY KEY using index "haccp_logs_pkey";

alter table "public"."products" add constraint "products_pkey" PRIMARY KEY using index "products_pkey";

alter table "public"."sensors" add constraint "sensors_pkey" PRIMARY KEY using index "sensors_pkey";

alter table "public"."temperature_logs" add constraint "temperature_logs_pkey" PRIMARY KEY using index "temperature_logs_pkey";

alter table "public"."venues" add constraint "venues_pkey" PRIMARY KEY using index "venues_pkey";

alter table "public"."waste_records" add constraint "waste_records_pkey" PRIMARY KEY using index "waste_records_pkey";

alter table "public"."zones" add constraint "zones_pkey" PRIMARY KEY using index "zones_pkey";

alter table "public"."annotations" add constraint "annotations_created_by_fkey" FOREIGN KEY (created_by) REFERENCES public.employees(id) not valid;

alter table "public"."annotations" validate constraint "annotations_created_by_fkey";

alter table "public"."annotations" add constraint "annotations_sensor_id_fkey" FOREIGN KEY (sensor_id) REFERENCES public.sensors(id) ON DELETE CASCADE not valid;

alter table "public"."annotations" validate constraint "annotations_sensor_id_fkey";

alter table "public"."employee_zones" add constraint "employee_zones_employee_id_fkey" FOREIGN KEY (employee_id) REFERENCES public.employees(id) ON DELETE CASCADE not valid;

alter table "public"."employee_zones" validate constraint "employee_zones_employee_id_fkey";

alter table "public"."employee_zones" add constraint "employee_zones_zone_id_fkey" FOREIGN KEY (zone_id) REFERENCES public.zones(id) ON DELETE CASCADE not valid;

alter table "public"."employee_zones" validate constraint "employee_zones_zone_id_fkey";

alter table "public"."generated_reports" add constraint "generated_reports_created_by_fkey" FOREIGN KEY (created_by) REFERENCES public.employees(id) not valid;

alter table "public"."generated_reports" validate constraint "generated_reports_created_by_fkey";

alter table "public"."generated_reports" add constraint "generated_reports_report_type_check" CHECK ((report_type = ANY (ARRAY['ccp3_cooling'::text, 'waste_monthly'::text, 'gmp_daily'::text]))) not valid;

alter table "public"."generated_reports" validate constraint "generated_reports_report_type_check";

alter table "public"."generated_reports" add constraint "generated_reports_venue_id_fkey" FOREIGN KEY (venue_id) REFERENCES public.venues(id) ON DELETE CASCADE not valid;

alter table "public"."generated_reports" validate constraint "generated_reports_venue_id_fkey";

alter table "public"."ghp_logs" add constraint "ghp_logs_employee_id_fkey" FOREIGN KEY (employee_id) REFERENCES public.employees(id) not valid;

alter table "public"."ghp_logs" validate constraint "ghp_logs_employee_id_fkey";

alter table "public"."ghp_logs" add constraint "ghp_logs_template_id_fkey" FOREIGN KEY (template_id) REFERENCES public.checklists_templates(id) not valid;

alter table "public"."ghp_logs" validate constraint "ghp_logs_template_id_fkey";

alter table "public"."ghp_logs" add constraint "ghp_logs_zone_id_fkey" FOREIGN KEY (zone_id) REFERENCES public.zones(id) not valid;

alter table "public"."ghp_logs" validate constraint "ghp_logs_zone_id_fkey";

alter table "public"."gmp_logs" add constraint "gmp_logs_employee_id_fkey" FOREIGN KEY (employee_id) REFERENCES public.employees(id) not valid;

alter table "public"."gmp_logs" validate constraint "gmp_logs_employee_id_fkey";

alter table "public"."gmp_logs" add constraint "gmp_logs_template_id_fkey" FOREIGN KEY (template_id) REFERENCES public.checklists_templates(id) not valid;

alter table "public"."gmp_logs" validate constraint "gmp_logs_template_id_fkey";

alter table "public"."gmp_logs" add constraint "gmp_logs_zone_id_fkey" FOREIGN KEY (zone_id) REFERENCES public.zones(id) not valid;

alter table "public"."gmp_logs" validate constraint "gmp_logs_zone_id_fkey";

alter table "public"."products" add constraint "products_name_venue_unique" UNIQUE using index "products_name_venue_unique";

alter table "public"."products" add constraint "products_venue_id_fkey" FOREIGN KEY (venue_id) REFERENCES public.venues(id) ON DELETE CASCADE not valid;

alter table "public"."products" validate constraint "products_venue_id_fkey";

alter table "public"."sensors" add constraint "sensors_zone_id_fkey" FOREIGN KEY (zone_id) REFERENCES public.zones(id) not valid;

alter table "public"."sensors" validate constraint "sensors_zone_id_fkey";

alter table "public"."temperature_logs" add constraint "temperature_logs_acknowledged_by_fkey" FOREIGN KEY (acknowledged_by) REFERENCES public.employees(id) not valid;

alter table "public"."temperature_logs" validate constraint "temperature_logs_acknowledged_by_fkey";

alter table "public"."temperature_logs" add constraint "temperature_logs_sensor_id_fkey" FOREIGN KEY (sensor_id) REFERENCES public.sensors(id) not valid;

alter table "public"."temperature_logs" validate constraint "temperature_logs_sensor_id_fkey";

alter table "public"."waste_records" add constraint "waste_records_mass_kg_check" CHECK ((mass_kg > (0)::numeric)) not valid;

alter table "public"."waste_records" validate constraint "waste_records_mass_kg_check";

alter table "public"."waste_records" add constraint "waste_records_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.employees(id) not valid;

alter table "public"."waste_records" validate constraint "waste_records_user_id_fkey";

alter table "public"."waste_records" add constraint "waste_records_zone_id_fkey" FOREIGN KEY (zone_id) REFERENCES public.zones(id) not valid;

alter table "public"."waste_records" validate constraint "waste_records_zone_id_fkey";

alter table "public"."zones" add constraint "zones_name_key" UNIQUE using index "zones_name_key";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.check_pin_availability(pin_input text)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  exists_count int;
BEGIN
  SELECT count(*)
  INTO exists_count
  FROM employees
  WHERE pin_hash = pin_input;

  RETURN exists_count = 0;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.create_employee(name_input text, pin_hash_input text, role_input text, sanepid_input timestamp with time zone, zone_ids_input uuid[], is_active_input boolean DEFAULT true)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  new_id uuid;
  z_id uuid;
BEGIN
  -- A. Insert Employee
  INSERT INTO employees (full_name, pin_hash, role, sanepid_expiry, is_active)
  VALUES (name_input, pin_hash_input, role_input, sanepid_input, is_active_input)
  RETURNING id INTO new_id;

  -- B. Insert Zone Assignments
  IF zone_ids_input IS NOT NULL THEN
    FOREACH z_id IN ARRAY zone_ids_input
    LOOP
      INSERT INTO employee_zones (employee_id, zone_id)
      VALUES (new_id, z_id)
      ON CONFLICT DO NOTHING;
    END LOOP;
  END IF;

  RETURN new_id;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.login_with_pin(pin_input text)
 RETURNS SETOF public.employees
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  RETURN QUERY
  SELECT *
  FROM employees
  WHERE pin_hash = pin_input
    AND is_active = true;
END;
$function$
;

create or replace view "public"."public_employees" as  SELECT id,
    full_name,
    role,
    is_active,
    sanepid_expiry,
    created_at,
    updated_at
   FROM public.employees;


CREATE OR REPLACE FUNCTION public.toggle_employee_active(employee_id uuid, new_status boolean)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  UPDATE employees
  SET is_active = new_status,
      updated_at = now()
  WHERE id = employee_id;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_employee_sanepid(employee_id uuid, new_expiry timestamp with time zone)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  UPDATE employees
  SET sanepid_expiry = new_expiry,
      updated_at = now()
  WHERE id = employee_id;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$function$
;

grant delete on table "public"."annotations" to "anon";

grant insert on table "public"."annotations" to "anon";

grant references on table "public"."annotations" to "anon";

grant select on table "public"."annotations" to "anon";

grant trigger on table "public"."annotations" to "anon";

grant truncate on table "public"."annotations" to "anon";

grant update on table "public"."annotations" to "anon";

grant delete on table "public"."annotations" to "authenticated";

grant insert on table "public"."annotations" to "authenticated";

grant references on table "public"."annotations" to "authenticated";

grant select on table "public"."annotations" to "authenticated";

grant trigger on table "public"."annotations" to "authenticated";

grant truncate on table "public"."annotations" to "authenticated";

grant update on table "public"."annotations" to "authenticated";

grant delete on table "public"."annotations" to "service_role";

grant insert on table "public"."annotations" to "service_role";

grant references on table "public"."annotations" to "service_role";

grant select on table "public"."annotations" to "service_role";

grant trigger on table "public"."annotations" to "service_role";

grant truncate on table "public"."annotations" to "service_role";

grant update on table "public"."annotations" to "service_role";

grant delete on table "public"."checklists_templates" to "anon";

grant insert on table "public"."checklists_templates" to "anon";

grant references on table "public"."checklists_templates" to "anon";

grant select on table "public"."checklists_templates" to "anon";

grant trigger on table "public"."checklists_templates" to "anon";

grant truncate on table "public"."checklists_templates" to "anon";

grant update on table "public"."checklists_templates" to "anon";

grant delete on table "public"."checklists_templates" to "authenticated";

grant insert on table "public"."checklists_templates" to "authenticated";

grant references on table "public"."checklists_templates" to "authenticated";

grant select on table "public"."checklists_templates" to "authenticated";

grant trigger on table "public"."checklists_templates" to "authenticated";

grant truncate on table "public"."checklists_templates" to "authenticated";

grant update on table "public"."checklists_templates" to "authenticated";

grant delete on table "public"."checklists_templates" to "service_role";

grant insert on table "public"."checklists_templates" to "service_role";

grant references on table "public"."checklists_templates" to "service_role";

grant select on table "public"."checklists_templates" to "service_role";

grant trigger on table "public"."checklists_templates" to "service_role";

grant truncate on table "public"."checklists_templates" to "service_role";

grant update on table "public"."checklists_templates" to "service_role";

grant delete on table "public"."employee_zones" to "anon";

grant insert on table "public"."employee_zones" to "anon";

grant references on table "public"."employee_zones" to "anon";

grant select on table "public"."employee_zones" to "anon";

grant trigger on table "public"."employee_zones" to "anon";

grant truncate on table "public"."employee_zones" to "anon";

grant update on table "public"."employee_zones" to "anon";

grant delete on table "public"."employee_zones" to "authenticated";

grant insert on table "public"."employee_zones" to "authenticated";

grant references on table "public"."employee_zones" to "authenticated";

grant select on table "public"."employee_zones" to "authenticated";

grant trigger on table "public"."employee_zones" to "authenticated";

grant truncate on table "public"."employee_zones" to "authenticated";

grant update on table "public"."employee_zones" to "authenticated";

grant delete on table "public"."employee_zones" to "service_role";

grant insert on table "public"."employee_zones" to "service_role";

grant references on table "public"."employee_zones" to "service_role";

grant select on table "public"."employee_zones" to "service_role";

grant trigger on table "public"."employee_zones" to "service_role";

grant truncate on table "public"."employee_zones" to "service_role";

grant update on table "public"."employee_zones" to "service_role";

grant delete on table "public"."employees" to "anon";

grant insert on table "public"."employees" to "anon";

grant references on table "public"."employees" to "anon";

grant select on table "public"."employees" to "anon";

grant trigger on table "public"."employees" to "anon";

grant truncate on table "public"."employees" to "anon";

grant update on table "public"."employees" to "anon";

grant delete on table "public"."employees" to "authenticated";

grant insert on table "public"."employees" to "authenticated";

grant references on table "public"."employees" to "authenticated";

grant select on table "public"."employees" to "authenticated";

grant trigger on table "public"."employees" to "authenticated";

grant truncate on table "public"."employees" to "authenticated";

grant update on table "public"."employees" to "authenticated";

grant delete on table "public"."employees" to "service_role";

grant insert on table "public"."employees" to "service_role";

grant references on table "public"."employees" to "service_role";

grant select on table "public"."employees" to "service_role";

grant trigger on table "public"."employees" to "service_role";

grant truncate on table "public"."employees" to "service_role";

grant update on table "public"."employees" to "service_role";

grant delete on table "public"."generated_reports" to "anon";

grant insert on table "public"."generated_reports" to "anon";

grant references on table "public"."generated_reports" to "anon";

grant select on table "public"."generated_reports" to "anon";

grant trigger on table "public"."generated_reports" to "anon";

grant truncate on table "public"."generated_reports" to "anon";

grant update on table "public"."generated_reports" to "anon";

grant delete on table "public"."generated_reports" to "authenticated";

grant insert on table "public"."generated_reports" to "authenticated";

grant references on table "public"."generated_reports" to "authenticated";

grant select on table "public"."generated_reports" to "authenticated";

grant trigger on table "public"."generated_reports" to "authenticated";

grant truncate on table "public"."generated_reports" to "authenticated";

grant update on table "public"."generated_reports" to "authenticated";

grant delete on table "public"."generated_reports" to "service_role";

grant insert on table "public"."generated_reports" to "service_role";

grant references on table "public"."generated_reports" to "service_role";

grant select on table "public"."generated_reports" to "service_role";

grant trigger on table "public"."generated_reports" to "service_role";

grant truncate on table "public"."generated_reports" to "service_role";

grant update on table "public"."generated_reports" to "service_role";

grant delete on table "public"."ghp_logs" to "anon";

grant insert on table "public"."ghp_logs" to "anon";

grant references on table "public"."ghp_logs" to "anon";

grant select on table "public"."ghp_logs" to "anon";

grant trigger on table "public"."ghp_logs" to "anon";

grant truncate on table "public"."ghp_logs" to "anon";

grant update on table "public"."ghp_logs" to "anon";

grant delete on table "public"."ghp_logs" to "authenticated";

grant insert on table "public"."ghp_logs" to "authenticated";

grant references on table "public"."ghp_logs" to "authenticated";

grant select on table "public"."ghp_logs" to "authenticated";

grant trigger on table "public"."ghp_logs" to "authenticated";

grant truncate on table "public"."ghp_logs" to "authenticated";

grant update on table "public"."ghp_logs" to "authenticated";

grant delete on table "public"."ghp_logs" to "service_role";

grant insert on table "public"."ghp_logs" to "service_role";

grant references on table "public"."ghp_logs" to "service_role";

grant select on table "public"."ghp_logs" to "service_role";

grant trigger on table "public"."ghp_logs" to "service_role";

grant truncate on table "public"."ghp_logs" to "service_role";

grant update on table "public"."ghp_logs" to "service_role";

grant delete on table "public"."gmp_logs" to "anon";

grant insert on table "public"."gmp_logs" to "anon";

grant references on table "public"."gmp_logs" to "anon";

grant select on table "public"."gmp_logs" to "anon";

grant trigger on table "public"."gmp_logs" to "anon";

grant truncate on table "public"."gmp_logs" to "anon";

grant update on table "public"."gmp_logs" to "anon";

grant delete on table "public"."gmp_logs" to "authenticated";

grant insert on table "public"."gmp_logs" to "authenticated";

grant references on table "public"."gmp_logs" to "authenticated";

grant select on table "public"."gmp_logs" to "authenticated";

grant trigger on table "public"."gmp_logs" to "authenticated";

grant truncate on table "public"."gmp_logs" to "authenticated";

grant update on table "public"."gmp_logs" to "authenticated";

grant delete on table "public"."gmp_logs" to "service_role";

grant insert on table "public"."gmp_logs" to "service_role";

grant references on table "public"."gmp_logs" to "service_role";

grant select on table "public"."gmp_logs" to "service_role";

grant trigger on table "public"."gmp_logs" to "service_role";

grant truncate on table "public"."gmp_logs" to "service_role";

grant update on table "public"."gmp_logs" to "service_role";

grant delete on table "public"."haccp_logs" to "anon";

grant insert on table "public"."haccp_logs" to "anon";

grant references on table "public"."haccp_logs" to "anon";

grant select on table "public"."haccp_logs" to "anon";

grant trigger on table "public"."haccp_logs" to "anon";

grant truncate on table "public"."haccp_logs" to "anon";

grant update on table "public"."haccp_logs" to "anon";

grant delete on table "public"."haccp_logs" to "authenticated";

grant insert on table "public"."haccp_logs" to "authenticated";

grant references on table "public"."haccp_logs" to "authenticated";

grant select on table "public"."haccp_logs" to "authenticated";

grant trigger on table "public"."haccp_logs" to "authenticated";

grant truncate on table "public"."haccp_logs" to "authenticated";

grant update on table "public"."haccp_logs" to "authenticated";

grant delete on table "public"."haccp_logs" to "service_role";

grant insert on table "public"."haccp_logs" to "service_role";

grant references on table "public"."haccp_logs" to "service_role";

grant select on table "public"."haccp_logs" to "service_role";

grant trigger on table "public"."haccp_logs" to "service_role";

grant truncate on table "public"."haccp_logs" to "service_role";

grant update on table "public"."haccp_logs" to "service_role";

grant delete on table "public"."products" to "anon";

grant insert on table "public"."products" to "anon";

grant references on table "public"."products" to "anon";

grant select on table "public"."products" to "anon";

grant trigger on table "public"."products" to "anon";

grant truncate on table "public"."products" to "anon";

grant update on table "public"."products" to "anon";

grant delete on table "public"."products" to "authenticated";

grant insert on table "public"."products" to "authenticated";

grant references on table "public"."products" to "authenticated";

grant select on table "public"."products" to "authenticated";

grant trigger on table "public"."products" to "authenticated";

grant truncate on table "public"."products" to "authenticated";

grant update on table "public"."products" to "authenticated";

grant delete on table "public"."products" to "service_role";

grant insert on table "public"."products" to "service_role";

grant references on table "public"."products" to "service_role";

grant select on table "public"."products" to "service_role";

grant trigger on table "public"."products" to "service_role";

grant truncate on table "public"."products" to "service_role";

grant update on table "public"."products" to "service_role";

grant delete on table "public"."sensors" to "anon";

grant insert on table "public"."sensors" to "anon";

grant references on table "public"."sensors" to "anon";

grant select on table "public"."sensors" to "anon";

grant trigger on table "public"."sensors" to "anon";

grant truncate on table "public"."sensors" to "anon";

grant update on table "public"."sensors" to "anon";

grant delete on table "public"."sensors" to "authenticated";

grant insert on table "public"."sensors" to "authenticated";

grant references on table "public"."sensors" to "authenticated";

grant select on table "public"."sensors" to "authenticated";

grant trigger on table "public"."sensors" to "authenticated";

grant truncate on table "public"."sensors" to "authenticated";

grant update on table "public"."sensors" to "authenticated";

grant delete on table "public"."sensors" to "service_role";

grant insert on table "public"."sensors" to "service_role";

grant references on table "public"."sensors" to "service_role";

grant select on table "public"."sensors" to "service_role";

grant trigger on table "public"."sensors" to "service_role";

grant truncate on table "public"."sensors" to "service_role";

grant update on table "public"."sensors" to "service_role";

grant delete on table "public"."temperature_logs" to "anon";

grant insert on table "public"."temperature_logs" to "anon";

grant references on table "public"."temperature_logs" to "anon";

grant select on table "public"."temperature_logs" to "anon";

grant trigger on table "public"."temperature_logs" to "anon";

grant truncate on table "public"."temperature_logs" to "anon";

grant update on table "public"."temperature_logs" to "anon";

grant delete on table "public"."temperature_logs" to "authenticated";

grant insert on table "public"."temperature_logs" to "authenticated";

grant references on table "public"."temperature_logs" to "authenticated";

grant select on table "public"."temperature_logs" to "authenticated";

grant trigger on table "public"."temperature_logs" to "authenticated";

grant truncate on table "public"."temperature_logs" to "authenticated";

grant update on table "public"."temperature_logs" to "authenticated";

grant delete on table "public"."temperature_logs" to "service_role";

grant insert on table "public"."temperature_logs" to "service_role";

grant references on table "public"."temperature_logs" to "service_role";

grant select on table "public"."temperature_logs" to "service_role";

grant trigger on table "public"."temperature_logs" to "service_role";

grant truncate on table "public"."temperature_logs" to "service_role";

grant update on table "public"."temperature_logs" to "service_role";

grant delete on table "public"."venues" to "anon";

grant insert on table "public"."venues" to "anon";

grant references on table "public"."venues" to "anon";

grant select on table "public"."venues" to "anon";

grant trigger on table "public"."venues" to "anon";

grant truncate on table "public"."venues" to "anon";

grant update on table "public"."venues" to "anon";

grant delete on table "public"."venues" to "authenticated";

grant insert on table "public"."venues" to "authenticated";

grant references on table "public"."venues" to "authenticated";

grant select on table "public"."venues" to "authenticated";

grant trigger on table "public"."venues" to "authenticated";

grant truncate on table "public"."venues" to "authenticated";

grant update on table "public"."venues" to "authenticated";

grant delete on table "public"."venues" to "service_role";

grant insert on table "public"."venues" to "service_role";

grant references on table "public"."venues" to "service_role";

grant select on table "public"."venues" to "service_role";

grant trigger on table "public"."venues" to "service_role";

grant truncate on table "public"."venues" to "service_role";

grant update on table "public"."venues" to "service_role";

grant delete on table "public"."waste_records" to "anon";

grant insert on table "public"."waste_records" to "anon";

grant references on table "public"."waste_records" to "anon";

grant select on table "public"."waste_records" to "anon";

grant trigger on table "public"."waste_records" to "anon";

grant truncate on table "public"."waste_records" to "anon";

grant update on table "public"."waste_records" to "anon";

grant delete on table "public"."waste_records" to "authenticated";

grant insert on table "public"."waste_records" to "authenticated";

grant references on table "public"."waste_records" to "authenticated";

grant select on table "public"."waste_records" to "authenticated";

grant trigger on table "public"."waste_records" to "authenticated";

grant truncate on table "public"."waste_records" to "authenticated";

grant update on table "public"."waste_records" to "authenticated";

grant delete on table "public"."waste_records" to "service_role";

grant insert on table "public"."waste_records" to "service_role";

grant references on table "public"."waste_records" to "service_role";

grant select on table "public"."waste_records" to "service_role";

grant trigger on table "public"."waste_records" to "service_role";

grant truncate on table "public"."waste_records" to "service_role";

grant update on table "public"."waste_records" to "service_role";

grant delete on table "public"."zones" to "anon";

grant insert on table "public"."zones" to "anon";

grant references on table "public"."zones" to "anon";

grant select on table "public"."zones" to "anon";

grant trigger on table "public"."zones" to "anon";

grant truncate on table "public"."zones" to "anon";

grant update on table "public"."zones" to "anon";

grant delete on table "public"."zones" to "authenticated";

grant insert on table "public"."zones" to "authenticated";

grant references on table "public"."zones" to "authenticated";

grant select on table "public"."zones" to "authenticated";

grant trigger on table "public"."zones" to "authenticated";

grant truncate on table "public"."zones" to "authenticated";

grant update on table "public"."zones" to "authenticated";

grant delete on table "public"."zones" to "service_role";

grant insert on table "public"."zones" to "service_role";

grant references on table "public"."zones" to "service_role";

grant select on table "public"."zones" to "service_role";

grant trigger on table "public"."zones" to "service_role";

grant truncate on table "public"."zones" to "service_role";

grant update on table "public"."zones" to "service_role";


  create policy "Annotations insertable"
  on "public"."annotations"
  as permissive
  for insert
  to anon, authenticated
with check (true);



  create policy "Annotations readable"
  on "public"."annotations"
  as permissive
  for select
  to anon, authenticated
using (true);



  create policy "Allow select for all employees"
  on "public"."checklists_templates"
  as permissive
  for select
  to public
using (true);



  create policy "Enable read access for authenticated users"
  on "public"."employee_zones"
  as permissive
  for select
  to public
using ((auth.role() = 'authenticated'::text));



  create policy "Odczyt przypisań dla Kiosku"
  on "public"."employee_zones"
  as permissive
  for select
  to public
using (true);



  create policy "Admin only insert"
  on "public"."employees"
  as permissive
  for insert
  to service_role
with check (true);



  create policy "Employees can only see colleagues from the same venue"
  on "public"."employees"
  as permissive
  for select
  to public
using ((venue_id = ( SELECT employees_1.venue_id
   FROM public.employees employees_1
  WHERE (employees_1.id = auth.uid()))));



  create policy "Odczyt pracowników dla Kiosku"
  on "public"."employees"
  as permissive
  for select
  to public
using (true);



  create policy "Only Managers/Owners can modify employees"
  on "public"."employees"
  as permissive
  for all
  to public
using (((( SELECT employees_1.role
   FROM public.employees employees_1
  WHERE (employees_1.id = auth.uid())) = ANY (ARRAY['manager'::public.user_role, 'owner'::public.user_role])) AND (venue_id = ( SELECT employees_1.venue_id
   FROM public.employees employees_1
  WHERE (employees_1.id = auth.uid())))));



  create policy "allow_updates_service_role"
  on "public"."employees"
  as permissive
  for update
  to service_role
using (true);



  create policy "simple_login_policy"
  on "public"."employees"
  as permissive
  for select
  to public
using (true);



  create policy "Enable insert for all"
  on "public"."generated_reports"
  as permissive
  for insert
  to anon, authenticated
with check (true);



  create policy "Enable read access for all"
  on "public"."generated_reports"
  as permissive
  for select
  to anon, authenticated
using (true);



  create policy "Allow insert for all employees"
  on "public"."ghp_logs"
  as permissive
  for insert
  to public
with check (true);



  create policy "Allow insert for all employees"
  on "public"."gmp_logs"
  as permissive
  for insert
  to public
with check (true);



  create policy "Enable insert access for authenticated users"
  on "public"."haccp_logs"
  as permissive
  for insert
  to public
with check (true);



  create policy "Enable read access for authenticated users"
  on "public"."haccp_logs"
  as permissive
  for select
  to public
using (true);



  create policy "Allow public read access"
  on "public"."products"
  as permissive
  for select
  to public
using (true);



  create policy "Enable read access for all"
  on "public"."products"
  as permissive
  for select
  to public
using (true);



  create policy "Sensors readable by all"
  on "public"."sensors"
  as permissive
  for select
  to anon, authenticated
using (true);



  create policy "Enable insert access for authenticated users"
  on "public"."temperature_logs"
  as permissive
  for insert
  to public
with check ((auth.role() = 'authenticated'::text));



  create policy "Logs readable by all"
  on "public"."temperature_logs"
  as permissive
  for select
  to anon, authenticated
using (true);



  create policy "Logs updateable by all"
  on "public"."temperature_logs"
  as permissive
  for update
  to anon, authenticated
using (true)
with check (true);



  create policy "Enable read access for authenticated users"
  on "public"."venues"
  as permissive
  for select
  to public
using ((auth.role() = 'authenticated'::text));



  create policy "Employees can view/insert own venue waste"
  on "public"."waste_records"
  as permissive
  for all
  to public
using (true);



  create policy "Enable read access for authenticated users"
  on "public"."zones"
  as permissive
  for select
  to public
using ((auth.role() = 'authenticated'::text));



  create policy "Odczyt stref dla Kiosku"
  on "public"."zones"
  as permissive
  for select
  to public
using (true);


CREATE TRIGGER set_employees_updated_at BEFORE UPDATE ON public.employees FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER set_haccp_logs_updated_at BEFORE UPDATE ON public.haccp_logs FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER set_venues_updated_at BEFORE UPDATE ON public.venues FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


  create policy "Allow all reads from reports"
  on "storage"."objects"
  as permissive
  for select
  to anon, authenticated
using ((bucket_id = 'reports'::text));



  create policy "Allow all uploads to reports"
  on "storage"."objects"
  as permissive
  for insert
  to anon, authenticated
with check ((bucket_id = 'reports'::text));



