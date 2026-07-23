# Venturr Supabase backend

This directory is the source of truth for the Venturr database, authorization
policies, Storage buckets, and database policy tests.

## Local setup

Prerequisites:

- Docker Desktop running with the Linux engine
- A current Supabase CLI

From the repository root:

```bash
npx supabase start
npx supabase db reset
npx supabase test db supabase/tests/database
```

`db reset` applies every migration in order and then runs `seed.sql`. The
default seed is intentionally empty, so a reset never creates fictional users
or product content.

## Replaying migrations

The four baseline migration files are transaction-wrapped and safe to replay
in order against a database where they have already completed:

- enum types are created only when absent;
- tables and indexes use guarded creation;
- named constraints are checked through the PostgreSQL catalogs;
- functions are replaced in place;
- triggers and migration-owned RLS policies are replaced atomically; and
- Storage bucket configuration is upserted.

Harmless PostgreSQL `NOTICE` output such as “already exists, skipping” is
suppressed inside the migration transactions. Real `WARNING` and `ERROR`
messages remain visible, and `ON_ERROR_STOP` should stay enabled.

This repeatability is for local recovery, reviewed SQL-editor execution, and
validation. Supabase CLI deployments still use the migration history table.
After a migration version has been deployed, put later schema changes in a new
migration instead of editing the deployed version.

## Optional demo records

The demo fixtures are explicit, isolated utilities:

- `demo/seed_demo_data.sql` creates a `.test` campus, three demo Auth users,
  memberships, listings, services, and availability.
- `demo/drop_demo_data.sql` removes only manifest-tagged demo records.

Copy the local database URL reported by `npx supabase status`, then run:

```powershell
psql $env:LOCAL_DATABASE_URL -v ON_ERROR_STOP=1 -f supabase/demo/seed_demo_data.sql
psql $env:LOCAL_DATABASE_URL -v ON_ERROR_STOP=1 -f supabase/demo/drop_demo_data.sql
```

The seed uses deterministic reserved IDs and refuses to claim conflicting
existing rows. The cleanup script aborts instead of deleting when non-demo
memberships, listings, services, favorites, conversations, offers, requests,
bookings, reviews, blocks, or reports depend on demo records.

The configured local Auth callbacks cover Vite's default port (`5173`) and the
verified local preview port (`4173`) on both `localhost` and `127.0.0.1`.
Update both the local Supabase config and the hosted provider allowlist before
using any other origin.

## Production deployment

1. Create separate Supabase projects for preview/staging and production.
2. Link the intended project explicitly and review the diff:

   ```bash
   npx supabase link --project-ref <project-ref>
   npx supabase db diff --linked
   npx supabase db push --dry-run
   npx supabase db push
   ```

3. Do **not** run anything under `supabase/demo/` against production. Insert
   real campuses, verified email domains, controlled categories, and safe
   public pickup zones through a reviewed admin migration or dashboard session.
4. Bootstrap the first moderator assignment only after the moderator has a real
   Auth user and MFA. Use a one-time SQL change in a reviewed migration:

   ```sql
   insert into private.moderator_assignments(user_id, campus_id, role, granted_by)
   values ('<auth-user-uuid>', '<campus-uuid>', 'admin', '<granting-user-uuid>');
   ```

5. Enable Supabase email confirmations, CAPTCHA, custom SMTP, SSL enforcement,
   Security Advisor, and the backup policy described in `docs/SECURITY.md`.

## Authorization design

- `anon` can read only active marketplace content and public-safe profiles.
- An authenticated user must have an unexpired `verified` campus membership to
  create content or transact at that campus.
- A confirmed Auth email whose exact domain is active for a campus is
  automatically verified for one year. Other requests remain pending for an
  audited moderator decision.
- Listing/service categories and pickup-zone labels must reference active,
  campus-scoped reference rows; free-form exact locations are not accepted.
- Insert triggers derive user ownership and initial workflow state from
  `auth.uid()`; clients are not granted ownership/status columns.
- Active workflow transitions use audited `SECURITY DEFINER` RPCs with a pinned
  empty `search_path`.
- Moderation assignments and audit records live in the unexposed `private`
  schema.
- The Supabase secret/service key is not required for ordinary user CRUD and
  must never appear in browser code.

## Image workflow

Listing images use a two-stage pipeline:

> The database reservation contract and fail-closed Storage policies are
> implemented. The Vercel signed-upload/read routes, media processor, and orphan
> cleanup worker are required launch work and are not implemented in this
> repository yet.

1. The authenticated client calls `reserve_listing_image`. The RPC atomically
   creates a safe public image record plus an immutable owner-only reservation,
   enforces four positions per listing and 20 reservations per account/day,
   and returns a random staging path:
   `<user>/<listing>/<uuid>.<jpg|jpeg|png|webp>`.
2. The client sends the reservation ID to a Vercel Function carrying the
   end-user access token. The function validates the user and reservation, then
   uses the server-only Supabase secret to issue a short-lived signed upload
   token for that exact path. Browser roles have no direct Storage INSERT
   policy.
3. The browser uploads with that one-time/short-lived token. A trusted worker
   validates magic bytes and decoded dimensions,
   rejects decompression bombs, strips EXIF/GPS, re-encodes to WebP, writes a
   random path in private `listing-images`, records it in the owner-only upload
   ledger, and marks the public image row `ready`.
4. The worker deletes the staging object. Reader-facing code receives a
   short-lived signed URL only after checking that the listing is active or the
   caller owns it.

The browser has no direct write policy for staging, processed listing images,
or public avatars. Avatar writes must use the same trusted decode/re-encode
discipline.

Never update or delete rows in `storage.objects` directly. Use the Storage API
so the object and its metadata remain consistent.

## Tests and generated types

`tests/database/rls_policies.test.sql` covers key ownership, workflow, public
read, verification, message IDOR, block, grant, and definer-function
invariants. Add a regression test with every new policy or RPC.

After schema changes:

```bash
npx supabase db lint
npx supabase test db supabase/tests/database
npx supabase gen types typescript --local > src/lib/database.types.ts
```

Review the generated type diff through the normal workflow; do not hand-edit
generated types.
