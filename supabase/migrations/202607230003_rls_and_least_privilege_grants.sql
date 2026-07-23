begin;

set local client_min_messages = warning;

alter table public.campuses enable row level security;
alter table public.campuses force row level security;
alter table public.campus_email_domains enable row level security;
alter table public.campus_email_domains force row level security;
alter table public.campus_categories enable row level security;
alter table public.campus_categories force row level security;
alter table public.campus_pickup_zones enable row level security;
alter table public.campus_pickup_zones force row level security;
alter table public.profiles enable row level security;
alter table public.profiles force row level security;
alter table public.campus_memberships enable row level security;
alter table public.campus_memberships force row level security;
alter table public.listings enable row level security;
alter table public.listings force row level security;
alter table public.listing_images enable row level security;
alter table public.listing_images force row level security;
alter table public.listing_image_uploads enable row level security;
alter table public.listing_image_uploads force row level security;
alter table public.services enable row level security;
alter table public.services force row level security;
alter table public.service_availability enable row level security;
alter table public.service_availability force row level security;
alter table public.favorites enable row level security;
alter table public.favorites force row level security;
alter table public.conversations enable row level security;
alter table public.conversations force row level security;
alter table public.messages enable row level security;
alter table public.messages force row level security;
alter table public.offers enable row level security;
alter table public.offers force row level security;
alter table public.service_requests enable row level security;
alter table public.service_requests force row level security;
alter table public.bookings enable row level security;
alter table public.bookings force row level security;
alter table public.reviews enable row level security;
alter table public.reviews force row level security;
alter table public.blocks enable row level security;
alter table public.blocks force row level security;
alter table public.reports enable row level security;
alter table public.reports force row level security;

-- No client role receives implicit privileges.
revoke all on all tables in schema public from anon, authenticated;
revoke all on all sequences in schema public from anon, authenticated;
revoke all on schema public from anon, authenticated;
grant usage on schema public to anon, authenticated;

-- Keep future migrations deny-by-default as well. PostgreSQL otherwise grants
-- EXECUTE on new functions to PUBLIC and may inherit broader environment ACLs.
alter default privileges for role postgres in schema public
  revoke all on tables from public, anon, authenticated;
alter default privileges for role postgres in schema public
  revoke all on sequences from public, anon, authenticated;
alter default privileges for role postgres in schema public
  revoke execute on functions from public, anon, authenticated;
alter default privileges for role postgres in schema private
  revoke all on tables from public, anon, authenticated;
alter default privileges for role postgres in schema private
  revoke all on sequences from public, anon, authenticated;
alter default privileges for role postgres in schema private
  revoke execute on functions from public, anon, authenticated;

-- The server-only Supabase secret maps to service_role. It still needs SQL
-- privileges even though it bypasses RLS. Never expose this role to a client.
grant usage on schema public to service_role;
grant select, insert, update, delete
on all tables in schema public to service_role;
grant usage, select on all sequences in schema public to service_role;

-- Reapply only the policies owned by this migration. The catalog check avoids
-- first-run "does not exist" notices, while the transaction ensures there is
-- never a committed state where a managed policy was dropped but not rebuilt.
do $managed_policies$
declare
  v_policy record;
begin
  for v_policy in
    select *
    from (
      values
        ('public', 'campuses', 'campuses_public_read'),
        ('public', 'campus_email_domains', 'campus_domains_moderator_read'),
        ('public', 'campus_categories', 'campus_categories_active_read'),
        ('public', 'campus_categories', 'campus_categories_moderator_read'),
        ('public', 'campus_pickup_zones', 'campus_pickup_zones_active_read'),
        ('public', 'campus_pickup_zones', 'campus_pickup_zones_moderator_read'),
        ('public', 'profiles', 'profiles_marketplace_read'),
        ('public', 'profiles', 'profiles_owner_update'),
        ('public', 'profiles', 'profiles_published_review_read'),
        ('public', 'profiles', 'profiles_relationship_read'),
        ('public', 'profiles', 'profiles_moderator_read'),
        ('public', 'campus_memberships', 'memberships_owner_read'),
        ('public', 'campus_memberships', 'memberships_moderator_read'),
        ('public', 'campus_memberships', 'memberships_owner_request'),
        ('public', 'listings', 'listings_public_active_read'),
        ('public', 'listings', 'listings_owner_read'),
        ('public', 'listings', 'listings_moderator_read'),
        ('public', 'listings', 'listings_transaction_participant_read'),
        ('public', 'listings', 'listings_verified_owner_insert'),
        ('public', 'listings', 'listings_owner_edit_draft'),
        ('public', 'listing_images', 'listing_images_public_ready_read'),
        ('public', 'listing_images', 'listing_images_owner_read'),
        ('public', 'listing_images', 'listing_images_moderator_read'),
        ('public', 'listing_images', 'listing_images_transaction_participant_read'),
        ('public', 'listing_image_uploads', 'listing_image_uploads_owner_read'),
        ('public', 'services', 'services_public_active_read'),
        ('public', 'services', 'services_owner_read'),
        ('public', 'services', 'services_moderator_read'),
        ('public', 'services', 'services_verified_owner_insert'),
        ('public', 'services', 'services_owner_edit_draft'),
        ('public', 'service_availability', 'service_availability_visible_with_service'),
        ('public', 'service_availability', 'service_availability_provider_insert'),
        ('public', 'service_availability', 'service_availability_provider_update'),
        ('public', 'service_availability', 'service_availability_provider_delete'),
        ('public', 'favorites', 'favorites_owner_all_read'),
        ('public', 'favorites', 'favorites_owner_insert'),
        ('public', 'favorites', 'favorites_owner_delete'),
        ('public', 'conversations', 'conversations_participant_read'),
        ('public', 'conversations', 'conversations_moderator_reported_read'),
        ('public', 'conversations', 'conversations_verified_initiator_insert'),
        ('public', 'messages', 'messages_participant_read'),
        ('public', 'messages', 'messages_moderator_reported_read'),
        ('public', 'messages', 'messages_participant_send'),
        ('public', 'offers', 'offers_participant_read'),
        ('public', 'offers', 'offers_moderator_reported_booking_read'),
        ('public', 'offers', 'offers_verified_buyer_insert'),
        ('public', 'service_requests', 'service_requests_participant_read'),
        ('public', 'service_requests', 'service_requests_moderator_reported_booking_read'),
        ('public', 'service_requests', 'service_requests_verified_requester_insert'),
        ('public', 'bookings', 'bookings_participant_read'),
        ('public', 'bookings', 'bookings_moderator_reported_read'),
        ('public', 'reviews', 'reviews_public_published_read'),
        ('public', 'reviews', 'reviews_owner_read'),
        ('public', 'reviews', 'reviews_moderator_reported_read'),
        ('public', 'reviews', 'reviews_completed_participant_insert'),
        ('public', 'blocks', 'blocks_owner_read'),
        ('public', 'blocks', 'blocks_owner_insert'),
        ('public', 'blocks', 'blocks_owner_delete'),
        ('public', 'reports', 'reports_owner_read'),
        ('public', 'reports', 'reports_moderator_read'),
        ('public', 'reports', 'reports_verified_user_insert')
    ) as managed(schema_name, table_name, policy_name)
  loop
    if exists (
      select 1
      from pg_policies
      where schemaname = v_policy.schema_name
        and tablename = v_policy.table_name
        and policyname = v_policy.policy_name
    ) then
      execute format(
        'drop policy %I on %I.%I',
        v_policy.policy_name,
        v_policy.schema_name,
        v_policy.table_name
      );
    end if;
  end loop;
end
$managed_policies$;

create policy campuses_public_read
on public.campuses
for select
to anon, authenticated
using (is_active);

create policy campus_domains_moderator_read
on public.campus_email_domains
for select
to authenticated
using (private.is_moderator((select auth.uid()), campus_id));

create policy campus_categories_active_read
on public.campus_categories
for select
to anon, authenticated
using (is_active);

create policy campus_categories_moderator_read
on public.campus_categories
for select
to authenticated
using (private.is_moderator((select auth.uid()), campus_id));

create policy campus_pickup_zones_active_read
on public.campus_pickup_zones
for select
to anon, authenticated
using (is_active);

create policy campus_pickup_zones_moderator_read
on public.campus_pickup_zones
for select
to authenticated
using (private.is_moderator((select auth.uid()), campus_id));

create policy profiles_marketplace_read
on public.profiles
for select
to anon, authenticated
using (
  user_id = (select auth.uid())
  or exists (
    select 1
    from public.listings l
    where l.seller_id = profiles.user_id
      and l.status = 'active'
      and l.deleted_at is null
      and (l.expires_at is null or l.expires_at > now())
  )
  or exists (
    select 1
    from public.services s
    where s.provider_id = profiles.user_id
      and s.status = 'active'
      and s.deleted_at is null
      and (s.expires_at is null or s.expires_at > now())
  )
);

create policy profiles_owner_update
on public.profiles
for update
to authenticated
using (user_id = (select auth.uid()))
with check (
  user_id = (select auth.uid())
  and (
    preferred_campus_id is null
    or private.is_current_user_verified(preferred_campus_id)
  )
);

create policy profiles_published_review_read
on public.profiles
for select
to anon, authenticated
using (
  exists (
    select 1
    from public.reviews r
    where r.status = 'published'
      and profiles.user_id in (r.reviewer_id, r.reviewee_id)
  )
);

create policy profiles_relationship_read
on public.profiles
for select
to authenticated
using (
  exists (
    select 1
    from public.conversations c
    where (select auth.uid()) in (c.initiator_id, c.recipient_id)
      and profiles.user_id in (c.initiator_id, c.recipient_id)
  )
  or exists (
    select 1
    from public.offers o
    where (select auth.uid()) in (o.proposer_id, o.recipient_id)
      and profiles.user_id in (o.proposer_id, o.recipient_id)
  )
  or exists (
    select 1
    from public.service_requests r
    where (select auth.uid()) in (r.requester_id, r.provider_id)
      and profiles.user_id in (r.requester_id, r.provider_id)
  )
  or exists (
    select 1
    from public.bookings b
    where (select auth.uid()) in (b.customer_id, b.provider_id)
      and profiles.user_id in (b.customer_id, b.provider_id)
  )
);

create policy profiles_moderator_read
on public.profiles
for select
to authenticated
using (
  exists (
    select 1
    from public.campus_memberships m
    where m.user_id = profiles.user_id
      and private.is_moderator((select auth.uid()), m.campus_id)
  )
);

create policy memberships_owner_read
on public.campus_memberships
for select
to authenticated
using (user_id = (select auth.uid()));

create policy memberships_moderator_read
on public.campus_memberships
for select
to authenticated
using (private.is_moderator((select auth.uid()), campus_id));

create policy memberships_owner_request
on public.campus_memberships
for insert
to authenticated
with check (
  user_id = (select auth.uid())
  and role = 'student'
  and (
    (
      status = 'pending'
      and verified_at is null
      and expires_at is null
    )
    or (
      status = 'verified'
      and verified_at is not null
      and expires_at is not null
      and private.email_qualifies_for_campus((select auth.uid()), campus_id)
    )
  )
  and exists (
    select 1
    from public.campuses c
    where c.id = campus_id
      and c.is_active
  )
);

create policy listings_public_active_read
on public.listings
for select
to anon, authenticated
using (
  private.is_listing_actionable(id)
);

create policy listings_owner_read
on public.listings
for select
to authenticated
using (seller_id = (select auth.uid()));

create policy listings_moderator_read
on public.listings
for select
to authenticated
using (private.is_moderator((select auth.uid()), campus_id));

create policy listings_transaction_participant_read
on public.listings
for select
to authenticated
using (
  private.is_current_user_listing_transaction_participant(id)
);

create policy listings_verified_owner_insert
on public.listings
for insert
to authenticated
with check (
  seller_id = (select auth.uid())
  and status = 'draft'
  and published_at is null
  and deleted_at is null
  and private.is_current_user_verified(campus_id)
  and exists (
    select 1
    from public.campus_categories cc
    where cc.campus_id = listings.campus_id
      and cc.name = listings.category
      and cc.is_active
      and cc.scope in ('listing', 'both')
  )
  and (
    pickup_zone is null
    or exists (
      select 1
      from public.campus_pickup_zones z
      where z.campus_id = listings.campus_id
        and z.label = listings.pickup_zone
        and z.is_active
    )
  )
  and exists (
    select 1
    from public.campuses c
    where c.id = campus_id
      and c.is_active
      and c.currency_code = listings.currency_code
  )
);

create policy listings_owner_edit_draft
on public.listings
for update
to authenticated
using (
  seller_id = (select auth.uid())
  and status = 'draft'
)
with check (
  seller_id = (select auth.uid())
  and status = 'draft'
  and published_at is null
  and deleted_at is null
  and private.is_current_user_verified(campus_id)
  and exists (
    select 1
    from public.campus_categories cc
    where cc.campus_id = listings.campus_id
      and cc.name = listings.category
      and cc.is_active
      and cc.scope in ('listing', 'both')
  )
  and (
    pickup_zone is null
    or exists (
      select 1
      from public.campus_pickup_zones z
      where z.campus_id = listings.campus_id
        and z.label = listings.pickup_zone
        and z.is_active
    )
  )
);

create policy listing_images_public_ready_read
on public.listing_images
for select
to anon, authenticated
using (
  processing_status = 'ready'
  and exists (
    select 1
    from public.listings l
    where l.id = listing_images.listing_id
      and l.status = 'active'
      and l.deleted_at is null
      and (l.expires_at is null or l.expires_at > now())
  )
);

create policy listing_images_owner_read
on public.listing_images
for select
to authenticated
using (
  exists (
    select 1
    from public.listings l
    where l.id = listing_images.listing_id
      and l.seller_id = (select auth.uid())
  )
);

create policy listing_images_moderator_read
on public.listing_images
for select
to authenticated
using (
  exists (
    select 1
    from public.listings l
    where l.id = listing_images.listing_id
      and private.is_moderator((select auth.uid()), l.campus_id)
  )
);

create policy listing_images_transaction_participant_read
on public.listing_images
for select
to authenticated
using (
  processing_status = 'ready'
  and private.is_current_user_listing_transaction_participant(listing_id)
);

create policy listing_image_uploads_owner_read
on public.listing_image_uploads
for select
to authenticated
using (uploader_id = (select auth.uid()));

create policy services_public_active_read
on public.services
for select
to anon, authenticated
using (
  private.is_service_actionable(id)
);

create policy services_owner_read
on public.services
for select
to authenticated
using (provider_id = (select auth.uid()));

create policy services_moderator_read
on public.services
for select
to authenticated
using (private.is_moderator((select auth.uid()), campus_id));

create policy services_verified_owner_insert
on public.services
for insert
to authenticated
with check (
  provider_id = (select auth.uid())
  and status = 'draft'
  and published_at is null
  and deleted_at is null
  and private.is_current_user_verified(campus_id)
  and exists (
    select 1
    from public.campus_categories cc
    where cc.campus_id = services.campus_id
      and cc.name = services.category
      and cc.is_active
      and cc.scope in ('service', 'both')
  )
  and (
    pickup_zone is null
    or exists (
      select 1
      from public.campus_pickup_zones z
      where z.campus_id = services.campus_id
        and z.label = services.pickup_zone
        and z.is_active
    )
  )
  and exists (
    select 1
    from public.campuses c
    where c.id = campus_id
      and c.is_active
      and c.currency_code = services.currency_code
  )
);

create policy services_owner_edit_draft
on public.services
for update
to authenticated
using (
  provider_id = (select auth.uid())
  and status = 'draft'
)
with check (
  provider_id = (select auth.uid())
  and status = 'draft'
  and published_at is null
  and deleted_at is null
  and private.is_current_user_verified(campus_id)
  and exists (
    select 1
    from public.campus_categories cc
    where cc.campus_id = services.campus_id
      and cc.name = services.category
      and cc.is_active
      and cc.scope in ('service', 'both')
  )
  and (
    pickup_zone is null
    or exists (
      select 1
      from public.campus_pickup_zones z
      where z.campus_id = services.campus_id
        and z.label = services.pickup_zone
        and z.is_active
    )
  )
);

create policy service_availability_visible_with_service
on public.service_availability
for select
to anon, authenticated
using (
  exists (
    select 1
    from public.services s
    where s.id = service_availability.service_id
  )
);

create policy service_availability_provider_insert
on public.service_availability
for insert
to authenticated
with check (
  exists (
    select 1
    from public.services s
    where s.id = service_availability.service_id
      and s.provider_id = (select auth.uid())
      and s.status = 'draft'
  )
);

create policy service_availability_provider_update
on public.service_availability
for update
to authenticated
using (
  exists (
    select 1
    from public.services s
    where s.id = service_availability.service_id
      and s.provider_id = (select auth.uid())
      and s.status = 'draft'
  )
)
with check (
  exists (
    select 1
    from public.services s
    where s.id = service_availability.service_id
      and s.provider_id = (select auth.uid())
      and s.status = 'draft'
  )
);

create policy service_availability_provider_delete
on public.service_availability
for delete
to authenticated
using (
  exists (
    select 1
    from public.services s
    where s.id = service_availability.service_id
      and s.provider_id = (select auth.uid())
      and s.status = 'draft'
  )
);

create policy favorites_owner_all_read
on public.favorites
for select
to authenticated
using (user_id = (select auth.uid()));

create policy favorites_owner_insert
on public.favorites
for insert
to authenticated
with check (
  user_id = (select auth.uid())
  and (
    (
      listing_id is not null
      and private.is_listing_actionable(listing_id)
    )
    or (
      service_id is not null
      and private.is_service_actionable(service_id)
    )
  )
);

create policy favorites_owner_delete
on public.favorites
for delete
to authenticated
using (user_id = (select auth.uid()));

create policy conversations_participant_read
on public.conversations
for select
to authenticated
using ((select auth.uid()) in (initiator_id, recipient_id));

create policy conversations_moderator_reported_read
on public.conversations
for select
to authenticated
using (
  exists (
    select 1
    from public.messages m
    join public.reports r on r.message_id = m.id
    where m.conversation_id = conversations.id
      and r.status in ('open', 'triaged')
      and private.is_moderator((select auth.uid()), r.campus_id)
  )
);

create policy conversations_verified_initiator_insert
on public.conversations
for insert
to authenticated
with check (
  initiator_id = (select auth.uid())
  and initiator_id <> recipient_id
  and status = 'open'
  and not private.is_current_user_blocked_with(recipient_id)
  and (
    (
      listing_id is not null
      and exists (
        select 1
        from public.listings l
        where l.id = conversations.listing_id
          and l.seller_id = conversations.recipient_id
          and private.is_listing_actionable(l.id)
          and private.is_current_user_verified(l.campus_id)
      )
    )
    or (
      service_id is not null
      and exists (
        select 1
        from public.services s
        where s.id = conversations.service_id
          and s.provider_id = conversations.recipient_id
          and private.is_service_actionable(s.id)
          and private.is_current_user_verified(s.campus_id)
      )
    )
  )
);

create policy messages_participant_read
on public.messages
for select
to authenticated
using (
  private.can_current_user_access_conversation(conversation_id)
);

create policy messages_moderator_reported_read
on public.messages
for select
to authenticated
using (
  exists (
    select 1
    from public.reports r
    where r.message_id = messages.id
      and r.status in ('open', 'triaged')
      and private.is_moderator((select auth.uid()), r.campus_id)
  )
);

create policy messages_participant_send
on public.messages
for insert
to authenticated
with check (
  sender_id = (select auth.uid())
  and kind = 'text'
  and private.can_current_user_access_conversation(conversation_id)
);

create policy offers_participant_read
on public.offers
for select
to authenticated
using ((select auth.uid()) in (proposer_id, recipient_id));

create policy offers_moderator_reported_booking_read
on public.offers
for select
to authenticated
using (
  exists (
    select 1
    from public.bookings b
    join public.reports r on r.booking_id = b.id
    where b.offer_id = offers.id
      and r.status in ('open', 'triaged')
      and private.is_moderator((select auth.uid()), r.campus_id)
  )
);

create policy offers_verified_buyer_insert
on public.offers
for insert
to authenticated
with check (
  proposer_id = (select auth.uid())
  and proposer_id <> recipient_id
  and proposer_id in (buyer_id, seller_id)
  and recipient_id in (buyer_id, seller_id)
  and status = 'pending'
  and not private.is_current_user_blocked_with(recipient_id)
  and exists (
    select 1
    from public.listings l
    where l.id = offers.listing_id
      and l.seller_id = offers.recipient_id
      and l.status = 'active'
      and private.is_current_user_verified(l.campus_id)
      and (
        (
          l.kind = 'sale'
          and offers.kind = 'purchase'
          and offers.buyer_id = offers.proposer_id
          and offers.seller_id = offers.recipient_id
        )
        or (
          l.kind = 'rent'
          and offers.kind = 'rental'
          and offers.buyer_id = offers.proposer_id
          and offers.seller_id = offers.recipient_id
        )
        or (
          l.kind = 'free'
          and offers.kind = 'claim_free'
          and offers.buyer_id = offers.proposer_id
          and offers.seller_id = offers.recipient_id
        )
        or (
          l.kind = 'wanted'
          and offers.kind = 'fulfill_wanted'
          and offers.buyer_id = offers.recipient_id
          and offers.seller_id = offers.proposer_id
        )
      )
  )
);

create policy service_requests_participant_read
on public.service_requests
for select
to authenticated
using ((select auth.uid()) in (requester_id, provider_id));

create policy service_requests_moderator_reported_booking_read
on public.service_requests
for select
to authenticated
using (
  exists (
    select 1
    from public.bookings b
    join public.reports r on r.booking_id = b.id
    where b.service_request_id = service_requests.id
      and r.status in ('open', 'triaged')
      and private.is_moderator((select auth.uid()), r.campus_id)
  )
);

create policy service_requests_verified_requester_insert
on public.service_requests
for insert
to authenticated
with check (
  requester_id = (select auth.uid())
  and requester_id <> provider_id
  and status = 'pending'
  and not private.is_current_user_blocked_with(provider_id)
  and exists (
    select 1
    from public.services s
    where s.id = service_requests.service_id
      and s.provider_id = service_requests.provider_id
      and s.status = 'active'
      and private.is_current_user_verified(s.campus_id)
  )
);

create policy bookings_participant_read
on public.bookings
for select
to authenticated
using ((select auth.uid()) in (customer_id, provider_id));

create policy bookings_moderator_reported_read
on public.bookings
for select
to authenticated
using (
  exists (
    select 1
    from public.reports r
    where r.booking_id = bookings.id
      and r.status in ('open', 'triaged')
      and private.is_moderator((select auth.uid()), r.campus_id)
  )
);

create policy reviews_public_published_read
on public.reviews
for select
to anon, authenticated
using (status = 'published');

create policy reviews_owner_read
on public.reviews
for select
to authenticated
using (reviewer_id = (select auth.uid()));

create policy reviews_moderator_reported_read
on public.reviews
for select
to authenticated
using (
  exists (
    select 1
    from public.reports r
    where r.review_id = reviews.id
      and r.status in ('open', 'triaged')
      and private.is_moderator((select auth.uid()), r.campus_id)
  )
);

create policy reviews_completed_participant_insert
on public.reviews
for insert
to authenticated
with check (
  reviewer_id = (select auth.uid())
  and reviewer_id <> reviewee_id
  and status = 'published'
  and exists (
    select 1
    from public.bookings b
    where b.id = reviews.booking_id
      and b.status = 'completed'
      and (
        (
          b.customer_id = reviews.reviewer_id
          and b.provider_id = reviews.reviewee_id
        )
        or (
          b.provider_id = reviews.reviewer_id
          and b.customer_id = reviews.reviewee_id
        )
      )
  )
);

create policy blocks_owner_read
on public.blocks
for select
to authenticated
using (blocker_id = (select auth.uid()));

create policy blocks_owner_insert
on public.blocks
for insert
to authenticated
with check (
  blocker_id = (select auth.uid())
  and blocker_id <> blocked_id
);

create policy blocks_owner_delete
on public.blocks
for delete
to authenticated
using (blocker_id = (select auth.uid()));

create policy reports_owner_read
on public.reports
for select
to authenticated
using (reporter_id = (select auth.uid()));

create policy reports_moderator_read
on public.reports
for select
to authenticated
using (private.is_moderator((select auth.uid()), campus_id));

create policy reports_verified_user_insert
on public.reports
for insert
to authenticated
with check (
  reporter_id = (select auth.uid())
  and status = 'open'
  and resolved_by is null
  and resolved_at is null
  and private.is_current_user_verified(campus_id)
);

grant select on public.campuses to anon, authenticated;
grant select on public.campus_categories to anon, authenticated;
grant select on public.campus_pickup_zones to anon, authenticated;
grant select (user_id, display_name, avatar_path)
on public.profiles to anon;
grant select on public.profiles to authenticated;
grant select on public.listings to anon, authenticated;
grant select (
  id,
  listing_id,
  position,
  mime_type,
  byte_size,
  width,
  height,
  alt_text,
  created_at
)
on public.listing_images to anon;
grant select on public.listing_images to authenticated;
grant select on public.services to anon, authenticated;
grant select on public.service_availability to anon, authenticated;
grant select (
  id,
  reviewer_id,
  reviewee_id,
  rating,
  body,
  created_at
)
on public.reviews to anon;
grant select on public.reviews to authenticated;

grant select on public.campus_email_domains to authenticated;
grant select on public.campus_memberships to authenticated;
grant select on public.listing_image_uploads to authenticated;
grant select, delete on public.favorites to authenticated;
grant select on public.conversations to authenticated;
grant select on public.messages to authenticated;
grant select on public.offers to authenticated;
grant select on public.service_requests to authenticated;
grant select on public.bookings to authenticated;
grant select, delete on public.blocks to authenticated;
grant select on public.reports to authenticated;

grant update (display_name, avatar_path, preferred_campus_id)
on public.profiles to authenticated;

grant insert (campus_id)
on public.campus_memberships to authenticated;

grant insert (
  campus_id,
  kind,
  title,
  description,
  category,
  condition,
  price_minor,
  price_unit,
  rental_deposit_minor,
  quantity,
  pickup_zone
)
on public.listings to authenticated;

grant update (
  kind,
  title,
  description,
  category,
  condition,
  price_minor,
  price_unit,
  rental_deposit_minor,
  quantity,
  pickup_zone
)
on public.listings to authenticated;

grant insert (
  campus_id,
  title,
  description,
  category,
  mode,
  base_rate_minor,
  billing_unit,
  max_group_size,
  pickup_zone
)
on public.services to authenticated;

grant update (
  title,
  description,
  category,
  mode,
  base_rate_minor,
  billing_unit,
  max_group_size,
  pickup_zone
)
on public.services to authenticated;

grant insert (
  service_id,
  kind,
  weekday,
  start_time,
  end_time,
  starts_at,
  ends_at,
  valid_from,
  valid_until,
  is_active
)
on public.service_availability to authenticated;

grant update (
  kind,
  weekday,
  start_time,
  end_time,
  starts_at,
  ends_at,
  valid_from,
  valid_until,
  is_active
)
on public.service_availability to authenticated;

grant delete on public.service_availability to authenticated;

grant insert (listing_id, service_id)
on public.favorites to authenticated;

grant insert (listing_id, service_id)
on public.conversations to authenticated;

grant insert (conversation_id, body)
on public.messages to authenticated;

grant insert (
  listing_id,
  kind,
  offered_amount_minor,
  rental_starts_at,
  rental_ends_at,
  note
)
on public.offers to authenticated;

grant insert (
  service_id,
  proposed_starts_at,
  proposed_ends_at,
  proposed_amount_minor,
  note
)
on public.service_requests to authenticated;

grant insert (booking_id, rating, body)
on public.reviews to authenticated;

grant insert (blocked_id)
on public.blocks to authenticated;

grant insert (
  listing_id,
  service_id,
  message_id,
  review_id,
  booking_id,
  profile_id,
  reason,
  details
)
on public.reports to authenticated;

commit;
