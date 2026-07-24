begin;

create extension if not exists pgtap with schema extensions;
set local search_path = public, extensions;

select no_plan();

select is(
  (
    select count(*)::integer
    from pg_catalog.pg_class c
    join pg_catalog.pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relkind in ('r', 'p')
      and (not c.relrowsecurity or not c.relforcerowsecurity)
  ),
  0,
  'every public base table has RLS enabled and forced'
);

select is(
  (
    select count(*)::integer
    from pg_catalog.pg_proc p
    join pg_catalog.pg_namespace n on n.oid = p.pronamespace
    where n.nspname in ('public', 'private')
      and p.prosecdef
      and not coalesce(p.proconfig, '{}'::text[]) @> array['search_path=""']
      and not coalesce(p.proconfig, '{}'::text[]) @> array['search_path=']
  ),
  0,
  'all SECURITY DEFINER functions pin an empty search_path'
);

select is(
  has_schema_privilege('anon', 'private', 'usage'),
  false,
  'anon cannot use the private schema'
);

select is(
  has_schema_privilege('authenticated', 'public', 'create'),
  false,
  'authenticated users cannot create objects in the API schema'
);

select is(
  has_table_privilege('authenticated', 'private.audit_events', 'select'),
  false,
  'authenticated users cannot read private audit events'
);

select is(
  has_table_privilege('authenticated', 'public.bookings', 'insert'),
  false,
  'clients cannot forge bookings directly'
);

select is(
  has_column_privilege('authenticated', 'public.listings', 'status', 'update'),
  false,
  'clients cannot directly update listing workflow state'
);

select is(
  (
    select count(*)::integer
    from storage.buckets
    where id in ('listing-upload-staging', 'listing-images', 'avatars')
  ),
  3,
  'required Storage buckets exist'
);

select is(
  (select public from storage.buckets where id = 'listing-images'),
  false,
  'processed listing images remain private'
);

select is(
  (
    select count(*)::integer
    from pg_catalog.pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and cmd = 'INSERT'
      and 'authenticated'::name = any(roles)
  ),
  0,
  'browser role has no direct Storage upload policy'
);

select is(
  (
    select count(*)::integer
    from pg_catalog.pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and cmd = 'INSERT'
      and policyname like 'processed_listing_image%'
  ),
  0,
  'no authenticated insert policy exists for processed listing images'
);

select is(
  has_table_privilege('authenticated', 'public.listing_images', 'insert'),
  false,
  'clients cannot forge processed image metadata'
);

select is(
  has_table_privilege('authenticated', 'public.listing_image_uploads', 'insert'),
  false,
  'clients cannot bypass the immutable image reservation RPC'
);

select is(
  has_table_privilege('authenticated', 'public.campus_memberships', 'insert'),
  false,
  'campus membership requests use the derived RPC boundary'
);

select is(
  has_function_privilege(
    'authenticated',
    'public.claim_campus_from_verified_email()',
    'execute'
  ),
  true,
  'authenticated users can claim only their own email-matched campus'
);

select is(
  has_function_privilege(
    'anon',
    'public.claim_campus_from_verified_email()',
    'execute'
  ),
  false,
  'anonymous users cannot call campus detection'
);

insert into public.campuses(
  id,
  slug,
  name,
  city,
  country_code,
  timezone,
  currency_code
)
values (
  '10000000-0000-0000-0000-000000000001',
  'policy-test-campus',
  'Policy Test Campus',
  'Test City',
  'IN',
  'Asia/Kolkata',
  'INR'
);

insert into public.campus_categories(campus_id, name, scope, is_active)
values
  (
    '10000000-0000-0000-0000-000000000001',
    'Books and study',
    'listing',
    true
  ),
  (
    '10000000-0000-0000-0000-000000000001',
    'Other',
    'both',
    true
  ),
  (
    '10000000-0000-0000-0000-000000000001',
    'Inactive category',
    'listing',
    false
  );

insert into public.campus_pickup_zones(campus_id, label)
values (
  '10000000-0000-0000-0000-000000000001',
  'Library help desk'
);

insert into auth.users(
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at
)
values
  (
    '20000000-0000-0000-0000-000000000001',
    'authenticated',
    'authenticated',
    'seller@policy.test',
    '',
    now(),
    '{}'::jsonb,
    '{"display_name":"Seller"}'::jsonb,
    now(),
    now()
  ),
  (
    '20000000-0000-0000-0000-000000000002',
    'authenticated',
    'authenticated',
    'buyer@policy.test',
    '',
    now(),
    '{}'::jsonb,
    '{"display_name":"Buyer"}'::jsonb,
    now(),
    now()
  ),
  (
    '20000000-0000-0000-0000-000000000003',
    'authenticated',
    'authenticated',
    'outsider@policy.test',
    '',
    now(),
    '{}'::jsonb,
    '{"display_name":"Outsider"}'::jsonb,
    now(),
    now()
  ),
  (
    '20000000-0000-0000-0000-000000000004',
    'authenticated',
    'authenticated',
    'moderator@policy.test',
    '',
    now(),
    '{}'::jsonb,
    '{"display_name":"Moderator"}'::jsonb,
    now(),
    now()
  ),
  (
    '20000000-0000-0000-0000-000000000005',
    'authenticated',
    'authenticated',
    'unconfirmed@policy.test',
    '',
    null,
    '{}'::jsonb,
    '{"display_name":"Unconfirmed"}'::jsonb,
    now(),
    now()
  );

insert into private.moderator_assignments(
  user_id,
  campus_id,
  role
)
values (
  '20000000-0000-0000-0000-000000000004',
  '10000000-0000-0000-0000-000000000001',
  'admin'
);

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '20000000-0000-0000-0000-000000000005',
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);

select throws_ok(
  $$
    select *
    from public.request_campus_membership(
      '10000000-0000-0000-0000-000000000001'
    )
  $$,
  '42501',
  null,
  'unconfirmed email cannot request a campus membership'
);

reset role;
set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '20000000-0000-0000-0000-000000000001',
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);
select lives_ok(
  $$
    select *
    from public.request_campus_membership(
      '10000000-0000-0000-0000-000000000001'
    )
  $$,
  'seller can request their own campus membership'
);

reset role;
select set_config(
  'test.seller_membership_id',
  (
    select id::text
    from public.campus_memberships
    where user_id = '20000000-0000-0000-0000-000000000001'
  ),
  true
);
set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '20000000-0000-0000-0000-000000000002',
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);
select lives_ok(
  $$
    select *
    from public.request_campus_membership(
      '10000000-0000-0000-0000-000000000001'
    )
  $$,
  'buyer can request their own campus membership'
);

reset role;
select set_config(
  'test.buyer_membership_id',
  (
    select id::text
    from public.campus_memberships
    where user_id = '20000000-0000-0000-0000-000000000002'
  ),
  true
);
set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '20000000-0000-0000-0000-000000000004',
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);
select set_config(
  'request.jwt.claims',
  '{"sub":"20000000-0000-0000-0000-000000000004","role":"authenticated","aal":"aal1"}',
  true
);

select throws_ok(
  $$
    select public.moderate_membership(
      current_setting('test.seller_membership_id')::uuid,
      'verified',
      'must require MFA'
    )
  $$,
  '42501',
  null,
  'AAL1 moderator sessions cannot perform privileged actions'
);

select set_config(
  'request.jwt.claims',
  '{"sub":"20000000-0000-0000-0000-000000000004","role":"authenticated","aal":"aal2"}',
  true
);

select lives_ok(
  $$
    select public.moderate_membership(
      current_setting('test.seller_membership_id')::uuid,
      'verified',
      'policy test'
    )
  $$,
  'moderator can verify seller membership through audited RPC'
);

select lives_ok(
  $$
    select public.moderate_membership(
      current_setting('test.buyer_membership_id')::uuid,
      'verified',
      'policy test'
    )
  $$,
  'moderator can verify buyer membership through audited RPC'
);

reset role;
set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '20000000-0000-0000-0000-000000000001',
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);

select lives_ok(
  $$
    insert into public.listings(
      campus_id,
      kind,
      title,
      description,
      category,
      condition,
      price_minor,
      price_unit,
      quantity,
      pickup_zone
    )
    values (
      '10000000-0000-0000-0000-000000000001',
      'wanted',
      'Wanted policy test calculator',
      'Looking for a working scientific calculator for class.',
      'Books and study',
      'not_applicable',
      150000,
      'item',
      1,
      'Library help desk'
    )
  $$,
  'verified seller can create a draft listing'
);

select is(
  (
    select status::text
    from public.listings
    where title = 'Wanted policy test calculator'
  ),
  'draft',
  'direct listing inserts are normalized to draft'
);

select lives_ok(
  $$
    select public.reserve_listing_image(
      (
        select id
        from public.listings
        where title = 'Wanted policy test calculator'
      ),
      0,
      'png',
      'Scientific calculator'
    )
  $$,
  'owner can reserve an upload through the quota-enforcing RPC'
);

select is(
  (
    select count(*)::integer
    from public.listing_image_uploads
    where uploader_id = '20000000-0000-0000-0000-000000000001'
  ),
  1,
  'owner can read only the reservation metadata created for them'
);

select throws_ok(
  $$
    insert into public.listings(
      campus_id,
      kind,
      title,
      description,
      category,
      condition,
      price_minor,
      price_unit,
      quantity
    )
    values (
      '10000000-0000-0000-0000-000000000001',
      'sale',
      'Inactive category item',
      'This listing must not use a disabled category.',
      'Inactive category',
      'good',
      50000,
      'item',
      1
    )
  $$,
  '42501',
  null,
  'inactive controlled categories are rejected at the RLS boundary'
);

select throws_ok(
  $$
    update public.listings
    set status = 'active'
    where title = 'Wanted policy test calculator'
  $$,
  '42501',
  null,
  'seller cannot bypass moderation by editing workflow status'
);

select lives_ok(
  $$
    select public.submit_listing(
      (
        select id
        from public.listings
        where title = 'Wanted policy test calculator'
      )
    )
  $$,
  'seller can submit owned draft through RPC'
);

reset role;
set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '20000000-0000-0000-0000-000000000004',
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);
select set_config(
  'request.jwt.claims',
  '{"sub":"20000000-0000-0000-0000-000000000004","role":"authenticated","aal":"aal2"}',
  true
);

select lives_ok(
  $$
    select public.moderate_listing(
      (
        select id
        from public.listings
        where title = 'Wanted policy test calculator'
      ),
      true,
      'policy test approval'
    )
  $$,
  'moderator can approve a pending listing'
);

reset role;
set local role anon;
select set_config('request.jwt.claim.sub', '', true);
select set_config('request.jwt.claim.role', 'anon', true);

select is(
  has_table_privilege('anon', 'public.listings', 'select'),
  false,
  'anonymous users cannot read approved active listings'
);

reset role;
set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '20000000-0000-0000-0000-000000000003',
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);

select throws_ok(
  $$
    insert into public.listings(
      campus_id,
      kind,
      title,
      description,
      category,
      condition,
      price_minor,
      price_unit,
      quantity
    )
    values (
      '10000000-0000-0000-0000-000000000001',
      'sale',
      'Unverified policy test item',
      'This insert must fail because membership is not verified.',
      'Other',
      'good',
      50000,
      'item',
      1
    )
  $$,
  '42501',
  null,
  'unverified user cannot create a listing'
);

reset role;
set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '20000000-0000-0000-0000-000000000002',
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);

select lives_ok(
  $$
    insert into public.conversations(listing_id)
    select id
    from public.listings
    where title = 'Wanted policy test calculator'
  $$,
  'verified buyer can open a contextual conversation'
);

select lives_ok(
  $$
    insert into public.messages(conversation_id, body)
    select id, 'Is this request still open?'
    from public.conversations
    where initiator_id = '20000000-0000-0000-0000-000000000002'
  $$,
  'conversation participant can send a message'
);

select lives_ok(
  $$
    insert into public.offers(
      listing_id,
      kind,
      offered_amount_minor,
      note
    )
    select
      id,
      'fulfill_wanted',
      140000,
      'I can provide this model.'
    from public.listings
    where title = 'Wanted policy test calculator'
  $$,
  'verified responder can offer to fulfill a wanted listing'
);

select is(
  (
    select buyer_id
    from public.offers
    where proposer_id = '20000000-0000-0000-0000-000000000002'
  ),
  '20000000-0000-0000-0000-000000000001'::uuid,
  'wanted-listing owner is normalized as the buyer'
);

select is(
  (
    select seller_id
    from public.offers
    where proposer_id = '20000000-0000-0000-0000-000000000002'
  ),
  '20000000-0000-0000-0000-000000000002'::uuid,
  'wanted-listing responder is normalized as the seller'
);

reset role;
set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '20000000-0000-0000-0000-000000000001',
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);

select throws_ok(
  $$
    select public.respond_to_offer(
      (
        select id
        from public.offers
        where proposer_id = '20000000-0000-0000-0000-000000000002'
      ),
      null
    )
  $$,
  '22023',
  null,
  'nullable decisions cannot accidentally accept offers'
);

select lives_ok(
  $$
    select public.respond_to_offer(
      (
        select id
        from public.offers
        where proposer_id = '20000000-0000-0000-0000-000000000002'
      ),
      true
    )
  $$,
  'wanted-listing recipient can accept a fulfillment offer'
);

select is(
  (
    select customer_id
    from public.bookings
    where offer_id is not null
  ),
  '20000000-0000-0000-0000-000000000001'::uuid,
  'wanted poster becomes the booking customer'
);

select is(
  (
    select provider_id
    from public.bookings
    where offer_id is not null
  ),
  '20000000-0000-0000-0000-000000000002'::uuid,
  'wanted fulfiller becomes the booking provider'
);

reset role;
set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '20000000-0000-0000-0000-000000000002',
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);

select lives_ok(
  $$
    select public.complete_booking(
      (
        select id
        from public.bookings
        where provider_id = '20000000-0000-0000-0000-000000000002'
      )
    )
  $$,
  'provider can complete an accepted wanted fulfillment'
);

reset role;
select is(
  (
    select status::text
    from public.listings
    where title = 'Wanted policy test calculator'
  ),
  'reserved',
  'one party cannot unilaterally complete a marketplace handoff'
);

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '20000000-0000-0000-0000-000000000001',
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);

select lives_ok(
  $$
    select public.complete_booking(
      (
        select id
        from public.bookings
        where customer_id = '20000000-0000-0000-0000-000000000001'
      )
    )
  $$,
  'customer confirmation completes the bilateral handoff'
);

reset role;
select is(
  (
    select status::text
    from public.listings
    where title = 'Wanted policy test calculator'
  ),
  'fulfilled',
  'completing a one-off booking transitions its listing out of reserved'
);

reset role;
set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '20000000-0000-0000-0000-000000000003',
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);

select is(
  (select count(*)::integer from public.conversations),
  0,
  'nonparticipant cannot enumerate conversations'
);

select is(
  (select count(*)::integer from public.messages),
  0,
  'nonparticipant cannot read messages'
);

reset role;
set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '20000000-0000-0000-0000-000000000001',
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);

insert into public.blocks(blocked_id)
values ('20000000-0000-0000-0000-000000000002');

reset role;
set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '20000000-0000-0000-0000-000000000002',
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);

select throws_ok(
  $$
    insert into public.messages(conversation_id, body)
    select id, 'This message must be blocked'
    from public.conversations
    limit 1
  $$,
  '42501',
  null,
  'either participant blocking the other prevents new messages'
);

reset role;

insert into public.campus_email_domains(campus_id, domain)
values (
  '10000000-0000-0000-0000-000000000001',
  'policy.test'
);

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '20000000-0000-0000-0000-000000000003',
  true
);
select set_config('request.jwt.claim.role', 'authenticated', true);

select lives_ok(
  $$ select * from public.claim_campus_from_verified_email() $$,
  'a confirmed exact-domain email can claim its campus'
);

select is(
  (
    select status::text
    from public.campus_memberships
    where user_id = '20000000-0000-0000-0000-000000000003'
      and campus_id = '10000000-0000-0000-0000-000000000001'
  ),
  'verified',
  'email campus detection creates a verified membership'
);

reset role;
set local role anon;

select is(
  has_table_privilege('anon', 'public.listings', 'select'),
  false,
  'anonymous users have no marketplace read grant'
);

select is(
  has_table_privilege('anon', 'public.services', 'select'),
  false,
  'anonymous users have no service read grant'
);

select is(
  has_table_privilege('anon', 'public.profiles', 'select'),
  false,
  'anonymous users have no profile read grant'
);

reset role;

select * from finish();
rollback;
