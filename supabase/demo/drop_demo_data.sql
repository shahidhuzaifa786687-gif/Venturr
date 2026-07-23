\set ON_ERROR_STOP on

-- Removes only rows recorded by `seed_demo_data.sql`.
--
-- If a real user has interacted with demo users, listings, services, or the
-- demo campus, this script aborts the entire transaction instead of cascading
-- into or rewriting that existing activity.

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
begin
  if exists (
    select 1
    from public.campus_memberships cm
    join private.venturr_demo_manifest campus
      on campus.seed_name = v_seed
     and campus.entity = 'campus'
     and campus.record_key = cm.campus_id::text
    where not exists (
      select 1
      from private.venturr_demo_manifest users
      where users.seed_name = v_seed
        and users.entity = 'auth_user'
        and users.record_key = cm.user_id::text
    )
  ) then
    raise exception 'Cleanup stopped: a non-demo user belongs to the demo campus';
  end if;

  if exists (
    select 1
    from public.profiles p
    join private.venturr_demo_manifest campus
      on campus.seed_name = v_seed
     and campus.entity = 'campus'
     and campus.record_key = p.preferred_campus_id::text
    where not exists (
      select 1
      from private.venturr_demo_manifest users
      where users.seed_name = v_seed
        and users.entity = 'auth_user'
        and users.record_key = p.user_id::text
    )
  ) then
    raise exception 'Cleanup stopped: a non-demo profile uses the demo campus';
  end if;

  if exists (
    select 1
    from public.listings l
    join private.venturr_demo_manifest campus
      on campus.seed_name = v_seed
     and campus.entity = 'campus'
     and campus.record_key = l.campus_id::text
    where not exists (
      select 1
      from private.venturr_demo_manifest demo_listing
      where demo_listing.seed_name = v_seed
        and demo_listing.entity = 'listing'
        and demo_listing.record_key = l.id::text
    )
  ) then
    raise exception 'Cleanup stopped: a non-demo listing uses the demo campus';
  end if;

  if exists (
    select 1
    from public.services s
    join private.venturr_demo_manifest campus
      on campus.seed_name = v_seed
     and campus.entity = 'campus'
     and campus.record_key = s.campus_id::text
    where not exists (
      select 1
      from private.venturr_demo_manifest demo_service
      where demo_service.seed_name = v_seed
        and demo_service.entity = 'service'
        and demo_service.record_key = s.id::text
    )
  ) then
    raise exception 'Cleanup stopped: a non-demo service uses the demo campus';
  end if;

  if exists (
    select 1
    from public.favorites f
    where (
      exists (
        select 1
        from private.venturr_demo_manifest m
        where m.seed_name = v_seed
          and m.entity = 'listing'
          and m.record_key = f.listing_id::text
      )
      or exists (
        select 1
        from private.venturr_demo_manifest m
        where m.seed_name = v_seed
          and m.entity = 'service'
          and m.record_key = f.service_id::text
      )
    )
    and not exists (
      select 1
      from private.venturr_demo_manifest u
      where u.seed_name = v_seed
        and u.entity = 'auth_user'
        and u.record_key = f.user_id::text
    )
  ) then
    raise exception 'Cleanup stopped: a real user saved demo content';
  end if;

  if exists (
    select 1
    from public.conversations c
    where exists (
      select 1
      from private.venturr_demo_manifest m
      where m.seed_name = v_seed
        and (
          (m.entity = 'listing' and m.record_key = c.listing_id::text)
          or (m.entity = 'service' and m.record_key = c.service_id::text)
          or (
            m.entity = 'auth_user'
            and m.record_key in (c.initiator_id::text, c.recipient_id::text)
          )
        )
    )
  ) then
    raise exception 'Cleanup stopped: conversations depend on demo content or users';
  end if;

  if exists (
    select 1
    from public.offers o
    join private.venturr_demo_manifest m
      on m.seed_name = v_seed
     and m.entity = 'listing'
     and m.record_key = o.listing_id::text
  ) then
    raise exception 'Cleanup stopped: offers depend on demo listings';
  end if;

  if exists (
    select 1
    from public.service_requests r
    join private.venturr_demo_manifest m
      on m.seed_name = v_seed
     and m.entity = 'service'
     and m.record_key = r.service_id::text
  ) then
    raise exception 'Cleanup stopped: requests depend on demo services';
  end if;

  if exists (
    select 1
    from public.bookings b
    where exists (
      select 1
      from private.venturr_demo_manifest m
      where m.seed_name = v_seed
        and m.entity = 'auth_user'
        and m.record_key in (b.customer_id::text, b.provider_id::text)
    )
  ) then
    raise exception 'Cleanup stopped: bookings depend on demo users';
  end if;

  if exists (
    select 1
    from public.reviews r
    where exists (
      select 1
      from private.venturr_demo_manifest m
      where m.seed_name = v_seed
        and m.entity = 'auth_user'
        and m.record_key in (r.reviewer_id::text, r.reviewee_id::text)
    )
  ) then
    raise exception 'Cleanup stopped: reviews depend on demo users';
  end if;

  if exists (
    select 1
    from public.blocks b
    where exists (
      select 1
      from private.venturr_demo_manifest m
      where m.seed_name = v_seed
        and m.entity = 'auth_user'
        and m.record_key in (b.blocker_id::text, b.blocked_id::text)
    )
  ) then
    raise exception 'Cleanup stopped: block records depend on demo users';
  end if;

  if exists (
    select 1
    from public.reports r
    where exists (
      select 1
      from private.venturr_demo_manifest m
      where m.seed_name = v_seed
        and (
          (m.entity = 'listing' and m.record_key = r.listing_id::text)
          or (m.entity = 'service' and m.record_key = r.service_id::text)
          or (m.entity = 'profile' and m.record_key = r.profile_id::text)
          or (m.entity = 'campus' and m.record_key = r.campus_id::text)
        )
    )
  ) then
    raise exception 'Cleanup stopped: reports depend on demo records';
  end if;
end
$guard$;

delete from public.service_availability a
using private.venturr_demo_manifest m
where m.seed_name = 'venturr_demo_v1'
  and m.entity = 'service_availability'
  and m.record_key = a.id::text;

delete from public.services s
using private.venturr_demo_manifest m
where m.seed_name = 'venturr_demo_v1'
  and m.entity = 'service'
  and m.record_key = s.id::text;

delete from public.listings l
using private.venturr_demo_manifest m
where m.seed_name = 'venturr_demo_v1'
  and m.entity = 'listing'
  and m.record_key = l.id::text;

delete from public.campus_memberships cm
using private.venturr_demo_manifest m
where m.seed_name = 'venturr_demo_v1'
  and m.entity = 'campus_membership'
  and m.record_key = cm.id::text;

delete from auth.identities i
using private.venturr_demo_manifest m
where m.seed_name = 'venturr_demo_v1'
  and m.entity = 'auth_identity'
  and m.record_key = i.id::text;

delete from public.profiles p
using private.venturr_demo_manifest m
where m.seed_name = 'venturr_demo_v1'
  and m.entity = 'profile'
  and m.record_key = p.user_id::text;

delete from auth.users u
using private.venturr_demo_manifest m
where m.seed_name = 'venturr_demo_v1'
  and m.entity = 'auth_user'
  and m.record_key = u.id::text;

delete from public.campus_pickup_zones z
using private.venturr_demo_manifest m
where m.seed_name = 'venturr_demo_v1'
  and m.entity = 'campus_zone'
  and m.record_key = z.campus_id::text || '|' || z.label;

delete from public.campus_categories c
using private.venturr_demo_manifest m
where m.seed_name = 'venturr_demo_v1'
  and m.entity = 'campus_category'
  and m.record_key = c.campus_id::text || '|' || c.name;

delete from public.campus_email_domains d
using private.venturr_demo_manifest m
where m.seed_name = 'venturr_demo_v1'
  and m.entity = 'campus_domain'
  and m.record_key = d.campus_id::text || '|' || d.domain;

delete from public.campuses c
using private.venturr_demo_manifest m
where m.seed_name = 'venturr_demo_v1'
  and m.entity = 'campus'
  and m.record_key = c.id::text;

delete from private.venturr_demo_manifest
where seed_name = 'venturr_demo_v1';

commit;

\echo 'Venturr demo records were removed. Existing non-demo data was not changed.'
