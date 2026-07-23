begin;

set local client_min_messages = warning;

create or replace function private.touch_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create or replace function private.is_verified_member(
  p_user_id uuid,
  p_campus_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.campus_memberships m
    join public.campuses c on c.id = m.campus_id
    where m.user_id = p_user_id
      and m.campus_id = p_campus_id
      and m.status = 'verified'
      and (m.expires_at is null or m.expires_at > now())
      and c.is_active
  );
$$;

create or replace function private.is_moderator(
  p_user_id uuid,
  p_campus_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from private.moderator_assignments a
    where a.user_id = p_user_id
      and a.campus_id = p_campus_id
      and p_user_id = auth.uid()
      and coalesce(auth.jwt() ->> 'aal', 'aal1') = 'aal2'
  );
$$;

create or replace function private.email_qualifies_for_campus(
  p_user_id uuid,
  p_campus_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    p_user_id = auth.uid()
    and exists (
      select 1
      from auth.users u
      join public.campus_email_domains d
        on d.campus_id = p_campus_id
       and d.is_active
       and d.domain = lower(pg_catalog.split_part(u.email, '@', 2))
      join public.campuses c
        on c.id = d.campus_id
       and c.is_active
      where u.id = p_user_id
        and u.email_confirmed_at is not null
        and u.email is not null
    );
$$;

create or replace function private.is_listing_actionable(p_listing_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.listings l
    join public.campus_categories cc
      on cc.campus_id = l.campus_id
     and cc.name = l.category
     and cc.is_active
     and cc.scope in ('listing', 'both')
    left join public.campus_pickup_zones z
      on z.campus_id = l.campus_id
     and z.label = l.pickup_zone
     and z.is_active
    where l.id = p_listing_id
      and l.status = 'active'
      and l.deleted_at is null
      and (l.expires_at is null or l.expires_at > now())
      and (l.pickup_zone is null or z.label is not null)
      and private.is_verified_member(l.seller_id, l.campus_id)
  );
$$;

create or replace function private.is_service_actionable(p_service_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.services s
    join public.campus_categories cc
      on cc.campus_id = s.campus_id
     and cc.name = s.category
     and cc.is_active
     and cc.scope in ('service', 'both')
    left join public.campus_pickup_zones z
      on z.campus_id = s.campus_id
     and z.label = s.pickup_zone
     and z.is_active
    where s.id = p_service_id
      and s.status = 'active'
      and s.deleted_at is null
      and (s.expires_at is null or s.expires_at > now())
      and (s.pickup_zone is null or z.label is not null)
      and private.is_verified_member(s.provider_id, s.campus_id)
      and exists (
        select 1
        from public.service_availability a
        where a.service_id = s.id
          and a.is_active
      )
  );
$$;

create or replace function private.are_blocked(
  p_first_user_id uuid,
  p_second_user_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.blocks b
    where (b.blocker_id = p_first_user_id and b.blocked_id = p_second_user_id)
       or (b.blocker_id = p_second_user_id and b.blocked_id = p_first_user_id)
  );
$$;

create or replace function private.can_access_conversation(
  p_user_id uuid,
  p_conversation_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.conversations c
    where c.id = p_conversation_id
      and p_user_id in (c.initiator_id, c.recipient_id)
  );
$$;

create or replace function private.is_current_user_verified(p_campus_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select auth.uid() is not null
    and private.is_verified_member(auth.uid(), p_campus_id);
$$;

create or replace function private.is_current_user_blocked_with(p_other_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select auth.uid() is not null
    and p_other_user_id is not null
    and private.are_blocked(auth.uid(), p_other_user_id);
$$;

create or replace function private.can_current_user_access_conversation(
  p_conversation_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select auth.uid() is not null
    and private.can_access_conversation(auth.uid(), p_conversation_id);
$$;

create or replace function private.is_current_user_listing_transaction_participant(
  p_listing_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select auth.uid() is not null
    and exists (
      select 1
      from public.offers o
      where o.listing_id = p_listing_id
        and auth.uid() in (o.proposer_id, o.recipient_id)
        and o.status in ('accepted', 'cancelled', 'completed')
    );
$$;

create or replace function private.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_display_name text;
begin
  v_display_name := left(
    regexp_replace(
      coalesce(nullif(btrim(new.raw_user_meta_data ->> 'display_name'), ''), 'Student'),
      '[[:cntrl:]]',
      '',
      'g'
    ),
    60
  );

  if v_display_name = '' then
    v_display_name := 'Student';
  end if;

  insert into public.profiles(user_id, display_name)
  values (new.id, v_display_name)
  on conflict (user_id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function private.handle_new_auth_user();

create or replace function private.normalize_membership_insert()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception using errcode = '42501', message = 'Authentication required';
  end if;

  new.user_id := v_user_id;
  new.role := 'student';

  if private.email_qualifies_for_campus(v_user_id, new.campus_id) then
    new.status := 'verified';
    new.verified_at := now();
    new.expires_at := now() + interval '1 year';
  else
    new.status := 'pending';
    new.verified_at := null;
    new.expires_at := null;
  end if;

  return new;
end;
$$;

create or replace function private.enforce_membership_quota()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_count integer;
begin
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(new.user_id::text, 19001)
  );

  select count(*) into v_count
  from public.campus_memberships m
  where m.user_id = new.user_id
    and m.status in ('pending', 'verified');

  if v_count >= 3 then
    raise exception using
      errcode = 'P0001',
      message = 'Membership request limit reached';
  end if;

  return new;
end;
$$;

drop trigger if exists "10_normalize_membership_insert" on public.campus_memberships;
create trigger "10_normalize_membership_insert"
before insert on public.campus_memberships
for each row execute function private.normalize_membership_insert();

drop trigger if exists "20_enforce_membership_quota" on public.campus_memberships;
create trigger "20_enforce_membership_quota"
before insert on public.campus_memberships
for each row execute function private.enforce_membership_quota();

create or replace function private.normalize_listing_insert()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_currency_code text;
begin
  if v_user_id is null then
    raise exception using errcode = '42501', message = 'Authentication required';
  end if;

  select c.currency_code into v_currency_code
  from public.campuses c
  where c.id = new.campus_id
    and c.is_active;

  if v_currency_code is null then
    raise exception using errcode = '22023', message = 'Unknown or inactive campus';
  end if;

  new.seller_id := v_user_id;
  new.status := 'draft';
  new.currency_code := v_currency_code;
  new.published_at := null;
  new.expires_at := null;
  new.deleted_at := null;
  return new;
end;
$$;

create or replace function private.enforce_listing_quota()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_recent_count integer;
  v_open_count integer;
begin
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(new.seller_id::text, 19002)
  );

  select count(*) into v_recent_count
  from public.listings l
  where l.seller_id = new.seller_id
    and l.created_at >= now() - interval '24 hours';

  select count(*) into v_open_count
  from public.listings l
  where l.seller_id = new.seller_id
    and l.status in ('draft', 'pending', 'active', 'paused', 'reserved');

  if v_recent_count >= 10 or v_open_count >= 25 then
    raise exception using
      errcode = 'P0001',
      message = 'Listing creation limit reached';
  end if;

  return new;
end;
$$;

drop trigger if exists "10_normalize_listing_insert" on public.listings;
create trigger "10_normalize_listing_insert"
before insert on public.listings
for each row execute function private.normalize_listing_insert();

drop trigger if exists "20_enforce_listing_quota" on public.listings;
create trigger "20_enforce_listing_quota"
before insert on public.listings
for each row execute function private.enforce_listing_quota();

create or replace function private.normalize_service_insert()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_currency_code text;
begin
  if v_user_id is null then
    raise exception using errcode = '42501', message = 'Authentication required';
  end if;

  select c.currency_code into v_currency_code
  from public.campuses c
  where c.id = new.campus_id
    and c.is_active;

  if v_currency_code is null then
    raise exception using errcode = '22023', message = 'Unknown or inactive campus';
  end if;

  new.provider_id := v_user_id;
  new.status := 'draft';
  new.currency_code := v_currency_code;
  new.published_at := null;
  new.expires_at := null;
  new.deleted_at := null;
  return new;
end;
$$;

create or replace function private.enforce_service_quota()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_recent_count integer;
  v_open_count integer;
begin
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(new.provider_id::text, 19003)
  );

  select count(*) into v_recent_count
  from public.services s
  where s.provider_id = new.provider_id
    and s.created_at >= now() - interval '24 hours';

  select count(*) into v_open_count
  from public.services s
  where s.provider_id = new.provider_id
    and s.status in ('draft', 'pending', 'active', 'paused', 'reserved');

  if v_recent_count >= 5 or v_open_count >= 15 then
    raise exception using
      errcode = 'P0001',
      message = 'Service creation limit reached';
  end if;

  return new;
end;
$$;

drop trigger if exists "10_normalize_service_insert" on public.services;
create trigger "10_normalize_service_insert"
before insert on public.services
for each row execute function private.normalize_service_insert();

drop trigger if exists "20_enforce_service_quota" on public.services;
create trigger "20_enforce_service_quota"
before insert on public.services
for each row execute function private.enforce_service_quota();

create or replace function private.normalize_service_availability_write()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_timezone text;
begin
  select c.timezone into v_timezone
  from public.services s
  join public.campuses c on c.id = s.campus_id
  where s.id = new.service_id;

  if v_timezone is null then
    raise exception using errcode = '22023', message = 'Unknown service campus';
  end if;

  new.timezone := v_timezone;
  return new;
end;
$$;

drop trigger if exists "10_normalize_service_availability_write"
on public.service_availability;
create trigger "10_normalize_service_availability_write"
before insert or update on public.service_availability
for each row execute function private.normalize_service_availability_write();

create or replace function private.normalize_favorite_insert()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception using errcode = '42501', message = 'Authentication required';
  end if;
  new.user_id := auth.uid();
  return new;
end;
$$;

drop trigger if exists "10_normalize_favorite_insert" on public.favorites;
create trigger "10_normalize_favorite_insert"
before insert on public.favorites
for each row execute function private.normalize_favorite_insert();

create or replace function private.normalize_conversation_insert()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_recipient_id uuid;
begin
  if v_user_id is null then
    raise exception using errcode = '42501', message = 'Authentication required';
  end if;

  if num_nonnulls(new.listing_id, new.service_id) <> 1 then
    raise exception using errcode = '22023', message = 'A conversation requires one target';
  end if;

  if new.listing_id is not null then
    select l.seller_id into v_recipient_id
    from public.listings l
    where l.id = new.listing_id
      and private.is_listing_actionable(l.id);
  else
    select s.provider_id into v_recipient_id
    from public.services s
    where s.id = new.service_id
      and private.is_service_actionable(s.id);
  end if;

  if v_recipient_id is null or v_recipient_id = v_user_id then
    raise exception using errcode = '22023', message = 'Conversation target is unavailable';
  end if;

  if private.are_blocked(v_user_id, v_recipient_id) then
    raise exception using errcode = '42501', message = 'Conversation is not permitted';
  end if;

  new.initiator_id := v_user_id;
  new.recipient_id := v_recipient_id;
  new.status := 'open';
  return new;
end;
$$;

create or replace function private.enforce_conversation_quota()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_count integer;
begin
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(new.initiator_id::text, 19004)
  );

  select count(*) into v_count
  from public.conversations c
  where c.initiator_id = new.initiator_id
    and c.created_at >= now() - interval '24 hours';

  if v_count >= 30 then
    raise exception using errcode = 'P0001', message = 'Conversation limit reached';
  end if;

  return new;
end;
$$;

drop trigger if exists "10_normalize_conversation_insert" on public.conversations;
create trigger "10_normalize_conversation_insert"
before insert on public.conversations
for each row execute function private.normalize_conversation_insert();

drop trigger if exists "20_enforce_conversation_quota" on public.conversations;
create trigger "20_enforce_conversation_quota"
before insert on public.conversations
for each row execute function private.enforce_conversation_quota();

create or replace function private.normalize_message_insert()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_other_user_id uuid;
  v_conversation_status public.conversation_status;
  v_campus_id uuid;
begin
  if v_user_id is null then
    raise exception using errcode = '42501', message = 'Authentication required';
  end if;

  select
    case
      when c.initiator_id = v_user_id then c.recipient_id
      when c.recipient_id = v_user_id then c.initiator_id
    end,
    c.status,
    coalesce(l.campus_id, s.campus_id)
  into v_other_user_id, v_conversation_status, v_campus_id
  from public.conversations c
  left join public.listings l on l.id = c.listing_id
  left join public.services s on s.id = c.service_id
  where c.id = new.conversation_id;

  if v_other_user_id is null
     or v_conversation_status <> 'open'
     or v_campus_id is null
     or not private.is_verified_member(v_user_id, v_campus_id) then
    raise exception using errcode = '42501', message = 'Conversation is unavailable';
  end if;

  if private.are_blocked(v_user_id, v_other_user_id) then
    raise exception using errcode = '42501', message = 'Message is not permitted';
  end if;

  new.sender_id := v_user_id;
  new.kind := 'text';
  return new;
end;
$$;

create or replace function private.enforce_message_quota()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_minute_count integer;
  v_day_count integer;
begin
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(new.sender_id::text, 19005)
  );

  select
    count(*) filter (where m.created_at >= now() - interval '1 minute'),
    count(*)
  into v_minute_count, v_day_count
  from public.messages m
  where m.sender_id = new.sender_id
    and m.created_at >= now() - interval '24 hours';

  if v_minute_count >= 20 or v_day_count >= 300 then
    raise exception using errcode = 'P0001', message = 'Message rate limit reached';
  end if;

  return new;
end;
$$;

drop trigger if exists "10_normalize_message_insert" on public.messages;
create trigger "10_normalize_message_insert"
before insert on public.messages
for each row execute function private.normalize_message_insert();

drop trigger if exists "20_enforce_message_quota" on public.messages;
create trigger "20_enforce_message_quota"
before insert on public.messages
for each row execute function private.enforce_message_quota();

create or replace function private.normalize_offer_insert()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_listing_owner_id uuid;
  v_listing_kind public.listing_kind;
  v_listing_campus_id uuid;
begin
  if v_user_id is null then
    raise exception using errcode = '42501', message = 'Authentication required';
  end if;

  select l.seller_id, l.kind, l.campus_id
  into v_listing_owner_id, v_listing_kind, v_listing_campus_id
  from public.listings l
  where l.id = new.listing_id
    and private.is_listing_actionable(l.id);

  if v_listing_owner_id is null or v_listing_owner_id = v_user_id then
    raise exception using errcode = '22023', message = 'Listing is unavailable';
  end if;

  if not private.is_verified_member(v_user_id, v_listing_campus_id) then
    raise exception using errcode = '42501', message = 'Verified campus membership required';
  end if;

  if private.are_blocked(v_user_id, v_listing_owner_id) then
    raise exception using errcode = '42501', message = 'Offer is not permitted';
  end if;

  if (v_listing_kind = 'sale' and new.kind <> 'purchase')
     or (v_listing_kind = 'rent' and new.kind <> 'rental')
     or (v_listing_kind = 'free' and new.kind <> 'claim_free')
     or (v_listing_kind = 'wanted' and new.kind <> 'fulfill_wanted') then
    raise exception using errcode = '22023', message = 'Offer type does not match listing type';
  end if;

  new.proposer_id := v_user_id;
  new.recipient_id := v_listing_owner_id;

  if v_listing_kind = 'wanted' then
    new.buyer_id := v_listing_owner_id;
    new.seller_id := v_user_id;
  else
    new.buyer_id := v_user_id;
    new.seller_id := v_listing_owner_id;
  end if;

  if v_listing_kind = 'free' then
    new.offered_amount_minor := 0;
  end if;

  new.status := 'pending';
  return new;
end;
$$;

create or replace function private.enforce_offer_quota()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_count integer;
begin
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(new.proposer_id::text, 19006)
  );

  select count(*) into v_count
  from public.offers o
  where o.proposer_id = new.proposer_id
    and o.created_at >= now() - interval '24 hours';

  if v_count >= 50 then
    raise exception using errcode = 'P0001', message = 'Offer limit reached';
  end if;

  return new;
end;
$$;

drop trigger if exists "10_normalize_offer_insert" on public.offers;
create trigger "10_normalize_offer_insert"
before insert on public.offers
for each row execute function private.normalize_offer_insert();

drop trigger if exists "20_enforce_offer_quota" on public.offers;
create trigger "20_enforce_offer_quota"
before insert on public.offers
for each row execute function private.enforce_offer_quota();

create or replace function private.normalize_service_request_insert()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_provider_id uuid;
  v_campus_id uuid;
begin
  if v_user_id is null then
    raise exception using errcode = '42501', message = 'Authentication required';
  end if;

  select s.provider_id, s.campus_id
  into v_provider_id, v_campus_id
  from public.services s
  where s.id = new.service_id
    and private.is_service_actionable(s.id);

  if v_provider_id is null or v_provider_id = v_user_id then
    raise exception using errcode = '22023', message = 'Service is unavailable';
  end if;

  if not private.is_verified_member(v_user_id, v_campus_id) then
    raise exception using errcode = '42501', message = 'Verified campus membership required';
  end if;

  if private.are_blocked(v_user_id, v_provider_id) then
    raise exception using errcode = '42501', message = 'Request is not permitted';
  end if;

  new.requester_id := v_user_id;
  new.provider_id := v_provider_id;
  new.status := 'pending';
  return new;
end;
$$;

create or replace function private.enforce_service_request_quota()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_count integer;
begin
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(new.requester_id::text, 19007)
  );

  select count(*) into v_count
  from public.service_requests r
  where r.requester_id = new.requester_id
    and r.created_at >= now() - interval '24 hours';

  if v_count >= 30 then
    raise exception using errcode = 'P0001', message = 'Service request limit reached';
  end if;

  return new;
end;
$$;

drop trigger if exists "10_normalize_service_request_insert" on public.service_requests;
create trigger "10_normalize_service_request_insert"
before insert on public.service_requests
for each row execute function private.normalize_service_request_insert();

drop trigger if exists "20_enforce_service_request_quota" on public.service_requests;
create trigger "20_enforce_service_request_quota"
before insert on public.service_requests
for each row execute function private.enforce_service_request_quota();

create or replace function private.normalize_review_insert()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_reviewee_id uuid;
begin
  if v_user_id is null then
    raise exception using errcode = '42501', message = 'Authentication required';
  end if;

  select case
    when b.customer_id = v_user_id then b.provider_id
    when b.provider_id = v_user_id then b.customer_id
  end
  into v_reviewee_id
  from public.bookings b
  where b.id = new.booking_id
    and b.status = 'completed';

  if v_reviewee_id is null then
    raise exception using errcode = '42501', message = 'Completed participant booking required';
  end if;

  new.reviewer_id := v_user_id;
  new.reviewee_id := v_reviewee_id;
  new.status := 'published';
  return new;
end;
$$;

drop trigger if exists "10_normalize_review_insert" on public.reviews;
create trigger "10_normalize_review_insert"
before insert on public.reviews
for each row execute function private.normalize_review_insert();

create or replace function private.normalize_block_insert()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception using errcode = '42501', message = 'Authentication required';
  end if;
  new.blocker_id := auth.uid();
  return new;
end;
$$;

drop trigger if exists "10_normalize_block_insert" on public.blocks;
create trigger "10_normalize_block_insert"
before insert on public.blocks
for each row execute function private.normalize_block_insert();

create or replace function private.apply_block_effects()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.conversations
  set status = 'closed'
  where status = 'open'
    and (
      (initiator_id = new.blocker_id and recipient_id = new.blocked_id)
      or (initiator_id = new.blocked_id and recipient_id = new.blocker_id)
    );

  update public.offers
  set status = 'cancelled'
  where status = 'pending'
    and (
      (proposer_id = new.blocker_id and recipient_id = new.blocked_id)
      or (proposer_id = new.blocked_id and recipient_id = new.blocker_id)
    );

  update public.service_requests
  set status = 'cancelled'
  where status = 'pending'
    and (
      (requester_id = new.blocker_id and provider_id = new.blocked_id)
      or (requester_id = new.blocked_id and provider_id = new.blocker_id)
    );

  insert into private.audit_events(
    actor_id,
    event_type,
    entity_type,
    metadata
  )
  values (
    new.blocker_id,
    'user.blocked',
    'profile',
    jsonb_build_object('blocked_user_id', new.blocked_id)
  );

  return new;
end;
$$;

drop trigger if exists "20_apply_block_effects" on public.blocks;
create trigger "20_apply_block_effects"
after insert on public.blocks
for each row execute function private.apply_block_effects();

create or replace function private.normalize_report_insert()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_campus_id uuid;
begin
  if v_user_id is null then
    raise exception using errcode = '42501', message = 'Authentication required';
  end if;

  if new.listing_id is not null then
    select l.campus_id into v_campus_id
    from public.listings l
    where l.id = new.listing_id;
  elsif new.service_id is not null then
    select s.campus_id into v_campus_id
    from public.services s
    where s.id = new.service_id;
  elsif new.message_id is not null then
    select coalesce(l.campus_id, s.campus_id) into v_campus_id
    from public.messages m
    join public.conversations c on c.id = m.conversation_id
    left join public.listings l on l.id = c.listing_id
    left join public.services s on s.id = c.service_id
    where m.id = new.message_id
      and v_user_id in (c.initiator_id, c.recipient_id);
  elsif new.review_id is not null then
    select coalesce(l.campus_id, s.campus_id) into v_campus_id
    from public.reviews rv
    join public.bookings b on b.id = rv.booking_id
    left join public.offers o on o.id = b.offer_id
    left join public.listings l on l.id = o.listing_id
    left join public.service_requests sr on sr.id = b.service_request_id
    left join public.services s on s.id = sr.service_id
    where rv.id = new.review_id;
  elsif new.booking_id is not null then
    select coalesce(l.campus_id, s.campus_id) into v_campus_id
    from public.bookings b
    left join public.offers o on o.id = b.offer_id
    left join public.listings l on l.id = o.listing_id
    left join public.service_requests sr on sr.id = b.service_request_id
    left join public.services s on s.id = sr.service_id
    where b.id = new.booking_id
      and v_user_id in (b.customer_id, b.provider_id);
  elsif new.profile_id is not null then
    select mine.campus_id into v_campus_id
    from public.campus_memberships mine
    join public.campus_memberships theirs
      on theirs.campus_id = mine.campus_id
    where mine.user_id = v_user_id
      and theirs.user_id = new.profile_id
      and mine.status = 'verified'
      and theirs.status = 'verified'
      and (mine.expires_at is null or mine.expires_at > now())
      and (theirs.expires_at is null or theirs.expires_at > now())
    order by mine.verified_at desc nulls last
    limit 1;
  end if;

  if v_campus_id is null then
    raise exception using errcode = '22023', message = 'Report target is unavailable';
  end if;

  new.reporter_id := v_user_id;
  new.campus_id := v_campus_id;
  new.status := 'open';
  new.resolution_note := null;
  new.resolved_by := null;
  new.resolved_at := null;
  return new;
end;
$$;

create or replace function private.enforce_report_quota()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_count integer;
begin
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(new.reporter_id::text, 19008)
  );

  select count(*) into v_count
  from public.reports r
  where r.reporter_id = new.reporter_id
    and r.created_at >= now() - interval '24 hours';

  if v_count >= 10 then
    raise exception using errcode = 'P0001', message = 'Report limit reached';
  end if;

  return new;
end;
$$;

drop trigger if exists "10_normalize_report_insert" on public.reports;
create trigger "10_normalize_report_insert"
before insert on public.reports
for each row execute function private.normalize_report_insert();

drop trigger if exists "20_enforce_report_quota" on public.reports;
create trigger "20_enforce_report_quota"
before insert on public.reports
for each row execute function private.enforce_report_quota();

drop trigger if exists campuses_touch_updated_at on public.campuses;
create trigger campuses_touch_updated_at
before update on public.campuses
for each row execute function private.touch_updated_at();

drop trigger if exists profiles_touch_updated_at on public.profiles;
create trigger profiles_touch_updated_at
before update on public.profiles
for each row execute function private.touch_updated_at();

drop trigger if exists campus_memberships_touch_updated_at on public.campus_memberships;
create trigger campus_memberships_touch_updated_at
before update on public.campus_memberships
for each row execute function private.touch_updated_at();

drop trigger if exists listings_touch_updated_at on public.listings;
create trigger listings_touch_updated_at
before update on public.listings
for each row execute function private.touch_updated_at();

drop trigger if exists listing_images_touch_updated_at on public.listing_images;
create trigger listing_images_touch_updated_at
before update on public.listing_images
for each row execute function private.touch_updated_at();

drop trigger if exists services_touch_updated_at on public.services;
create trigger services_touch_updated_at
before update on public.services
for each row execute function private.touch_updated_at();

drop trigger if exists service_availability_touch_updated_at on public.service_availability;
create trigger service_availability_touch_updated_at
before update on public.service_availability
for each row execute function private.touch_updated_at();

drop trigger if exists conversations_touch_updated_at on public.conversations;
create trigger conversations_touch_updated_at
before update on public.conversations
for each row execute function private.touch_updated_at();

drop trigger if exists offers_touch_updated_at on public.offers;
create trigger offers_touch_updated_at
before update on public.offers
for each row execute function private.touch_updated_at();

drop trigger if exists service_requests_touch_updated_at on public.service_requests;
create trigger service_requests_touch_updated_at
before update on public.service_requests
for each row execute function private.touch_updated_at();

drop trigger if exists bookings_touch_updated_at on public.bookings;
create trigger bookings_touch_updated_at
before update on public.bookings
for each row execute function private.touch_updated_at();

drop trigger if exists reviews_touch_updated_at on public.reviews;
create trigger reviews_touch_updated_at
before update on public.reviews
for each row execute function private.touch_updated_at();

drop trigger if exists reports_touch_updated_at on public.reports;
create trigger reports_touch_updated_at
before update on public.reports
for each row execute function private.touch_updated_at();

revoke all on all functions in schema private from public, anon, authenticated;
grant usage on schema private to authenticated;
grant execute on function private.is_moderator(uuid, uuid) to authenticated;
grant execute on function private.email_qualifies_for_campus(uuid, uuid) to authenticated;
grant execute on function private.is_listing_actionable(uuid) to anon, authenticated;
grant execute on function private.is_service_actionable(uuid) to anon, authenticated;
grant execute on function private.is_current_user_verified(uuid) to authenticated;
grant execute on function private.is_current_user_blocked_with(uuid) to authenticated;
grant execute on function private.can_current_user_access_conversation(uuid) to authenticated;
grant execute on function private.is_current_user_listing_transaction_participant(uuid)
to authenticated;

commit;
