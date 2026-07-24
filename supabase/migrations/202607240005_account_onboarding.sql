begin;

set local client_min_messages = warning;

alter table public.profiles
  add column if not exists course text not null default '',
  add column if not exists graduation_year smallint,
  add column if not exists bio text not null default '',
  add column if not exists onboarding_completed_at timestamptz;

alter table public.campus_memberships
  add column if not exists verification_method text;

create unique index if not exists campus_email_domains_one_active_campus
on public.campus_email_domains(domain)
where is_active;

do $constraints$
begin
  if not exists (
    select 1
    from pg_catalog.pg_constraint
    where conrelid = 'public.profiles'::regclass
      and conname = 'profiles_course_length'
  ) then
    alter table public.profiles
      add constraint profiles_course_length check (
        course = ''
        or (
          course = btrim(course)
          and char_length(course) between 2 and 100
          and course !~ '[[:cntrl:]]'
        )
      );
  end if;

  if not exists (
    select 1
    from pg_catalog.pg_constraint
    where conrelid = 'public.profiles'::regclass
      and conname = 'profiles_graduation_year_range'
  ) then
    alter table public.profiles
      add constraint profiles_graduation_year_range check (
        graduation_year is null
        or graduation_year between 2000 and 2100
      );
  end if;

  if not exists (
    select 1
    from pg_catalog.pg_constraint
    where conrelid = 'public.profiles'::regclass
      and conname = 'profiles_bio_length'
  ) then
    alter table public.profiles
      add constraint profiles_bio_length check (
        char_length(bio) <= 320
        and bio !~ E'[\\x00-\\x08\\x0B\\x0C\\x0E-\\x1F\\x7F]'
      );
  end if;

  if not exists (
    select 1
    from pg_catalog.pg_constraint
    where conrelid = 'public.campus_memberships'::regclass
      and conname = 'campus_memberships_verification_method'
  ) then
    alter table public.campus_memberships
      add constraint campus_memberships_verification_method check (
        verification_method is null
        or verification_method in (
          'college_email',
          'college_id_review',
          'manual_review'
        )
      );
  end if;
end
$constraints$;

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
    new.verification_method := 'college_email';
    new.verified_at := now();
    new.expires_at := now() + interval '1 year';
  else
    new.status := 'pending';
    new.verification_method := coalesce(
      new.verification_method,
      'college_id_review'
    );
    new.verified_at := null;
    new.expires_at := null;
  end if;

  return new;
end;
$$;

create or replace function public.claim_campus_from_verified_email()
returns table (
  id uuid,
  campus_id uuid,
  status public.membership_status,
  verification_method text,
  verified_at timestamptz,
  expires_at timestamptz,
  campus_name text,
  campus_slug text,
  campus_city text
)
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

  select d.campus_id
  into v_campus_id
  from auth.users u
  join public.campus_email_domains d
    on d.domain = lower(pg_catalog.split_part(u.email, '@', 2))
   and d.is_active
  join public.campuses c
    on c.id = d.campus_id
   and c.is_active
  where u.id = v_user_id
    and u.email is not null
    and u.email_confirmed_at is not null
  order by c.name, c.id
  limit 1;

  if v_campus_id is null then
    return;
  end if;

  if not exists (
    select 1
    from public.campus_memberships m
    where m.user_id = v_user_id
      and m.campus_id = v_campus_id
  ) then
    insert into public.campus_memberships(
      user_id,
      campus_id,
      verification_method
    )
    values (v_user_id, v_campus_id, 'college_email')
    on conflict on constraint campus_memberships_user_id_campus_id_key
    do nothing;
  end if;

  update public.profiles p
  set preferred_campus_id = v_campus_id,
      updated_at = now()
  where p.user_id = v_user_id;

  return query
  select
    m.id,
    m.campus_id,
    m.status,
    m.verification_method,
    m.verified_at,
    m.expires_at,
    c.name,
    c.slug,
    c.city
  from public.campus_memberships m
  join public.campuses c on c.id = m.campus_id
  where m.user_id = v_user_id
    and m.campus_id = v_campus_id;
end;
$$;

create or replace function public.request_campus_membership(
  p_campus_id uuid
)
returns table (
  id uuid,
  campus_id uuid,
  status public.membership_status,
  verification_method text,
  verified_at timestamptz,
  expires_at timestamptz
)
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

  if not exists (
    select 1
    from auth.users u
    where u.id = v_user_id
      and u.email_confirmed_at is not null
  ) then
    raise exception using errcode = '42501', message = 'Email confirmation required';
  end if;

  if not exists (
    select 1
    from public.campuses c
    where c.id = p_campus_id
      and c.is_active
  ) then
    raise exception using errcode = '22023', message = 'Campus is unavailable';
  end if;

  if not exists (
    select 1
    from public.campus_memberships m
    where m.user_id = v_user_id
      and m.campus_id = p_campus_id
  ) then
    insert into public.campus_memberships(
      user_id,
      campus_id,
      verification_method
    )
    values (v_user_id, p_campus_id, 'college_id_review')
    on conflict on constraint campus_memberships_user_id_campus_id_key
    do nothing;
  end if;

  return query
  select
    m.id,
    m.campus_id,
    m.status,
    m.verification_method,
    m.verified_at,
    m.expires_at
  from public.campus_memberships m
  where m.user_id = v_user_id
    and m.campus_id = p_campus_id;
end;
$$;

create or replace function private.validate_profile_fields(
  p_display_name text,
  p_course text,
  p_graduation_year integer,
  p_bio text
)
returns void
language plpgsql
stable
set search_path = ''
as $$
begin
  if p_display_name is null
     or btrim(p_display_name) <> p_display_name
     or char_length(p_display_name) not between 2 and 60
     or p_display_name ~ '[[:cntrl:]]' then
    raise exception using errcode = '22023', message = 'Invalid display name';
  end if;

  if p_course is null
     or btrim(p_course) <> p_course
     or char_length(p_course) not between 2 and 100
     or p_course ~ '[[:cntrl:]]' then
    raise exception using errcode = '22023', message = 'Invalid course';
  end if;

  if p_graduation_year is null
     or p_graduation_year < extract(year from current_date)::integer - 8
     or p_graduation_year > extract(year from current_date)::integer + 10 then
    raise exception using errcode = '22023', message = 'Invalid graduation year';
  end if;

  if p_bio is null
     or btrim(p_bio) <> p_bio
     or char_length(p_bio) > 320
     or p_bio ~ E'[\\x00-\\x08\\x0B\\x0C\\x0E-\\x1F\\x7F]' then
    raise exception using errcode = '22023', message = 'Invalid bio';
  end if;
end;
$$;

create or replace function public.complete_my_onboarding(
  p_display_name text,
  p_course text,
  p_graduation_year integer,
  p_bio text
)
returns public.profiles
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_profile public.profiles;
begin
  if v_user_id is null then
    raise exception using errcode = '42501', message = 'Authentication required';
  end if;

  if not exists (
    select 1
    from auth.users u
    where u.id = v_user_id
      and u.email_confirmed_at is not null
  ) then
    raise exception using errcode = '42501', message = 'Email confirmation required';
  end if;

  perform private.validate_profile_fields(
    p_display_name,
    p_course,
    p_graduation_year,
    p_bio
  );

  if not exists (
    select 1
    from public.campus_memberships m
    where m.user_id = v_user_id
      and m.status in ('pending', 'verified')
  ) then
    raise exception using
      errcode = '42501',
      message = 'A campus membership is required';
  end if;

  update public.profiles p
  set display_name = p_display_name,
      course = p_course,
      graduation_year = p_graduation_year,
      bio = p_bio,
      onboarding_completed_at = coalesce(p.onboarding_completed_at, now()),
      preferred_campus_id = coalesce(
        p.preferred_campus_id,
        (
          select m.campus_id
          from public.campus_memberships m
          where m.user_id = v_user_id
            and m.status = 'verified'
          order by m.verified_at desc nulls last, m.created_at
          limit 1
        )
      ),
      updated_at = now()
  where p.user_id = v_user_id
  returning p.* into v_profile;

  if not found then
    raise exception using errcode = 'P0002', message = 'Profile not found';
  end if;

  return v_profile;
end;
$$;

create or replace function public.save_my_profile(
  p_display_name text,
  p_course text,
  p_graduation_year integer,
  p_bio text
)
returns public.profiles
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_profile public.profiles;
begin
  if v_user_id is null then
    raise exception using errcode = '42501', message = 'Authentication required';
  end if;

  perform private.validate_profile_fields(
    p_display_name,
    p_course,
    p_graduation_year,
    p_bio
  );

  update public.profiles p
  set display_name = p_display_name,
      course = p_course,
      graduation_year = p_graduation_year,
      bio = p_bio,
      updated_at = now()
  where p.user_id = v_user_id
    and p.onboarding_completed_at is not null
  returning p.* into v_profile;

  if not found then
    raise exception using errcode = '42501', message = 'Complete onboarding first';
  end if;

  return v_profile;
end;
$$;

revoke all on function public.claim_campus_from_verified_email()
from public, anon, authenticated;
revoke all on function public.request_campus_membership(uuid)
from public, anon, authenticated;
revoke all on function public.complete_my_onboarding(text, text, integer, text)
from public, anon, authenticated;
revoke all on function public.save_my_profile(text, text, integer, text)
from public, anon, authenticated;

grant execute on function public.claim_campus_from_verified_email()
to authenticated, service_role;
grant execute on function public.request_campus_membership(uuid)
to authenticated, service_role;
grant execute on function public.complete_my_onboarding(text, text, integer, text)
to authenticated, service_role;
grant execute on function public.save_my_profile(text, text, integer, text)
to authenticated, service_role;

revoke insert on public.campus_memberships from authenticated;

revoke select (user_id, display_name, avatar_path)
on public.profiles from anon;
revoke select on public.listings from anon;
revoke select on public.listing_images from anon;
revoke select on public.services from anon;
revoke select on public.service_availability from anon;
revoke select on public.reviews from anon;

alter policy profiles_marketplace_read
on public.profiles to authenticated;
alter policy profiles_published_review_read
on public.profiles to authenticated;
alter policy listings_public_active_read
on public.listings to authenticated;
alter policy listing_images_public_ready_read
on public.listing_images to authenticated;
alter policy services_public_active_read
on public.services to authenticated;
alter policy service_availability_visible_with_service
on public.service_availability to authenticated;
alter policy reviews_public_published_read
on public.reviews to authenticated;

commit;
