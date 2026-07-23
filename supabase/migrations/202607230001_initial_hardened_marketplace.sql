begin;

-- `if not exists` emits harmless NOTICE messages on a repeat run. Keep those
-- out of deploy logs while still surfacing WARNING and ERROR conditions.
set local client_min_messages = warning;

-- Venturr production baseline.
-- This migration intentionally keeps privileged authorization data in `private`,
-- exposes only narrowly scoped RPCs, and treats RLS as the final authorization
-- boundary for browser/server clients carrying an end-user JWT.

create schema if not exists extensions;
create schema if not exists private;

create extension if not exists pgcrypto with schema extensions;
create extension if not exists btree_gist with schema extensions;

revoke all on schema private from public;
revoke all on schema private from anon, authenticated;
revoke create on schema public from public;

-- PostgreSQL has no `create type if not exists`. Keep this baseline safe to
-- reapply without dropping or recreating enum types that may already be used
-- by existing rows.
do $enum_types$
begin
  if to_regtype('public.membership_role') is null then
    create type public.membership_role as enum (
      'student', 'staff', 'faculty', 'alumni'
    );
  end if;

  if to_regtype('public.membership_status') is null then
    create type public.membership_status as enum (
      'pending', 'verified', 'rejected', 'suspended', 'expired'
    );
  end if;

  if to_regtype('private.moderator_role') is null then
    create type private.moderator_role as enum ('moderator', 'admin');
  end if;

  if to_regtype('public.listing_kind') is null then
    create type public.listing_kind as enum ('sale', 'rent', 'free', 'wanted');
  end if;

  if to_regtype('public.content_status') is null then
    create type public.content_status as enum (
      'draft', 'pending', 'active', 'paused', 'reserved', 'fulfilled',
      'expired', 'rejected', 'removed'
    );
  end if;

  if to_regtype('public.listing_condition') is null then
    create type public.listing_condition as enum (
      'new', 'like_new', 'good', 'fair', 'poor', 'not_applicable'
    );
  end if;

  if to_regtype('public.price_unit') is null then
    create type public.price_unit as enum (
      'item', 'hour', 'day', 'week', 'month', 'session'
    );
  end if;

  if to_regtype('public.service_mode') is null then
    create type public.service_mode as enum ('in_person', 'online', 'hybrid');
  end if;

  if to_regtype('public.category_scope') is null then
    create type public.category_scope as enum ('listing', 'service', 'both');
  end if;

  if to_regtype('public.availability_kind') is null then
    create type public.availability_kind as enum ('weekly', 'one_off');
  end if;

  if to_regtype('public.image_processing_status') is null then
    create type public.image_processing_status as enum (
      'pending', 'ready', 'rejected'
    );
  end if;

  if to_regtype('public.conversation_status') is null then
    create type public.conversation_status as enum ('open', 'archived', 'closed');
  end if;

  if to_regtype('public.message_kind') is null then
    create type public.message_kind as enum ('text', 'system');
  end if;

  if to_regtype('public.offer_kind') is null then
    create type public.offer_kind as enum (
      'purchase', 'rental', 'claim_free', 'fulfill_wanted'
    );
  end if;

  if to_regtype('public.offer_status') is null then
    create type public.offer_status as enum (
      'pending', 'accepted', 'declined', 'cancelled', 'expired', 'completed'
    );
  end if;

  if to_regtype('public.request_status') is null then
    create type public.request_status as enum (
      'pending', 'accepted', 'declined', 'cancelled', 'expired', 'completed'
    );
  end if;

  if to_regtype('public.booking_status') is null then
    create type public.booking_status as enum (
      'confirmed', 'cancelled', 'completed', 'no_show', 'disputed'
    );
  end if;

  if to_regtype('public.review_status') is null then
    create type public.review_status as enum ('published', 'hidden', 'removed');
  end if;

  if to_regtype('public.report_reason') is null then
    create type public.report_reason as enum (
      'spam', 'scam', 'prohibited_item', 'harassment', 'unsafe_content',
      'impersonation', 'privacy', 'other'
    );
  end if;

  if to_regtype('public.report_status') is null then
    create type public.report_status as enum (
      'open', 'triaged', 'actioned', 'dismissed'
    );
  end if;

  if to_regtype('private.moderation_action_kind') is null then
    create type private.moderation_action_kind as enum (
      'verify_membership', 'reject_membership', 'suspend_membership',
      'approve_content', 'reject_content', 'remove_content', 'restore_content',
      'resolve_report', 'warn_user', 'suspend_user', 'unsuspend_user', 'other'
    );
  end if;
end
$enum_types$;

create table if not exists public.campuses (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null,
  city text,
  country_code text not null default 'IN',
  timezone text not null default 'Asia/Kolkata',
  currency_code text not null default 'INR',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint campuses_slug_format check (
    slug = lower(slug)
    and slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'
    and char_length(slug) between 2 and 64
  ),
  constraint campuses_name_length check (char_length(btrim(name)) between 2 and 120),
  constraint campuses_city_length check (city is null or char_length(btrim(city)) between 2 and 100),
  constraint campuses_country_code_format check (country_code ~ '^[A-Z]{2}$'),
  constraint campuses_currency_code_format check (currency_code ~ '^[A-Z]{3}$')
);

create table if not exists public.campus_email_domains (
  campus_id uuid not null references public.campuses(id) on delete cascade,
  domain text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  primary key (campus_id, domain),
  constraint campus_email_domains_normalized check (
    domain = lower(domain)
    and position('..' in domain) = 0
    and domain ~ '^[a-z0-9](?:[a-z0-9.-]{0,251}[a-z0-9])?$'
    and position('.' in domain) > 0
  )
);

create table if not exists public.campus_categories (
  campus_id uuid not null references public.campuses(id) on delete cascade,
  name text not null,
  scope public.category_scope not null default 'both',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  primary key (campus_id, name),
  constraint campus_categories_name check (
    char_length(btrim(name)) between 2 and 50
    and name = btrim(name)
    and name !~ '[[:cntrl:]]'
  )
);

create table if not exists public.campus_pickup_zones (
  campus_id uuid not null references public.campuses(id) on delete cascade,
  label text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  primary key (campus_id, label),
  constraint campus_pickup_zones_label check (
    char_length(btrim(label)) between 2 and 80
    and label = btrim(label)
    and label !~ '[[:cntrl:]]'
  )
);

create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null,
  avatar_path text,
  preferred_campus_id uuid references public.campuses(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_display_name_length check (
    char_length(btrim(display_name)) between 1 and 60
    and display_name !~ '[[:cntrl:]]'
  ),
  constraint profiles_avatar_path check (
    avatar_path is null
    or avatar_path = user_id::text || '/avatar.webp'
  )
);

create table if not exists public.campus_memberships (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  campus_id uuid not null references public.campuses(id) on delete cascade,
  role public.membership_role not null default 'student',
  status public.membership_status not null default 'pending',
  verified_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, campus_id),
  constraint campus_memberships_verification_consistency check (
    (status = 'verified' and verified_at is not null)
    or (status <> 'verified')
  ),
  constraint campus_memberships_expiry_order check (
    expires_at is null or expires_at > created_at
  )
);

create table if not exists private.moderator_assignments (
  user_id uuid not null references auth.users(id) on delete cascade,
  campus_id uuid not null references public.campuses(id) on delete cascade,
  role private.moderator_role not null default 'moderator',
  granted_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  primary key (user_id, campus_id)
);

create table if not exists public.listings (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null references auth.users(id) on delete restrict,
  campus_id uuid not null references public.campuses(id) on delete restrict,
  kind public.listing_kind not null,
  status public.content_status not null default 'draft',
  title text not null,
  description text not null,
  category text not null,
  condition public.listing_condition not null default 'good',
  price_minor bigint,
  currency_code text not null,
  price_unit public.price_unit not null default 'item',
  rental_deposit_minor bigint,
  quantity smallint not null default 1,
  pickup_zone text,
  expires_at timestamptz,
  published_at timestamptz,
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (campus_id, category)
    references public.campus_categories(campus_id, name)
    on delete restrict,
  foreign key (campus_id, pickup_zone)
    references public.campus_pickup_zones(campus_id, label)
    on delete restrict,
  search_document tsvector generated always as (
    to_tsvector(
      'simple',
      coalesce(title, '') || ' ' ||
      coalesce(description, '') || ' ' ||
      coalesce(category, '')
    )
  ) stored,
  constraint listings_title_length check (
    char_length(btrim(title)) between 3 and 100
    and title !~ '[[:cntrl:]]'
  ),
  constraint listings_description_length check (
    char_length(btrim(description)) between 10 and 2000
    and regexp_replace(description, E'[\\n\\r\\t]', '', 'g') !~ '[[:cntrl:]]'
  ),
  constraint listings_category_length check (
    char_length(btrim(category)) between 2 and 50
    and category !~ '[[:cntrl:]]'
  ),
  constraint listings_currency_code_format check (currency_code ~ '^[A-Z]{3}$'),
  constraint listings_quantity_range check (quantity between 1 and 20),
  constraint listings_pickup_zone_length check (
    pickup_zone is null
    or (
      char_length(btrim(pickup_zone)) between 2 and 80
      and pickup_zone !~ '[[:cntrl:]]'
    )
  ),
  constraint listings_price_by_kind check (
    (kind = 'sale' and price_minor is not null and price_minor > 0 and price_unit = 'item')
    or (kind = 'rent' and price_minor is not null and price_minor > 0 and price_unit in ('day', 'week', 'month'))
    or (kind = 'free' and price_minor = 0 and price_unit = 'item')
    or (kind = 'wanted' and (price_minor is null or price_minor >= 0) and price_unit = 'item')
  ),
  constraint listings_price_ceiling check (
    price_minor is null or price_minor <= 1000000000
  ),
  constraint listings_deposit_valid check (
    rental_deposit_minor is null
    or (
      kind = 'rent'
      and rental_deposit_minor between 0 and 1000000000
    )
  ),
  constraint listings_publish_fields check (
    (status in ('draft', 'pending', 'rejected') and published_at is null)
    or status in ('active', 'paused', 'reserved', 'fulfilled', 'expired', 'removed')
  ),
  constraint listings_deleted_state check (
    deleted_at is null or status = 'removed'
  )
);

create table if not exists public.listing_images (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.listings(id) on delete cascade,
  position smallint not null,
  processing_status public.image_processing_status not null default 'pending',
  mime_type text,
  byte_size integer,
  width integer,
  height integer,
  sha256_hex text,
  alt_text text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, listing_id),
  unique (listing_id, position),
  constraint listing_images_position_range check (position between 0 and 3),
  constraint listing_images_processing_consistency check (
    processing_status <> 'ready'
    or (
      mime_type = 'image/webp'
      and byte_size is not null
      and width is not null
      and height is not null
      and sha256_hex is not null
    )
  ),
  constraint listing_images_dimensions check (
    (width is null and height is null)
    or (width between 1 and 4096 and height between 1 and 4096)
  ),
  constraint listing_images_byte_size check (
    byte_size is null or byte_size between 1 and 5242880
  ),
  constraint listing_images_hash_format check (
    sha256_hex is null or sha256_hex ~ '^[0-9a-f]{64}$'
  ),
  constraint listing_images_alt_text check (
    alt_text is null
    or (
      char_length(btrim(alt_text)) between 1 and 160
      and alt_text !~ '[[:cntrl:]]'
    )
  )
);

-- Storage object names are deliberately separated from the public image
-- projection. Reservation rows are immutable quota/audit records; processing
-- may detach an image but must not delete the reservation.
create table if not exists public.listing_image_uploads (
  id uuid primary key default gen_random_uuid(),
  image_id uuid unique,
  listing_id uuid not null references public.listings(id) on delete restrict,
  uploader_id uuid not null references auth.users(id) on delete restrict,
  source_path text not null unique,
  object_path text unique,
  created_at timestamptz not null default now(),
  processed_at timestamptz,
  foreign key (image_id, listing_id)
    references public.listing_images(id, listing_id)
    on delete set null (image_id),
  constraint listing_image_uploads_source_path_format check (
    source_path ~ '^[0-9a-f-]{36}/[0-9a-f-]{36}/[0-9a-f-]{36}\.(jpe?g|png|webp)$'
  ),
  constraint listing_image_uploads_object_path_format check (
    object_path is null
    or object_path ~ '^[0-9a-f-]{36}/[0-9a-f-]{36}/[0-9a-f-]{36}\.webp$'
  ),
  constraint listing_image_uploads_processing_consistency check (
    (object_path is null and processed_at is null)
    or (object_path is not null and processed_at is not null)
  )
);

create table if not exists public.services (
  id uuid primary key default gen_random_uuid(),
  provider_id uuid not null references auth.users(id) on delete restrict,
  campus_id uuid not null references public.campuses(id) on delete restrict,
  status public.content_status not null default 'draft',
  title text not null,
  description text not null,
  category text not null,
  mode public.service_mode not null,
  base_rate_minor bigint not null default 0,
  currency_code text not null,
  billing_unit public.price_unit not null default 'session',
  max_group_size smallint not null default 1,
  pickup_zone text,
  expires_at timestamptz,
  published_at timestamptz,
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (campus_id, category)
    references public.campus_categories(campus_id, name)
    on delete restrict,
  foreign key (campus_id, pickup_zone)
    references public.campus_pickup_zones(campus_id, label)
    on delete restrict,
  search_document tsvector generated always as (
    to_tsvector(
      'simple',
      coalesce(title, '') || ' ' ||
      coalesce(description, '') || ' ' ||
      coalesce(category, '')
    )
  ) stored,
  constraint services_title_length check (
    char_length(btrim(title)) between 3 and 100
    and title !~ '[[:cntrl:]]'
  ),
  constraint services_description_length check (
    char_length(btrim(description)) between 10 and 2000
    and regexp_replace(description, E'[\\n\\r\\t]', '', 'g') !~ '[[:cntrl:]]'
  ),
  constraint services_category_length check (
    char_length(btrim(category)) between 2 and 50
    and category !~ '[[:cntrl:]]'
  ),
  constraint services_currency_code_format check (currency_code ~ '^[A-Z]{3}$'),
  constraint services_rate_range check (base_rate_minor between 0 and 1000000000),
  constraint services_billing_unit check (billing_unit in ('hour', 'session')),
  constraint services_group_size check (max_group_size between 1 and 50),
  constraint services_pickup_zone_length check (
    pickup_zone is null
    or (
      char_length(btrim(pickup_zone)) between 2 and 80
      and pickup_zone !~ '[[:cntrl:]]'
    )
  ),
  constraint services_publish_fields check (
    (status in ('draft', 'pending', 'rejected') and published_at is null)
    or status in ('active', 'paused', 'reserved', 'fulfilled', 'expired', 'removed')
  ),
  constraint services_deleted_state check (
    deleted_at is null or status = 'removed'
  )
);

create table if not exists public.service_availability (
  id uuid primary key default gen_random_uuid(),
  service_id uuid not null references public.services(id) on delete cascade,
  kind public.availability_kind not null,
  weekday smallint,
  start_time time,
  end_time time,
  starts_at timestamptz,
  ends_at timestamptz,
  timezone text not null,
  valid_from date,
  valid_until date,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint service_availability_shape check (
    (
      kind = 'weekly'
      and weekday between 0 and 6
      and start_time is not null
      and end_time is not null
      and start_time < end_time
      and starts_at is null
      and ends_at is null
    )
    or (
      kind = 'one_off'
      and weekday is null
      and start_time is null
      and end_time is null
      and starts_at is not null
      and ends_at is not null
      and starts_at < ends_at
    )
  ),
  constraint service_availability_validity check (
    valid_until is null or valid_from is null or valid_until >= valid_from
  )
);

create table if not exists public.favorites (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  listing_id uuid references public.listings(id) on delete cascade,
  service_id uuid references public.services(id) on delete cascade,
  created_at timestamptz not null default now(),
  constraint favorites_one_target check (num_nonnulls(listing_id, service_id) = 1)
);

create unique index if not exists favorites_user_listing_unique
  on public.favorites(user_id, listing_id)
  where listing_id is not null;

create unique index if not exists favorites_user_service_unique
  on public.favorites(user_id, service_id)
  where service_id is not null;

create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  initiator_id uuid not null references auth.users(id) on delete restrict,
  recipient_id uuid not null references auth.users(id) on delete restrict,
  listing_id uuid references public.listings(id) on delete set null,
  service_id uuid references public.services(id) on delete set null,
  status public.conversation_status not null default 'open',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint conversations_different_participants check (initiator_id <> recipient_id),
  constraint conversations_at_most_one_target check (num_nonnulls(listing_id, service_id) <= 1)
);

create unique index if not exists conversations_listing_pair_unique
  on public.conversations(listing_id, initiator_id, recipient_id)
  where listing_id is not null;

create unique index if not exists conversations_service_pair_unique
  on public.conversations(service_id, initiator_id, recipient_id)
  where service_id is not null;

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references auth.users(id) on delete restrict,
  kind public.message_kind not null default 'text',
  body text not null,
  created_at timestamptz not null default now(),
  constraint messages_body_length check (
    char_length(btrim(body)) between 1 and 2000
    and regexp_replace(body, E'[\\n\\r\\t]', '', 'g') !~ '[[:cntrl:]]'
  )
);

create table if not exists public.offers (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.listings(id) on delete restrict,
  proposer_id uuid not null references auth.users(id) on delete restrict,
  recipient_id uuid not null references auth.users(id) on delete restrict,
  buyer_id uuid not null references auth.users(id) on delete restrict,
  seller_id uuid not null references auth.users(id) on delete restrict,
  kind public.offer_kind not null,
  offered_amount_minor bigint not null,
  rental_starts_at timestamptz,
  rental_ends_at timestamptz,
  note text,
  status public.offer_status not null default 'pending',
  expires_at timestamptz not null default (now() + interval '72 hours'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint offers_distinct_route_parties check (proposer_id <> recipient_id),
  constraint offers_distinct_parties check (buyer_id <> seller_id),
  constraint offers_parties_match_route check (
    proposer_id in (buyer_id, seller_id)
    and recipient_id in (buyer_id, seller_id)
  ),
  constraint offers_amount_range check (offered_amount_minor between 0 and 1000000000),
  constraint offers_rental_shape check (
    (
      kind = 'rental'
      and rental_starts_at is not null
      and rental_ends_at is not null
      and rental_starts_at < rental_ends_at
    )
    or (
      kind <> 'rental'
      and rental_starts_at is null
      and rental_ends_at is null
    )
  ),
  constraint offers_note_length check (
    note is null
    or (
      char_length(btrim(note)) between 1 and 500
      and regexp_replace(note, E'[\\n\\r\\t]', '', 'g') !~ '[[:cntrl:]]'
    )
  ),
  constraint offers_expiry_order check (expires_at > created_at)
);

create unique index if not exists offers_one_pending_per_proposer_listing
  on public.offers(listing_id, proposer_id)
  where status = 'pending';

create table if not exists public.service_requests (
  id uuid primary key default gen_random_uuid(),
  service_id uuid not null references public.services(id) on delete restrict,
  requester_id uuid not null references auth.users(id) on delete restrict,
  provider_id uuid not null references auth.users(id) on delete restrict,
  proposed_starts_at timestamptz not null,
  proposed_ends_at timestamptz not null,
  proposed_amount_minor bigint,
  note text,
  status public.request_status not null default 'pending',
  expires_at timestamptz not null default (now() + interval '72 hours'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint service_requests_distinct_parties check (requester_id <> provider_id),
  constraint service_requests_time_order check (proposed_starts_at < proposed_ends_at),
  constraint service_requests_future_end check (proposed_ends_at > created_at),
  constraint service_requests_amount_range check (
    proposed_amount_minor is null
    or proposed_amount_minor between 0 and 1000000000
  ),
  constraint service_requests_note_length check (
    note is null
    or (
      char_length(btrim(note)) between 1 and 1000
      and regexp_replace(note, E'[\\n\\r\\t]', '', 'g') !~ '[[:cntrl:]]'
    )
  ),
  constraint service_requests_expiry_order check (expires_at > created_at)
);

create table if not exists public.bookings (
  id uuid primary key default gen_random_uuid(),
  offer_id uuid unique references public.offers(id) on delete restrict,
  service_request_id uuid unique references public.service_requests(id) on delete restrict,
  customer_id uuid not null references auth.users(id) on delete restrict,
  provider_id uuid not null references auth.users(id) on delete restrict,
  starts_at timestamptz,
  ends_at timestamptz,
  amount_minor bigint not null,
  currency_code text not null,
  status public.booking_status not null default 'confirmed',
  customer_confirmed_at timestamptz,
  provider_confirmed_at timestamptz,
  completed_at timestamptz,
  cancelled_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint bookings_one_source check (num_nonnulls(offer_id, service_request_id) = 1),
  constraint bookings_distinct_parties check (customer_id <> provider_id),
  constraint bookings_time_pair check (
    (starts_at is null and ends_at is null)
    or (
      starts_at is not null
      and ends_at is not null
      and starts_at < ends_at
    )
  ),
  constraint bookings_amount_range check (amount_minor between 0 and 1000000000),
  constraint bookings_currency_code_format check (currency_code ~ '^[A-Z]{3}$'),
  constraint bookings_completion_consistency check (
    (
      status = 'completed'
      and completed_at is not null
      and customer_confirmed_at is not null
      and provider_confirmed_at is not null
    )
    or (status <> 'completed' and completed_at is null)
  ),
  constraint bookings_cancellation_consistency check (
    (status = 'cancelled' and cancelled_at is not null)
    or status <> 'cancelled'
  )
);

do $booking_overlap$
begin
  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.bookings'::regclass
      and conname = 'bookings_no_provider_overlap'
  ) then
    alter table public.bookings
      add constraint bookings_no_provider_overlap
      exclude using gist (
        provider_id with =,
        tstzrange(starts_at, ends_at, '[)') with &&
      )
      where (
        status = 'confirmed'
        and service_request_id is not null
        and starts_at is not null
        and ends_at is not null
      );
  end if;
end
$booking_overlap$;

create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete restrict,
  reviewer_id uuid not null references auth.users(id) on delete restrict,
  reviewee_id uuid not null references auth.users(id) on delete restrict,
  rating smallint not null,
  body text,
  status public.review_status not null default 'published',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (booking_id, reviewer_id),
  constraint reviews_distinct_parties check (reviewer_id <> reviewee_id),
  constraint reviews_rating_range check (rating between 1 and 5),
  constraint reviews_body_length check (
    body is null
    or (
      char_length(btrim(body)) between 1 and 1000
      and regexp_replace(body, E'[\\n\\r\\t]', '', 'g') !~ '[[:cntrl:]]'
    )
  )
);

create table if not exists public.blocks (
  blocker_id uuid not null references auth.users(id) on delete cascade,
  blocked_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  constraint blocks_not_self check (blocker_id <> blocked_id)
);

create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references auth.users(id) on delete restrict,
  campus_id uuid not null references public.campuses(id) on delete restrict,
  listing_id uuid references public.listings(id) on delete restrict,
  service_id uuid references public.services(id) on delete restrict,
  message_id uuid references public.messages(id) on delete restrict,
  review_id uuid references public.reviews(id) on delete restrict,
  booking_id uuid references public.bookings(id) on delete restrict,
  profile_id uuid references public.profiles(user_id) on delete restrict,
  reason public.report_reason not null,
  details text,
  status public.report_status not null default 'open',
  resolution_note text,
  resolved_by uuid references auth.users(id) on delete set null,
  resolved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint reports_one_target check (
    num_nonnulls(listing_id, service_id, message_id, review_id, booking_id, profile_id) = 1
  ),
  constraint reports_details_length check (
    details is null
    or (
      char_length(btrim(details)) between 1 and 2000
      and regexp_replace(details, E'[\\n\\r\\t]', '', 'g') !~ '[[:cntrl:]]'
    )
  ),
  constraint reports_resolution_consistency check (
    (
      status in ('actioned', 'dismissed')
      and resolved_by is not null
      and resolved_at is not null
    )
    or status in ('open', 'triaged')
  )
);

create table if not exists private.moderation_actions (
  id uuid primary key default gen_random_uuid(),
  moderator_id uuid not null references auth.users(id) on delete restrict,
  campus_id uuid not null references public.campuses(id) on delete restrict,
  action private.moderation_action_kind not null,
  entity_type text not null,
  entity_id uuid,
  reason text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint moderation_actions_entity_type check (
    entity_type in ('membership', 'listing', 'service', 'report', 'profile', 'review', 'message')
  ),
  constraint moderation_actions_reason_length check (
    reason is null or char_length(reason) between 1 and 2000
  ),
  constraint moderation_actions_metadata_object check (
    jsonb_typeof(metadata) = 'object'
  )
);

create table if not exists private.audit_events (
  id bigint generated always as identity primary key,
  actor_id uuid references auth.users(id) on delete set null,
  event_type text not null,
  entity_type text,
  entity_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  occurred_at timestamptz not null default now(),
  constraint audit_events_event_type_length check (char_length(event_type) between 2 and 100),
  constraint audit_events_metadata_object check (jsonb_typeof(metadata) = 'object')
);

create index if not exists campus_memberships_user_status_idx
  on public.campus_memberships(user_id, status, campus_id);
create index if not exists campus_memberships_campus_status_idx
  on public.campus_memberships(campus_id, status, user_id);
create index if not exists listings_market_idx
  on public.listings(campus_id, status, kind, created_at desc);
create index if not exists listings_seller_idx
  on public.listings(seller_id, created_at desc);
create index if not exists listings_expiry_idx
  on public.listings(expires_at)
  where status in ('active', 'reserved');
create index if not exists listings_search_idx
  on public.listings using gin(search_document);
create index if not exists listing_images_listing_ready_idx
  on public.listing_images(listing_id, position)
  where processing_status = 'ready';
create index if not exists listing_image_uploads_user_rate_idx
  on public.listing_image_uploads(uploader_id, created_at desc);
create index if not exists listing_image_uploads_listing_idx
  on public.listing_image_uploads(listing_id, created_at desc);
create index if not exists services_market_idx
  on public.services(campus_id, status, created_at desc);
create index if not exists services_provider_idx
  on public.services(provider_id, created_at desc);
create index if not exists services_search_idx
  on public.services using gin(search_document);
create index if not exists service_availability_service_idx
  on public.service_availability(service_id, is_active);
create index if not exists conversations_initiator_idx
  on public.conversations(initiator_id, updated_at desc);
create index if not exists conversations_recipient_idx
  on public.conversations(recipient_id, updated_at desc);
create index if not exists messages_conversation_idx
  on public.messages(conversation_id, created_at, id);
create index if not exists messages_sender_rate_idx
  on public.messages(sender_id, created_at desc);
create index if not exists offers_listing_idx
  on public.offers(listing_id, status, created_at desc);
create index if not exists offers_proposer_idx
  on public.offers(proposer_id, created_at desc);
create index if not exists service_requests_service_idx
  on public.service_requests(service_id, status, proposed_starts_at);
create index if not exists service_requests_requester_idx
  on public.service_requests(requester_id, created_at desc);
create unique index if not exists service_requests_one_pending_per_requester_service
  on public.service_requests(service_id, requester_id)
  where status = 'pending';
create index if not exists bookings_customer_idx
  on public.bookings(customer_id, created_at desc);
create index if not exists bookings_provider_idx
  on public.bookings(provider_id, created_at desc);
create index if not exists reviews_reviewee_idx
  on public.reviews(reviewee_id, status, created_at desc);
create index if not exists reports_campus_status_idx
  on public.reports(campus_id, status, created_at);
create index if not exists reports_reporter_rate_idx
  on public.reports(reporter_id, created_at desc);
create unique index if not exists reports_one_open_listing_per_reporter
  on public.reports(reporter_id, listing_id)
  where listing_id is not null and status in ('open', 'triaged');
create unique index if not exists reports_one_open_service_per_reporter
  on public.reports(reporter_id, service_id)
  where service_id is not null and status in ('open', 'triaged');
create unique index if not exists reports_one_open_message_per_reporter
  on public.reports(reporter_id, message_id)
  where message_id is not null and status in ('open', 'triaged');
create unique index if not exists reports_one_open_review_per_reporter
  on public.reports(reporter_id, review_id)
  where review_id is not null and status in ('open', 'triaged');
create unique index if not exists reports_one_open_booking_per_reporter
  on public.reports(reporter_id, booking_id)
  where booking_id is not null and status in ('open', 'triaged');
create unique index if not exists reports_one_open_profile_per_reporter
  on public.reports(reporter_id, profile_id)
  where profile_id is not null and status in ('open', 'triaged');
create index if not exists moderation_actions_campus_idx
  on private.moderation_actions(campus_id, created_at desc);
create index if not exists audit_events_entity_idx
  on private.audit_events(entity_type, entity_id, occurred_at desc);

commit;
