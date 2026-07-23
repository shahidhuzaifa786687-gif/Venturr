begin;

set local client_min_messages = warning;

create or replace function public.reserve_listing_image(
  p_listing_id uuid,
  p_position integer,
  p_extension text,
  p_alt_text text default null
)
returns table(image_id uuid, source_path text)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_listing public.listings%rowtype;
  v_existing_image public.listing_images%rowtype;
  v_image_id uuid;
  v_source_path text;
  v_extension text := lower(btrim(p_extension));
  v_recent_count integer;
begin
  if v_user_id is null then
    raise exception using errcode = '42501', message = 'Authentication required';
  end if;

  if p_position is null
     or p_position not between 0 and 3
     or p_extension is null
     or v_extension not in ('jpg', 'jpeg', 'png', 'webp') then
    raise exception using errcode = '22023', message = 'Invalid image reservation';
  end if;

  select * into v_listing
  from public.listings l
  where l.id = p_listing_id
  for update;

  if v_listing.id is null
     or v_listing.seller_id <> v_user_id
     or v_listing.status <> 'draft'
     or not private.is_verified_member(v_user_id, v_listing.campus_id) then
    raise exception using errcode = '42501', message = 'Eligible draft listing required';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(v_user_id::text, 19009)
  );

  select count(*) into v_recent_count
  from public.listing_image_uploads u
  where u.uploader_id = v_user_id
    and u.created_at >= now() - interval '24 hours';

  if v_recent_count >= 20 then
    raise exception using
      errcode = 'P0001',
      message = 'Image reservation limit reached';
  end if;

  select * into v_existing_image
  from public.listing_images i
  where i.listing_id = v_listing.id
    and i.position = p_position
  for update;

  if v_existing_image.id is not null then
    if v_existing_image.processing_status <> 'rejected' then
      raise exception using errcode = '23505', message = 'Image position is already reserved';
    end if;

    -- The upload reservation survives via ON DELETE SET NULL and continues to
    -- count against the immutable daily quota.
    delete from public.listing_images
    where id = v_existing_image.id;
  end if;

  v_image_id := extensions.gen_random_uuid();
  v_source_path :=
    v_user_id::text || '/' ||
    v_listing.id::text || '/' ||
    extensions.gen_random_uuid()::text || '.' ||
    v_extension;

  insert into public.listing_images(
    id,
    listing_id,
    position,
    processing_status,
    alt_text
  )
  values (
    v_image_id,
    v_listing.id,
    p_position,
    'pending',
    nullif(btrim(p_alt_text), '')
  );

  insert into public.listing_image_uploads(
    image_id,
    listing_id,
    uploader_id,
    source_path
  )
  values (
    v_image_id,
    v_listing.id,
    v_user_id,
    v_source_path
  );

  insert into private.audit_events(
    actor_id,
    event_type,
    entity_type,
    entity_id,
    metadata
  )
  values (
    v_user_id,
    'listing_image.reserved',
    'listing_image',
    v_image_id,
    jsonb_build_object('listing_id', v_listing.id, 'position', p_position)
  );

  return query
  select v_image_id, v_source_path;
end;
$$;

create or replace function public.submit_listing(p_listing_id uuid)
returns public.listings
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_listing public.listings%rowtype;
begin
  if v_user_id is null then
    raise exception using errcode = '42501', message = 'Authentication required';
  end if;

  select * into v_listing
  from public.listings l
  where l.id = p_listing_id
  for update;

  if v_listing.id is null
     or v_listing.seller_id <> v_user_id
     or v_listing.status <> 'draft' then
    raise exception using errcode = '42501', message = 'Draft listing not found';
  end if;

  if not private.is_verified_member(v_user_id, v_listing.campus_id) then
    raise exception using errcode = '42501', message = 'Verified campus membership required';
  end if;

  if not exists (
       select 1
       from public.campus_categories cc
       where cc.campus_id = v_listing.campus_id
         and cc.name = v_listing.category
         and cc.is_active
         and cc.scope in ('listing', 'both')
     )
     or (
       v_listing.pickup_zone is not null
       and not exists (
         select 1
         from public.campus_pickup_zones z
         where z.campus_id = v_listing.campus_id
           and z.label = v_listing.pickup_zone
           and z.is_active
       )
     ) then
    raise exception using errcode = '22023', message = 'Listing category or pickup zone is inactive';
  end if;

  if v_listing.kind <> 'wanted'
     and not exists (
       select 1
       from public.listing_images i
       join public.listing_image_uploads u
         on u.image_id = i.id
        and u.listing_id = i.listing_id
       where i.listing_id = v_listing.id
         and i.processing_status = 'ready'
         and u.object_path is not null
         and u.processed_at is not null
     ) then
    raise exception using errcode = '22023', message = 'A processed listing image is required';
  end if;

  update public.listings
  set status = 'pending',
      published_at = null,
      expires_at = null
  where id = v_listing.id
  returning * into v_listing;

  insert into private.audit_events(actor_id, event_type, entity_type, entity_id)
  values (v_user_id, 'listing.submitted', 'listing', v_listing.id);

  return v_listing;
end;
$$;

create or replace function public.withdraw_listing(p_listing_id uuid)
returns public.listings
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_listing public.listings%rowtype;
begin
  if v_user_id is null then
    raise exception using errcode = '42501', message = 'Authentication required';
  end if;

  update public.listings
  set status = 'removed',
      deleted_at = now()
  where id = p_listing_id
    and seller_id = v_user_id
    and status in ('draft', 'pending', 'active', 'paused', 'reserved', 'rejected')
  returning * into v_listing;

  if v_listing.id is null then
    raise exception using errcode = '42501', message = 'Listing cannot be withdrawn';
  end if;

  update public.offers
  set status = 'cancelled'
  where listing_id = v_listing.id
    and status = 'pending';

  insert into private.audit_events(actor_id, event_type, entity_type, entity_id)
  values (v_user_id, 'listing.withdrawn', 'listing', v_listing.id);

  return v_listing;
end;
$$;

create or replace function public.mark_listing_fulfilled(p_listing_id uuid)
returns public.listings
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_listing public.listings%rowtype;
begin
  if v_user_id is null then
    raise exception using errcode = '42501', message = 'Authentication required';
  end if;

  update public.listings
  set status = 'fulfilled'
  where id = p_listing_id
    and seller_id = v_user_id
    and status = 'active'
  returning * into v_listing;

  if v_listing.id is null then
    raise exception using errcode = '42501', message = 'Listing cannot be completed';
  end if;

  update public.offers
  set status = 'declined'
  where listing_id = v_listing.id
    and status = 'pending';

  insert into private.audit_events(actor_id, event_type, entity_type, entity_id)
  values (v_user_id, 'listing.fulfilled_offline', 'listing', v_listing.id);

  return v_listing;
end;
$$;

create or replace function public.submit_service(p_service_id uuid)
returns public.services
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_service public.services%rowtype;
begin
  if v_user_id is null then
    raise exception using errcode = '42501', message = 'Authentication required';
  end if;

  select * into v_service
  from public.services s
  where s.id = p_service_id
  for update;

  if v_service.id is null
     or v_service.provider_id <> v_user_id
     or v_service.status <> 'draft' then
    raise exception using errcode = '42501', message = 'Draft service not found';
  end if;

  if not private.is_verified_member(v_user_id, v_service.campus_id) then
    raise exception using errcode = '42501', message = 'Verified campus membership required';
  end if;

  if not exists (
       select 1
       from public.campus_categories cc
       where cc.campus_id = v_service.campus_id
         and cc.name = v_service.category
         and cc.is_active
         and cc.scope in ('service', 'both')
     )
     or (
       v_service.pickup_zone is not null
       and not exists (
         select 1
         from public.campus_pickup_zones z
         where z.campus_id = v_service.campus_id
           and z.label = v_service.pickup_zone
           and z.is_active
       )
     ) then
    raise exception using errcode = '22023', message = 'Service category or pickup zone is inactive';
  end if;

  if not exists (
    select 1
    from public.service_availability a
    where a.service_id = v_service.id
      and a.is_active
  ) then
    raise exception using errcode = '22023', message = 'At least one availability window is required';
  end if;

  update public.services
  set status = 'pending',
      published_at = null,
      expires_at = null
  where id = v_service.id
  returning * into v_service;

  insert into private.audit_events(actor_id, event_type, entity_type, entity_id)
  values (v_user_id, 'service.submitted', 'service', v_service.id);

  return v_service;
end;
$$;

create or replace function public.withdraw_service(p_service_id uuid)
returns public.services
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_service public.services%rowtype;
begin
  if v_user_id is null then
    raise exception using errcode = '42501', message = 'Authentication required';
  end if;

  update public.services
  set status = 'removed',
      deleted_at = now()
  where id = p_service_id
    and provider_id = v_user_id
    and status in ('draft', 'pending', 'active', 'paused', 'reserved', 'rejected')
  returning * into v_service;

  if v_service.id is null then
    raise exception using errcode = '42501', message = 'Service cannot be withdrawn';
  end if;

  update public.service_requests
  set status = 'cancelled'
  where service_id = v_service.id
    and status = 'pending';

  insert into private.audit_events(actor_id, event_type, entity_type, entity_id)
  values (v_user_id, 'service.withdrawn', 'service', v_service.id);

  return v_service;
end;
$$;

create or replace function public.respond_to_offer(
  p_offer_id uuid,
  p_accept boolean
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_offer public.offers%rowtype;
  v_listing public.listings%rowtype;
  v_booking_id uuid;
begin
  if v_user_id is null then
    raise exception using errcode = '42501', message = 'Authentication required';
  end if;

  if p_accept is null then
    raise exception using errcode = '22023', message = 'Offer decision is required';
  end if;

  select * into v_offer
  from public.offers o
  where o.id = p_offer_id
  for update;

  if v_offer.id is null
     or v_offer.recipient_id <> v_user_id
     or v_offer.status <> 'pending'
     or v_offer.expires_at <= now() then
    raise exception using errcode = '42501', message = 'Offer is unavailable';
  end if;

  if not p_accept then
    update public.offers
    set status = 'declined'
    where id = v_offer.id;

    insert into private.audit_events(actor_id, event_type, entity_type, entity_id)
    values (v_user_id, 'offer.declined', 'offer', v_offer.id);

    return null;
  end if;

  select * into v_listing
  from public.listings l
  where l.id = v_offer.listing_id
  for update;

  if v_listing.id is null
     or v_offer.recipient_id <> v_user_id
     or not private.is_listing_actionable(v_listing.id) then
    raise exception using errcode = '40001', message = 'Listing is no longer available';
  end if;

  if not private.is_verified_member(v_offer.buyer_id, v_listing.campus_id)
     or not private.is_verified_member(v_offer.seller_id, v_listing.campus_id)
     or private.are_blocked(v_offer.buyer_id, v_offer.seller_id) then
    raise exception using errcode = '42501', message = 'Offer participants are no longer eligible';
  end if;

  update public.offers
  set status = 'accepted'
  where id = v_offer.id;

  update public.offers
  set status = 'declined'
  where listing_id = v_offer.listing_id
    and id <> v_offer.id
    and status = 'pending';

  update public.listings
  set status = 'reserved'
  where id = v_listing.id;

  insert into public.bookings(
    offer_id,
    customer_id,
    provider_id,
    starts_at,
    ends_at,
    amount_minor,
    currency_code,
    status
  )
  values (
    v_offer.id,
    v_offer.buyer_id,
    v_offer.seller_id,
    v_offer.rental_starts_at,
    v_offer.rental_ends_at,
    v_offer.offered_amount_minor,
    v_listing.currency_code,
    'confirmed'
  )
  returning id into v_booking_id;

  insert into private.audit_events(
    actor_id,
    event_type,
    entity_type,
    entity_id,
    metadata
  )
  values (
    v_user_id,
    'offer.accepted',
    'offer',
    v_offer.id,
    jsonb_build_object('booking_id', v_booking_id)
  );

  return v_booking_id;
end;
$$;

create or replace function public.cancel_offer(p_offer_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_updated_id uuid;
begin
  if v_user_id is null then
    raise exception using errcode = '42501', message = 'Authentication required';
  end if;

  update public.offers
  set status = 'cancelled'
  where id = p_offer_id
    and proposer_id = v_user_id
    and status = 'pending'
  returning id into v_updated_id;

  if v_updated_id is null then
    raise exception using errcode = '42501', message = 'Offer cannot be cancelled';
  end if;

  insert into private.audit_events(actor_id, event_type, entity_type, entity_id)
  values (v_user_id, 'offer.cancelled', 'offer', v_updated_id);
end;
$$;

create or replace function public.respond_to_service_request(
  p_request_id uuid,
  p_accept boolean
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_request public.service_requests%rowtype;
  v_service public.services%rowtype;
  v_booking_id uuid;
  v_amount bigint;
begin
  if v_user_id is null then
    raise exception using errcode = '42501', message = 'Authentication required';
  end if;

  if p_accept is null then
    raise exception using errcode = '22023', message = 'Service request decision is required';
  end if;

  select * into v_request
  from public.service_requests r
  where r.id = p_request_id
  for update;

  if v_request.id is null
     or v_request.provider_id <> v_user_id
     or v_request.status <> 'pending'
     or v_request.expires_at <= now() then
    raise exception using errcode = '42501', message = 'Service request is unavailable';
  end if;

  if not p_accept then
    update public.service_requests
    set status = 'declined'
    where id = v_request.id;

    insert into private.audit_events(actor_id, event_type, entity_type, entity_id)
    values (v_user_id, 'service_request.declined', 'service_request', v_request.id);

    return null;
  end if;

  select * into v_service
  from public.services s
  where s.id = v_request.service_id
  for update;

  if v_service.id is null
     or v_service.provider_id <> v_user_id
     or not private.is_service_actionable(v_service.id) then
    raise exception using errcode = '40001', message = 'Service is no longer available';
  end if;

  if not private.is_verified_member(v_request.requester_id, v_service.campus_id)
     or not private.is_verified_member(v_request.provider_id, v_service.campus_id)
     or private.are_blocked(v_request.requester_id, v_request.provider_id) then
    raise exception using errcode = '42501', message = 'Request participants are no longer eligible';
  end if;

  v_amount := coalesce(v_request.proposed_amount_minor, v_service.base_rate_minor);

  update public.service_requests
  set status = 'accepted'
  where id = v_request.id;

  insert into public.bookings(
    service_request_id,
    customer_id,
    provider_id,
    starts_at,
    ends_at,
    amount_minor,
    currency_code,
    status
  )
  values (
    v_request.id,
    v_request.requester_id,
    v_request.provider_id,
    v_request.proposed_starts_at,
    v_request.proposed_ends_at,
    v_amount,
    v_service.currency_code,
    'confirmed'
  )
  returning id into v_booking_id;

  insert into private.audit_events(
    actor_id,
    event_type,
    entity_type,
    entity_id,
    metadata
  )
  values (
    v_user_id,
    'service_request.accepted',
    'service_request',
    v_request.id,
    jsonb_build_object('booking_id', v_booking_id)
  );

  return v_booking_id;
end;
$$;

create or replace function public.cancel_service_request(p_request_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_updated_id uuid;
begin
  if v_user_id is null then
    raise exception using errcode = '42501', message = 'Authentication required';
  end if;

  update public.service_requests
  set status = 'cancelled'
  where id = p_request_id
    and requester_id = v_user_id
    and status = 'pending'
  returning id into v_updated_id;

  if v_updated_id is null then
    raise exception using errcode = '42501', message = 'Request cannot be cancelled';
  end if;

  insert into private.audit_events(actor_id, event_type, entity_type, entity_id)
  values (v_user_id, 'service_request.cancelled', 'service_request', v_updated_id);
end;
$$;

create or replace function public.cancel_booking(p_booking_id uuid)
returns public.bookings
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_booking public.bookings%rowtype;
  v_listing_id uuid;
begin
  if v_user_id is null then
    raise exception using errcode = '42501', message = 'Authentication required';
  end if;

  update public.bookings
  set status = 'cancelled',
      cancelled_at = now()
  where id = p_booking_id
    and v_user_id in (customer_id, provider_id)
    and status = 'confirmed'
  returning * into v_booking;

  if v_booking.id is null then
    raise exception using errcode = '42501', message = 'Booking cannot be cancelled';
  end if;

  if v_booking.offer_id is not null then
    update public.offers
    set status = 'cancelled'
    where id = v_booking.offer_id
    returning listing_id into v_listing_id;

    update public.listings
    set status = 'active'
    where id = v_listing_id
      and status = 'reserved';
  else
    update public.service_requests
    set status = 'cancelled'
    where id = v_booking.service_request_id;
  end if;

  insert into private.audit_events(actor_id, event_type, entity_type, entity_id)
  values (v_user_id, 'booking.cancelled', 'booking', v_booking.id);

  return v_booking;
end;
$$;

create or replace function public.complete_booking(p_booking_id uuid)
returns public.bookings
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_booking public.bookings%rowtype;
  v_listing public.listings%rowtype;
  v_listing_id uuid;
begin
  if v_user_id is null then
    raise exception using errcode = '42501', message = 'Authentication required';
  end if;

  select * into v_booking
  from public.bookings b
  where b.id = p_booking_id
  for update;

  if v_booking.id is null
     or v_user_id not in (v_booking.customer_id, v_booking.provider_id)
     or v_booking.status <> 'confirmed'
     or (v_booking.ends_at is not null and v_booking.ends_at > now()) then
    raise exception using errcode = '42501', message = 'Booking cannot be confirmed complete';
  end if;

  update public.bookings
  set customer_confirmed_at = case
        when customer_id = v_user_id then coalesce(customer_confirmed_at, now())
        else customer_confirmed_at
      end,
      provider_confirmed_at = case
        when provider_id = v_user_id then coalesce(provider_confirmed_at, now())
        else provider_confirmed_at
      end
  where id = v_booking.id
  returning * into v_booking;

  insert into private.audit_events(
    actor_id,
    event_type,
    entity_type,
    entity_id,
    metadata
  )
  values (
    v_user_id,
    'booking.completion_confirmed',
    'booking',
    v_booking.id,
    jsonb_build_object(
      'customer_confirmed', v_booking.customer_confirmed_at is not null,
      'provider_confirmed', v_booking.provider_confirmed_at is not null
    )
  );

  if v_booking.customer_confirmed_at is null
     or v_booking.provider_confirmed_at is null then
    return v_booking;
  end if;

  update public.bookings
  set status = 'completed',
      completed_at = now()
  where id = v_booking.id
  returning * into v_booking;

  if v_booking.offer_id is not null then
    update public.offers
    set status = 'completed'
    where id = v_booking.offer_id
    returning listing_id into v_listing_id;

    select * into v_listing
    from public.listings l
    where l.id = v_listing_id
    for update;

    update public.listings
    set status = case
          when v_listing.kind = 'rent'
               and (v_listing.expires_at is null or v_listing.expires_at > now())
            then 'active'::public.content_status
          when v_listing.kind = 'rent'
            then 'expired'::public.content_status
          else 'fulfilled'::public.content_status
        end
    where id = v_listing.id
      and status = 'reserved';
  else
    update public.service_requests
    set status = 'completed'
    where id = v_booking.service_request_id;
  end if;

  insert into private.audit_events(actor_id, event_type, entity_type, entity_id)
  values (v_user_id, 'booking.completed', 'booking', v_booking.id);

  return v_booking;
end;
$$;

create or replace function public.moderate_membership(
  p_membership_id uuid,
  p_status public.membership_status,
  p_reason text default null
)
returns public.campus_memberships
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor_id uuid := auth.uid();
  v_membership public.campus_memberships%rowtype;
  v_action private.moderation_action_kind;
begin
  if v_actor_id is null then
    raise exception using errcode = '42501', message = 'Authentication required';
  end if;

  if p_status is null
     or p_status not in ('verified', 'rejected', 'suspended', 'expired') then
    raise exception using errcode = '22023', message = 'Unsupported membership decision';
  end if;

  if p_status <> 'verified'
     and (
       p_reason is null
       or char_length(btrim(p_reason)) not between 3 and 2000
     ) then
    raise exception using errcode = '22023', message = 'A moderation reason is required';
  end if;

  select * into v_membership
  from public.campus_memberships m
  where m.id = p_membership_id
  for update;

  if v_membership.id is null
     or not private.is_moderator(v_actor_id, v_membership.campus_id) then
    raise exception using errcode = '42501', message = 'Moderator access required';
  end if;

  if v_membership.status = p_status
     or not (
       (v_membership.status = 'pending' and p_status in ('verified', 'rejected', 'suspended'))
       or (v_membership.status = 'verified' and p_status in ('suspended', 'expired'))
       or (v_membership.status in ('rejected', 'suspended', 'expired') and p_status = 'verified')
     ) then
    raise exception using errcode = '40001', message = 'Membership transition is not allowed';
  end if;

  update public.campus_memberships
  set status = p_status,
      verified_at = case when p_status = 'verified' then now() else verified_at end,
      expires_at = case
        when p_status = 'verified' then now() + interval '1 year'
        else expires_at
      end
  where id = v_membership.id
  returning * into v_membership;

  if p_status in ('rejected', 'suspended', 'expired') then
    update public.listings
    set status = 'paused'
    where seller_id = v_membership.user_id
      and campus_id = v_membership.campus_id
      and status in ('active', 'reserved');

    update public.services
    set status = 'paused'
    where provider_id = v_membership.user_id
      and campus_id = v_membership.campus_id
      and status in ('active', 'reserved');
  end if;

  v_action := (
    case p_status
      when 'verified' then 'verify_membership'
      when 'rejected' then 'reject_membership'
      else 'suspend_membership'
    end
  )::private.moderation_action_kind;

  insert into private.moderation_actions(
    moderator_id,
    campus_id,
    action,
    entity_type,
    entity_id,
    reason
  )
  values (
    v_actor_id,
    v_membership.campus_id,
    v_action,
    'membership',
    v_membership.id,
    nullif(btrim(p_reason), '')
  );

  return v_membership;
end;
$$;

create or replace function public.moderate_listing(
  p_listing_id uuid,
  p_approve boolean,
  p_reason text default null
)
returns public.listings
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor_id uuid := auth.uid();
  v_listing public.listings%rowtype;
begin
  if v_actor_id is null then
    raise exception using errcode = '42501', message = 'Authentication required';
  end if;

  if p_approve is null then
    raise exception using errcode = '22023', message = 'Listing moderation decision is required';
  end if;

  select * into v_listing
  from public.listings l
  where l.id = p_listing_id
  for update;

  if v_listing.id is null
     or v_listing.status <> 'pending'
     or not private.is_moderator(v_actor_id, v_listing.campus_id) then
    raise exception using errcode = '42501', message = 'Pending listing and moderator access required';
  end if;

  if p_approve
     and (
       not private.is_verified_member(v_listing.seller_id, v_listing.campus_id)
       or not exists (
         select 1
         from public.campus_categories cc
         where cc.campus_id = v_listing.campus_id
           and cc.name = v_listing.category
           and cc.is_active
           and cc.scope in ('listing', 'both')
       )
       or (
         v_listing.pickup_zone is not null
         and not exists (
           select 1
           from public.campus_pickup_zones z
           where z.campus_id = v_listing.campus_id
             and z.label = v_listing.pickup_zone
             and z.is_active
         )
       )
       or (
         v_listing.kind <> 'wanted'
         and not exists (
           select 1
           from public.listing_images i
           join public.listing_image_uploads u
             on u.image_id = i.id
            and u.listing_id = i.listing_id
           where i.listing_id = v_listing.id
             and i.processing_status = 'ready'
             and u.object_path is not null
             and u.processed_at is not null
         )
       )
     ) then
    raise exception using errcode = '42501', message = 'Listing owner or media is no longer eligible';
  end if;

  if not p_approve and nullif(btrim(p_reason), '') is null then
    raise exception using errcode = '22023', message = 'A rejection reason is required';
  end if;

  update public.listings
  set status = case
        when p_approve then 'active'::public.content_status
        else 'rejected'::public.content_status
      end,
      published_at = case when p_approve then now() else null end,
      expires_at = case when p_approve then now() + interval '45 days' else null end
  where id = v_listing.id
  returning * into v_listing;

  insert into private.moderation_actions(
    moderator_id,
    campus_id,
    action,
    entity_type,
    entity_id,
    reason
  )
  values (
    v_actor_id,
    v_listing.campus_id,
    case
      when p_approve then 'approve_content'::private.moderation_action_kind
      else 'reject_content'::private.moderation_action_kind
    end,
    'listing',
    v_listing.id,
    nullif(btrim(p_reason), '')
  );

  return v_listing;
end;
$$;

create or replace function public.moderate_service(
  p_service_id uuid,
  p_approve boolean,
  p_reason text default null
)
returns public.services
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor_id uuid := auth.uid();
  v_service public.services%rowtype;
begin
  if v_actor_id is null then
    raise exception using errcode = '42501', message = 'Authentication required';
  end if;

  if p_approve is null then
    raise exception using errcode = '22023', message = 'Service moderation decision is required';
  end if;

  select * into v_service
  from public.services s
  where s.id = p_service_id
  for update;

  if v_service.id is null
     or v_service.status <> 'pending'
     or not private.is_moderator(v_actor_id, v_service.campus_id) then
    raise exception using errcode = '42501', message = 'Pending service and moderator access required';
  end if;

  if p_approve
     and (
       not private.is_verified_member(v_service.provider_id, v_service.campus_id)
       or not exists (
         select 1
         from public.campus_categories cc
         where cc.campus_id = v_service.campus_id
           and cc.name = v_service.category
           and cc.is_active
           and cc.scope in ('service', 'both')
       )
       or (
         v_service.pickup_zone is not null
         and not exists (
           select 1
           from public.campus_pickup_zones z
           where z.campus_id = v_service.campus_id
             and z.label = v_service.pickup_zone
             and z.is_active
         )
       )
       or not exists (
         select 1
         from public.service_availability a
         where a.service_id = v_service.id
           and a.is_active
       )
     ) then
    raise exception using errcode = '42501', message = 'Service provider or availability is no longer eligible';
  end if;

  if not p_approve and nullif(btrim(p_reason), '') is null then
    raise exception using errcode = '22023', message = 'A rejection reason is required';
  end if;

  update public.services
  set status = case
        when p_approve then 'active'::public.content_status
        else 'rejected'::public.content_status
      end,
      published_at = case when p_approve then now() else null end,
      expires_at = case when p_approve then now() + interval '90 days' else null end
  where id = v_service.id
  returning * into v_service;

  insert into private.moderation_actions(
    moderator_id,
    campus_id,
    action,
    entity_type,
    entity_id,
    reason
  )
  values (
    v_actor_id,
    v_service.campus_id,
    case
      when p_approve then 'approve_content'::private.moderation_action_kind
      else 'reject_content'::private.moderation_action_kind
    end,
    'service',
    v_service.id,
    nullif(btrim(p_reason), '')
  );

  return v_service;
end;
$$;

create or replace function public.moderate_remove_listing(
  p_listing_id uuid,
  p_reason text
)
returns public.listings
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor_id uuid := auth.uid();
  v_listing public.listings%rowtype;
begin
  if v_actor_id is null then
    raise exception using errcode = '42501', message = 'Authentication required';
  end if;

  if p_reason is null
     or char_length(btrim(p_reason)) not between 3 and 2000 then
    raise exception using errcode = '22023', message = 'A removal reason is required';
  end if;

  select * into v_listing
  from public.listings l
  where l.id = p_listing_id
  for update;

  if v_listing.id is null
     or v_listing.status = 'removed'
     or not private.is_moderator(v_actor_id, v_listing.campus_id) then
    raise exception using errcode = '42501', message = 'Listing and moderator access required';
  end if;

  update public.listings
  set status = 'removed',
      deleted_at = now()
  where id = v_listing.id
  returning * into v_listing;

  update public.offers
  set status = 'cancelled'
  where listing_id = v_listing.id
    and status = 'pending';

  insert into private.moderation_actions(
    moderator_id,
    campus_id,
    action,
    entity_type,
    entity_id,
    reason
  )
  values (
    v_actor_id,
    v_listing.campus_id,
    'remove_content',
    'listing',
    v_listing.id,
    btrim(p_reason)
  );

  return v_listing;
end;
$$;

create or replace function public.moderate_remove_service(
  p_service_id uuid,
  p_reason text
)
returns public.services
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor_id uuid := auth.uid();
  v_service public.services%rowtype;
begin
  if v_actor_id is null then
    raise exception using errcode = '42501', message = 'Authentication required';
  end if;

  if p_reason is null
     or char_length(btrim(p_reason)) not between 3 and 2000 then
    raise exception using errcode = '22023', message = 'A removal reason is required';
  end if;

  select * into v_service
  from public.services s
  where s.id = p_service_id
  for update;

  if v_service.id is null
     or v_service.status = 'removed'
     or not private.is_moderator(v_actor_id, v_service.campus_id) then
    raise exception using errcode = '42501', message = 'Service and moderator access required';
  end if;

  update public.services
  set status = 'removed',
      deleted_at = now()
  where id = v_service.id
  returning * into v_service;

  update public.service_requests
  set status = 'cancelled'
  where service_id = v_service.id
    and status = 'pending';

  insert into private.moderation_actions(
    moderator_id,
    campus_id,
    action,
    entity_type,
    entity_id,
    reason
  )
  values (
    v_actor_id,
    v_service.campus_id,
    'remove_content',
    'service',
    v_service.id,
    btrim(p_reason)
  );

  return v_service;
end;
$$;

create or replace function public.moderate_review(
  p_review_id uuid,
  p_status public.review_status,
  p_reason text
)
returns public.reviews
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor_id uuid := auth.uid();
  v_review public.reviews%rowtype;
  v_campus_id uuid;
begin
  if v_actor_id is null then
    raise exception using errcode = '42501', message = 'Authentication required';
  end if;

  if p_status is null
     or p_reason is null
     or p_status not in ('published', 'hidden', 'removed')
     or char_length(btrim(p_reason)) not between 3 and 2000 then
    raise exception using errcode = '22023', message = 'A review decision and reason are required';
  end if;

  select * into v_review
  from public.reviews r
  where r.id = p_review_id
  for update;

  select coalesce(l.campus_id, s.campus_id) into v_campus_id
  from public.bookings b
  left join public.offers o on o.id = b.offer_id
  left join public.listings l on l.id = o.listing_id
  left join public.service_requests sr on sr.id = b.service_request_id
  left join public.services s on s.id = sr.service_id
  where b.id = v_review.booking_id;

  if v_review.id is null
     or v_campus_id is null
     or not private.is_moderator(v_actor_id, v_campus_id) then
    raise exception using errcode = '42501', message = 'Review and moderator access required';
  end if;

  update public.reviews
  set status = p_status
  where id = v_review.id
  returning * into v_review;

  insert into private.moderation_actions(
    moderator_id,
    campus_id,
    action,
    entity_type,
    entity_id,
    reason,
    metadata
  )
  values (
    v_actor_id,
    v_campus_id,
    case
      when p_status = 'published' then 'restore_content'::private.moderation_action_kind
      else 'remove_content'::private.moderation_action_kind
    end,
    'review',
    v_review.id,
    btrim(p_reason),
    jsonb_build_object('status', p_status)
  );

  return v_review;
end;
$$;

create or replace function public.resolve_report(
  p_report_id uuid,
  p_status public.report_status,
  p_resolution_note text
)
returns public.reports
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor_id uuid := auth.uid();
  v_report public.reports%rowtype;
begin
  if v_actor_id is null then
    raise exception using errcode = '42501', message = 'Authentication required';
  end if;

  if p_status is null
     or p_resolution_note is null
     or p_status not in ('actioned', 'dismissed')
     or char_length(btrim(p_resolution_note)) not between 3 and 2000 then
    raise exception using errcode = '22023', message = 'A final status and resolution note are required';
  end if;

  select * into v_report
  from public.reports r
  where r.id = p_report_id
  for update;

  if v_report.id is null
     or v_report.status not in ('open', 'triaged')
     or not private.is_moderator(v_actor_id, v_report.campus_id) then
    raise exception using errcode = '42501', message = 'Open report and moderator access required';
  end if;

  update public.reports
  set status = p_status,
      resolution_note = btrim(p_resolution_note),
      resolved_by = v_actor_id,
      resolved_at = now()
  where id = v_report.id
  returning * into v_report;

  insert into private.moderation_actions(
    moderator_id,
    campus_id,
    action,
    entity_type,
    entity_id,
    reason,
    metadata
  )
  values (
    v_actor_id,
    v_report.campus_id,
    'resolve_report',
    'report',
    v_report.id,
    btrim(p_resolution_note),
    jsonb_build_object('status', p_status)
  );

  return v_report;
end;
$$;

-- Public functions receive EXECUTE by default in PostgreSQL. Revoke it first,
-- then grant only the audited API surface.
revoke all on all functions in schema public from public, anon, authenticated;

grant execute on function public.reserve_listing_image(uuid, integer, text, text)
to authenticated, service_role;
grant execute on function public.submit_listing(uuid) to authenticated, service_role;
grant execute on function public.withdraw_listing(uuid) to authenticated, service_role;
grant execute on function public.mark_listing_fulfilled(uuid) to authenticated, service_role;
grant execute on function public.submit_service(uuid) to authenticated, service_role;
grant execute on function public.withdraw_service(uuid) to authenticated, service_role;
grant execute on function public.respond_to_offer(uuid, boolean) to authenticated, service_role;
grant execute on function public.cancel_offer(uuid) to authenticated, service_role;
grant execute on function public.respond_to_service_request(uuid, boolean) to authenticated, service_role;
grant execute on function public.cancel_service_request(uuid) to authenticated, service_role;
grant execute on function public.cancel_booking(uuid) to authenticated, service_role;
grant execute on function public.complete_booking(uuid) to authenticated, service_role;
grant execute on function public.moderate_membership(uuid, public.membership_status, text) to authenticated, service_role;
grant execute on function public.moderate_listing(uuid, boolean, text) to authenticated, service_role;
grant execute on function public.moderate_service(uuid, boolean, text) to authenticated, service_role;
grant execute on function public.moderate_remove_listing(uuid, text) to authenticated, service_role;
grant execute on function public.moderate_remove_service(uuid, text) to authenticated, service_role;
grant execute on function public.moderate_review(uuid, public.review_status, text) to authenticated, service_role;
grant execute on function public.resolve_report(uuid, public.report_status, text) to authenticated, service_role;

-- User uploads first land in a private staging bucket. Browser roles receive
-- no INSERT policy: a Vercel route must validate the immutable reservation and
-- issue a short-lived signed upload token using a server-only credential. A
-- trusted processor decodes, validates, strips metadata, re-encodes to WebP,
-- writes to `listing-images`, updates both image tables, and deletes staging.
insert into storage.buckets(
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values
  (
    'listing-upload-staging',
    'listing-upload-staging',
    false,
    5242880,
    array['image/jpeg', 'image/png', 'image/webp']
  ),
  (
    'listing-images',
    'listing-images',
    false,
    5242880,
    array['image/webp']
  ),
  (
    'avatars',
    'avatars',
    true,
    2097152,
    array['image/webp']
  )
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

do $storage_policy$
begin
  if exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'processed_listing_image_owner_read'
  ) then
    drop policy processed_listing_image_owner_read on storage.objects;
  end if;
end
$storage_policy$;

create policy processed_listing_image_owner_read
on storage.objects
for select
to authenticated
using (
  bucket_id = 'listing-images'
  and exists (
    select 1
    from public.listing_image_uploads u
    join public.listing_images i on i.id = u.image_id
    join public.listings l on l.id = i.listing_id
    where u.object_path = name
      and i.processing_status = 'ready'
      and (
        l.seller_id = (select auth.uid())
        or exists (
          select 1
          from public.offers o
          where o.listing_id = l.id
            and (select auth.uid()) in (o.proposer_id, o.recipient_id)
            and o.status in ('accepted', 'cancelled', 'completed')
        )
      )
  )
);

-- The avatar bucket is public by product design, but has no authenticated write
-- policy. Only the trusted image-processing route may write/delete avatars with
-- a server-only secret after decoding, stripping metadata, and re-encoding.

commit;
