# Campus identity setup

Last reviewed: 2026-07-24

Venturr supports two campus identity paths:

1. A confirmed college email whose exact domain is configured for an active
   campus is verified automatically for one year.
2. An unmatched student can request a pending college-ID review. The current
   application creates the protected review queue entry but deliberately does
   not collect an ID image in browser code.

## Configure a real campus

Add campuses and domains through a reviewed migration, not browser input or
editable Auth metadata:

```sql
insert into public.campuses(
  slug,
  name,
  city,
  country_code,
  timezone,
  currency_code
)
values (
  'example-university',
  'Example University',
  'Example City',
  'IN',
  'Asia/Kolkata',
  'INR'
)
returning id;

insert into public.campus_email_domains(campus_id, domain)
values (
  '<returned-campus-uuid>',
  'students.example.edu'
);
```

Store the lowercase host only. Do not include `@`, a URL scheme, a wildcard,
or a mailbox. Add each legitimate student domain explicitly. Staff, alumni,
and hospital domains should be separate policy decisions instead of assumed
equivalent to current student status.

Also insert reviewed categories and coarse public pickup zones before enabling
transactions for the campus. Never store dorm rooms, home addresses, or live
location as pickup zones.

## Automatic college-email verification

The frontend requires Supabase email confirmation first. During onboarding it
calls `claim_campus_from_verified_email()`. The database:

1. Reads only `auth.uid()` and that Auth user's confirmed email.
2. Matches the exact lowercased domain inside the database.
3. Creates or returns the user's membership.
4. Marks it `verified` with `verification_method=college_email` when matched.
5. Sets a one-year expiry and the user's preferred campus.

The campus-domain table is not readable by an ordinary student. The browser
cannot supply a campus, user ID, verified status, or expiry to this function.

## College-ID review

When no domain matches, onboarding lets the student choose an active campus
and calls `request_campus_membership()`. The database derives the current user,
student role, pending status, and `college_id_review` method. A student cannot
approve their own request.

The current build stops there. Before collecting identity evidence, implement
all of the following:

- A private, non-public evidence store or a contractually reviewed verification
  provider
- Server-issued, single-purpose upload authorization
- File signature, decoded-dimension, malware, and decompression-bomb checks
- Metadata stripping and a safe derivative used only by trained reviewers
- A separate private record for provider/reference IDs and decision state
- AAL2/MFA for reviewers, campus-scoped authorization, and immutable audit events
- A short documented retention period and deletion job for rejected and
  approved evidence
- A privacy notice, lawful basis/consent analysis, access correction, and
  deletion procedure

Do not add a direct browser Storage insert policy for ID documents. Do not put
ID paths in `profiles`, `campus_memberships`, public logs, analytics, email, or
client-visible error messages.

After a trained reviewer validates evidence, an AAL2 campus moderator can use
the existing audited `moderate_membership` RPC. Test wrong-campus, wrong-user,
replay, expired evidence, rejected request, and AAL1 denial cases before
production rollout.

## Production checks

- Remove all demo campus/domain records from the production project.
- Use two real unprivileged accounts for each launch campus.
- Test matching and nonmatching confirmed domains.
- Confirm an unconfirmed email cannot auto-verify.
- Confirm `anon` cannot read profiles, listings, services, or review data.
- Confirm students cannot insert or update membership status directly.
- Reverify or expire memberships on schedule.
