\set ON_ERROR_STOP on

-- Venturr development fixtures.
--
-- Run only against a disposable local or dedicated demo database as a
-- privileged database owner. This script:
--   1. uses deterministic UUIDs and `.test` email addresses;
--   2. records every inserted row in private.venturr_demo_manifest;
--   3. refuses to claim pre-existing rows as demo data; and
--   4. never updates conflicting rows.

begin;

create table if not exists private.venturr_demo_manifest (
  seed_name text not null,
  entity text not null,
  record_key text not null,
  inserted_at timestamptz not null default now(),
  primary key (seed_name, entity, record_key)
);

revoke all on private.venturr_demo_manifest from public, anon, authenticated;

do $guard$
declare
  v_seed constant text := 'venturr_demo_v1';
  v_campus constant uuid := '91000000-0000-4000-8000-000000000001';
  v_user_ids constant uuid[] := array[
    '92000000-0000-4000-8000-000000000001'::uuid,
    '92000000-0000-4000-8000-000000000002'::uuid,
    '92000000-0000-4000-8000-000000000003'::uuid
  ];
begin
  if exists (
    select 1
    from public.campuses c
    where (c.id = v_campus or c.slug = 'venturr-demo-campus')
      and not exists (
        select 1
        from private.venturr_demo_manifest m
        where m.seed_name = v_seed
          and m.entity = 'campus'
          and m.record_key = c.id::text
      )
  ) then
    raise exception 'A non-demo campus conflicts with the reserved Venturr demo identity';
  end if;

  if exists (
    select 1
    from auth.users u
    where (
      u.id = any(v_user_ids)
      or lower(u.email) in (
        'riya@students.venturr-demo.test',
        'kabir@students.venturr-demo.test',
        'ananya@students.venturr-demo.test'
      )
    )
    and not exists (
      select 1
      from private.venturr_demo_manifest m
      where m.seed_name = v_seed
        and m.entity = 'auth_user'
        and m.record_key = u.id::text
    )
  ) then
    raise exception 'A non-demo auth user conflicts with a reserved Venturr demo identity';
  end if;
end
$guard$;

-- These fixtures intentionally bypass application write triggers because demo
-- rows need deterministic owners and active states. Constraints remain active;
-- referential triggers are bypassed only inside this transaction.
set local session_replication_role = replica;

with inserted as (
  insert into public.campuses (
    id, slug, name, city, country_code, timezone, currency_code, is_active
  )
  values (
    '91000000-0000-4000-8000-000000000001',
    'venturr-demo-campus',
    'Venturr Demo Campus',
    'Demo City',
    'IN',
    'Asia/Kolkata',
    'INR',
    true
  )
  on conflict do nothing
  returning id
)
insert into private.venturr_demo_manifest(seed_name, entity, record_key)
select 'venturr_demo_v1', 'campus', id::text from inserted
on conflict do nothing;

with inserted as (
  insert into public.campus_email_domains(campus_id, domain, is_active)
  values (
    '91000000-0000-4000-8000-000000000001',
    'students.venturr-demo.test',
    true
  )
  on conflict do nothing
  returning campus_id, domain
)
insert into private.venturr_demo_manifest(seed_name, entity, record_key)
select 'venturr_demo_v1', 'campus_domain', campus_id::text || '|' || domain
from inserted
on conflict do nothing;

with inserted as (
  insert into public.campus_categories(campus_id, name, scope, is_active)
  values
    ('91000000-0000-4000-8000-000000000001', 'Books & notes', 'listing', true),
    ('91000000-0000-4000-8000-000000000001', 'Electronics', 'listing', true),
    ('91000000-0000-4000-8000-000000000001', 'Dorm & home', 'listing', true),
    ('91000000-0000-4000-8000-000000000001', 'Tutoring', 'service', true),
    ('91000000-0000-4000-8000-000000000001', 'Tech & debugging', 'service', true),
    ('91000000-0000-4000-8000-000000000001', 'Design & portfolio', 'service', true)
  on conflict do nothing
  returning campus_id, name
)
insert into private.venturr_demo_manifest(seed_name, entity, record_key)
select 'venturr_demo_v1', 'campus_category', campus_id::text || '|' || name
from inserted
on conflict do nothing;

with inserted as (
  insert into public.campus_pickup_zones(campus_id, label, is_active)
  values
    ('91000000-0000-4000-8000-000000000001', 'Main library entrance', true),
    ('91000000-0000-4000-8000-000000000001', 'Student centre help desk', true),
    ('91000000-0000-4000-8000-000000000001', 'North gate security desk', true)
  on conflict do nothing
  returning campus_id, label
)
insert into private.venturr_demo_manifest(seed_name, entity, record_key)
select 'venturr_demo_v1', 'campus_zone', campus_id::text || '|' || label
from inserted
on conflict do nothing;

with demo_users(id, email, display_name) as (
  values
    (
      '92000000-0000-4000-8000-000000000001'::uuid,
      'riya@students.venturr-demo.test',
      'Riya Demo'
    ),
    (
      '92000000-0000-4000-8000-000000000002'::uuid,
      'kabir@students.venturr-demo.test',
      'Kabir Demo'
    ),
    (
      '92000000-0000-4000-8000-000000000003'::uuid,
      'ananya@students.venturr-demo.test',
      'Ananya Demo'
    )
),
inserted as (
  insert into auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    confirmation_token,
    recovery_token,
    email_change_token_new,
    email_change,
    raw_app_meta_data,
    raw_user_meta_data,
    is_super_admin,
    created_at,
    updated_at
  )
  select
    '00000000-0000-0000-0000-000000000000'::uuid,
    d.id,
    'authenticated',
    'authenticated',
    d.email,
    extensions.crypt('VenturrDemoOnly!2026', extensions.gen_salt('bf')),
    now(),
    '',
    '',
    '',
    '',
    jsonb_build_object('provider', 'email', 'providers', jsonb_build_array('email')),
    jsonb_build_object('display_name', d.display_name, 'venturr_demo', true),
    false,
    now(),
    now()
  from demo_users d
  where not exists (
    select 1 from auth.users u where u.id = d.id or lower(u.email) = d.email
  )
  on conflict do nothing
  returning id
)
insert into private.venturr_demo_manifest(seed_name, entity, record_key)
select 'venturr_demo_v1', 'auth_user', id::text from inserted
on conflict do nothing;

with demo_identities(id, user_id, email) as (
  values
    (
      '92100000-0000-4000-8000-000000000001'::uuid,
      '92000000-0000-4000-8000-000000000001'::uuid,
      'riya@students.venturr-demo.test'
    ),
    (
      '92100000-0000-4000-8000-000000000002'::uuid,
      '92000000-0000-4000-8000-000000000002'::uuid,
      'kabir@students.venturr-demo.test'
    ),
    (
      '92100000-0000-4000-8000-000000000003'::uuid,
      '92000000-0000-4000-8000-000000000003'::uuid,
      'ananya@students.venturr-demo.test'
    )
),
inserted as (
  insert into auth.identities (
    id, provider_id, user_id, identity_data, provider,
    last_sign_in_at, created_at, updated_at
  )
  select
    d.id,
    d.user_id::text,
    d.user_id,
    jsonb_build_object('sub', d.user_id::text, 'email', d.email),
    'email',
    now(),
    now(),
    now()
  from demo_identities d
  where exists (select 1 from auth.users u where u.id = d.user_id)
    and not exists (
      select 1
      from auth.identities i
      where i.id = d.id or (i.provider_id = d.user_id::text and i.provider = 'email')
    )
  on conflict do nothing
  returning id
)
insert into private.venturr_demo_manifest(seed_name, entity, record_key)
select 'venturr_demo_v1', 'auth_identity', id::text from inserted
on conflict do nothing;

with demo_profiles(user_id, display_name) as (
  values
    ('92000000-0000-4000-8000-000000000001'::uuid, 'Riya Demo'),
    ('92000000-0000-4000-8000-000000000002'::uuid, 'Kabir Demo'),
    ('92000000-0000-4000-8000-000000000003'::uuid, 'Ananya Demo')
),
inserted as (
  insert into public.profiles(user_id, display_name, preferred_campus_id)
  select
    d.user_id,
    d.display_name,
    '91000000-0000-4000-8000-000000000001'::uuid
  from demo_profiles d
  where exists (select 1 from auth.users u where u.id = d.user_id)
  on conflict do nothing
  returning user_id
)
insert into private.venturr_demo_manifest(seed_name, entity, record_key)
select 'venturr_demo_v1', 'profile', user_id::text from inserted
on conflict do nothing;

with demo_memberships(id, user_id) as (
  values
    (
      '93000000-0000-4000-8000-000000000001'::uuid,
      '92000000-0000-4000-8000-000000000001'::uuid
    ),
    (
      '93000000-0000-4000-8000-000000000002'::uuid,
      '92000000-0000-4000-8000-000000000002'::uuid
    ),
    (
      '93000000-0000-4000-8000-000000000003'::uuid,
      '92000000-0000-4000-8000-000000000003'::uuid
    )
),
inserted as (
  insert into public.campus_memberships (
    id, user_id, campus_id, role, status, verified_at, expires_at
  )
  select
    d.id,
    d.user_id,
    '91000000-0000-4000-8000-000000000001'::uuid,
    'student',
    'verified',
    now(),
    now() + interval '1 year'
  from demo_memberships d
  where exists (select 1 from auth.users u where u.id = d.user_id)
  on conflict do nothing
  returning id
)
insert into private.venturr_demo_manifest(seed_name, entity, record_key)
select 'venturr_demo_v1', 'campus_membership', id::text from inserted
on conflict do nothing;

with inserted as (
  insert into public.listings (
    id,
    seller_id,
    campus_id,
    kind,
    status,
    title,
    description,
    category,
    condition,
    price_minor,
    currency_code,
    price_unit,
    pickup_zone,
    expires_at,
    published_at,
    created_at,
    updated_at
  )
  values
    (
      '94000000-0000-4000-8000-000000000001',
      '92000000-0000-4000-8000-000000000001',
      '91000000-0000-4000-8000-000000000001',
      'rent',
      'active',
      'Demo ergonomic study chair',
      'Development fixture: adjustable study chair in good working condition.',
      'Dorm & home',
      'good',
      45000,
      'INR',
      'week',
      'Main library entrance',
      now() + interval '45 days',
      now(),
      now() - interval '3 hours',
      now()
    ),
    (
      '94000000-0000-4000-8000-000000000002',
      '92000000-0000-4000-8000-000000000002',
      '91000000-0000-4000-8000-000000000001',
      'sale',
      'active',
      'Demo student laptop',
      'Development fixture: laptop with charger for testing marketplace flows.',
      'Electronics',
      'like_new',
      2800000,
      'INR',
      'item',
      'Student centre help desk',
      now() + interval '45 days',
      now(),
      now() - interval '7 hours',
      now()
    ),
    (
      '94000000-0000-4000-8000-000000000003',
      '92000000-0000-4000-8000-000000000003',
      '91000000-0000-4000-8000-000000000001',
      'sale',
      'active',
      'Demo mathematics textbook',
      'Development fixture: used course book with light highlighting.',
      'Books & notes',
      'good',
      65000,
      'INR',
      'item',
      'North gate security desk',
      now() + interval '45 days',
      now(),
      now() - interval '1 day',
      now()
    ),
    (
      '94000000-0000-4000-8000-000000000004',
      '92000000-0000-4000-8000-000000000001',
      '91000000-0000-4000-8000-000000000001',
      'free',
      'active',
      'Demo desk lamp',
      'Development fixture: compact desk lamp available for collection.',
      'Dorm & home',
      'good',
      0,
      'INR',
      'item',
      'Main library entrance',
      now() + interval '45 days',
      now(),
      now() - interval '2 days',
      now()
    )
  on conflict do nothing
  returning id
)
insert into private.venturr_demo_manifest(seed_name, entity, record_key)
select 'venturr_demo_v1', 'listing', id::text from inserted
on conflict do nothing;

with inserted as (
  insert into public.services (
    id,
    provider_id,
    campus_id,
    status,
    title,
    description,
    category,
    mode,
    base_rate_minor,
    currency_code,
    billing_unit,
    max_group_size,
    pickup_zone,
    expires_at,
    published_at,
    created_at,
    updated_at
  )
  values
    (
      '95000000-0000-4000-8000-000000000001',
      '92000000-0000-4000-8000-000000000001',
      '91000000-0000-4000-8000-000000000001',
      'active',
      'Demo calculus concept tutoring',
      'Development fixture: guided practice and revision planning without completing graded work.',
      'Tutoring',
      'in_person',
      30000,
      'INR',
      'hour',
      3,
      'Main library entrance',
      now() + interval '45 days',
      now(),
      now() - interval '5 hours',
      now()
    ),
    (
      '95000000-0000-4000-8000-000000000002',
      '92000000-0000-4000-8000-000000000002',
      '91000000-0000-4000-8000-000000000001',
      'active',
      'Demo Python debugging session',
      'Development fixture: pair-debugging and explanation for a reproducible technical problem.',
      'Tech & debugging',
      'online',
      35000,
      'INR',
      'hour',
      2,
      null,
      now() + interval '45 days',
      now(),
      now() - interval '9 hours',
      now()
    ),
    (
      '95000000-0000-4000-8000-000000000003',
      '92000000-0000-4000-8000-000000000003',
      '91000000-0000-4000-8000-000000000001',
      'active',
      'Demo portfolio feedback',
      'Development fixture: structured feedback on hierarchy, accessibility, and storytelling.',
      'Design & portfolio',
      'online',
      40000,
      'INR',
      'session',
      4,
      null,
      now() + interval '45 days',
      now(),
      now() - interval '1 day',
      now()
    )
  on conflict do nothing
  returning id
)
insert into private.venturr_demo_manifest(seed_name, entity, record_key)
select 'venturr_demo_v1', 'service', id::text from inserted
on conflict do nothing;

with inserted as (
  insert into public.service_availability (
    id,
    service_id,
    kind,
    weekday,
    start_time,
    end_time,
    timezone,
    valid_from,
    valid_until,
    is_active
  )
  values
    (
      '96000000-0000-4000-8000-000000000001',
      '95000000-0000-4000-8000-000000000001',
      'weekly',
      5,
      '16:00',
      '18:00',
      'Asia/Kolkata',
      current_date,
      current_date + 45,
      true
    ),
    (
      '96000000-0000-4000-8000-000000000002',
      '95000000-0000-4000-8000-000000000002',
      'weekly',
      6,
      '11:00',
      '13:00',
      'Asia/Kolkata',
      current_date,
      current_date + 45,
      true
    ),
    (
      '96000000-0000-4000-8000-000000000003',
      '95000000-0000-4000-8000-000000000003',
      'weekly',
      0,
      '15:00',
      '17:00',
      'Asia/Kolkata',
      current_date,
      current_date + 45,
      true
    )
  on conflict do nothing
  returning id
)
insert into private.venturr_demo_manifest(seed_name, entity, record_key)
select 'venturr_demo_v1', 'service_availability', id::text from inserted
on conflict do nothing;

set local session_replication_role = origin;

commit;

\echo 'Venturr demo records are ready.'
\echo 'Demo login password for all three .test accounts: VenturrDemoOnly!2026'
