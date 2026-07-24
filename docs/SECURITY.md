# Venturr security and privacy guide

Last reviewed: 2026-07-24

This document defines the security baseline for the student-campus marketplace
rebuild. It covers the React/Vite single-page application on Vercel and Supabase
Auth, Postgres, Realtime, and Storage. It is an engineering standard, not a
claim of legal compliance.

## Security stance

Venturr assumes that every browser, request field, uploaded file, URL parameter,
JWT claim writable by a user, and client-visible key is hostile. Controls are
layered:

1. Vercel terminates TLS and provides CDN/WAF controls.
2. The application validates requests, authenticates the user, rate-limits
   abuse, and performs sensitive mutations through narrow server routes/RPCs.
3. Supabase Postgres constraints and row-level security remain the final
   authorization boundary.
4. Privileged data and audit records are not exposed through the Data API.
5. User media is private until a trusted decoder has validated and re-encoded
   it.

The Supabase publishable key is intentionally public. RLS, grants, and policies
must be secure even when an attacker calls the Supabase API without using the
Venturr UI. A Supabase secret/service-role key bypasses RLS and is therefore a
high-impact production credential.

## Implementation review: 2026-07-24

The authentication/account change was reviewed across the browser entry,
Vercel headers, Supabase Auth settings, database grants/RLS, RPCs, local
Storage usage, redirects, validation, and package supply chain.

Resolved:

- The enforced Vercel CSP previously had `connect-src 'self'`, which blocked
  every hosted Supabase Auth and REST request. It is now pinned to the exact
  configured Supabase HTTPS and WebSocket origins and covered by a regression
  test.
- Product records are no longer granted to `anon`; `/explore` contains no
  student, listing, service, review, or conversation data.
- Auth return destinations use an internal allowlist to prevent open redirects.
- Campus membership creation moved behind current-user RPCs, confirmed email is
  required, domain matching stays in the database, and active domains are
  unique to one campus.
- Onboarding completion, verification status, role, owner, campus match,
  verification method, and timestamps are server-derived.
- Saved listing/service IDs are no longer retained in browser `localStorage`
  where they could cross account boundaries on a shared device.
- No raw HTML rendering, browser secret key, tracked credential pattern, or
  high-severity production dependency advisory was found.

Open production gates:

- Apply the onboarding migration before the matching frontend deployment.
- The currently inspected hosted project exposes a demo-named campus. Replace
  all demo campus/domain/catalog rows with reviewed real records before launch.
- Verify exact Supabase Site URL and callback allowlists in the Dashboard;
  those values are not exposed by the public Auth settings endpoint.
- Enable custom SMTP, CAPTCHA, reviewed Auth rate limits, production monitoring,
  and two-account smoke tests.
- College-ID evidence upload remains intentionally unavailable until the
  private verification and short-retention controls in
  `docs/CAMPUS_IDENTITY.md` are implemented.

## Architecture and trust boundaries

```text
Browser
  -> Vercel CDN / WAF
  -> application UI and server routes
       -> Supabase Auth (PKCE session)
       -> Postgres Data API with the end-user JWT
            -> grants + constraints + RLS
       -> signed-upload route (validated reservation + server-only secret)
            -> private Storage staging bucket
       -> trusted media processor (server-only secret)
            -> private processed-image bucket
```

The versioned Vite shell/assets may be cached. Catalog/API data must be cached
only when the response contains no session or private profile data. If a
Vercel Function is later used for auth or user-specific data, its authenticated
responses and callbacks are dynamic and use `Cache-Control: private, no-store`.

Use separate Supabase projects and Vercel environment scopes for local,
preview/staging, and production. A preview build must never point at production
data.

## Assets to protect

- Auth access/refresh tokens and email identities
- Supabase secret keys, SMTP credentials, CAPTCHA secrets, and database
  credentials
- Campus verification and moderator assignments
- Draft/rejected listings and services
- Messages, offers, service requests, bookings, reports, and blocks
- Exact object paths and unprocessed user uploads
- Audit and moderation history
- User safety information, including pickup location and block/report state
- Availability, integrity, and cost controls for email, Storage, Postgres, and
  Vercel Functions

## Threat model

| Threat actor / failure | Likely attack | Primary controls |
| --- | --- | --- |
| Anonymous bot | Scrape catalog, spam auth, exhaust email/function/storage quota | CAPTCHA, Auth limits, Vercel WAF, public-data minimization, spend alerts |
| Authenticated abuser | Spam listings/messages, harassment, prohibited goods, fraudulent reports | Verified membership, database quotas, block/report flows, moderation queue, suspension |
| Malicious seller/buyer | IDOR, forged owner/status/price, double booking, fake completion | RLS, derived ownership triggers, narrow RPCs, row locks, exclusion/unique constraints |
| XSS attacker | Persist HTML/event handlers in listings, profiles, messages, or URLs | React text rendering, no raw HTML, strict CSP, controlled Storage URLs, regression tests |
| Upload attacker | Polyglot/SVG payload, decompression bomb, EXIF location leak, storage exhaustion | MIME allowlist plus magic-byte/decode checks, pixel/byte caps, re-encode, private staging, quotas |
| Credential attacker | OTP abuse, credential stuffing, OAuth redirect abuse, stolen moderator session | Passwordless/OIDC, exact redirects, Turnstile, rate limits, MFA/AAL2 for staff |
| Curious student | Enumerate other users' messages, blocks, drafts, reports, or verification state | Deny-by-default RLS, private schema, participant policies, policy tests |
| Developer/operator error | Leak service key, point preview at prod, deploy permissive policy, cache a session response | Environment separation, sensitive vars, CI tests, migration review, no-store auth responses |
| Supply-chain compromise | Compromised CDN script/package | No remote runtime scripts, lockfile, dependency review/scanning, CSP |
| Platform/account compromise | Supabase/Vercel project takeover | Hardware-backed MFA, least-privilege team roles, audit logs, owner recovery plan |

Campus-specific abuse matters as much as technical exploitation. Product
moderation must explicitly cover scams, stolen goods, weapons/controlled items,
academic cheating, harassment, impersonation, unsafe meetup requests, and
attempts to move users to risky payment channels.

## Current database authorization model

The migrations in `supabase/migrations` implement:

- Public reads only for active, unexpired catalog content and published reviews
- Owner access to private/draft content
- Participant-only conversations, messages, offers, requests, and bookings,
  except that an assigned same-campus moderator with AAL2 may inspect the
  minimum content linked to an open/triaged report
- Verified, unexpired campus membership before content creation or transactions
- Confirmed exact-domain auto-verification, with other requests left pending
  for an audited decision
- Active campus-scoped category and public pickup-zone references
- Server-derived ownership and initial status on inserts
- No direct client privilege to update workflow status, create bookings, or
  change verification/moderation fields
- Private moderator assignments and append-only audit/moderation records
- AAL2 enforced inside moderator authorization, not only in the UI
- Audited `SECURITY DEFINER` RPCs with `search_path = ''`
- Database quotas that remain effective when callers bypass the web UI
- Immutable, owner-only upload reservations separated from public image fields
- Blocking checks in message, offer, request, and conversation flows

Never add a table to an exposed schema without all of:

1. Explicit grants
2. RLS enabled and forced
3. Policies for each required operation
4. Ownership/tenant constraints
5. Cross-user negative tests

Do not use UUID unpredictability as access control. Do not use
`raw_user_meta_data` for campus, verification, staff role, or any authorization
decision; users can modify it. Store authority in protected tables or
server-written app metadata. A protected table is preferred where suspension
must take effect immediately instead of waiting for JWT refresh.

Deactivating a category or pickup zone immediately removes dependent content
from public/actionable policies. Submission and moderation recheck those
references so a stale draft cannot be approved.

`SECURITY DEFINER` functions are exceptional. Every such function must:

- Pin an empty search path and schema-qualify every object
- Read the actor from `auth.uid()`, never from a caller-supplied owner ID
- Lock rows involved in a state transition
- Verify current state as well as ownership/role
- Avoid dynamic SQL, or strictly allowlist identifiers if unavoidable
- Have default `PUBLIC` execution revoked
- Grant execution only to the minimum role
- Write an audit/moderation event for privileged decisions
- Have success, cross-user, replay, and invalid-transition tests

The service-role key is not a substitute for RLS. Ordinary user operations
should use a Supabase server/browser client carrying that user's session.

## Authentication and campus verification

- Use `@supabase/supabase-js` with PKCE for the Vite browser application. If the
  application later adopts SSR, use the current `@supabase/ssr` guidance.
- Browser session state is for UI only; Postgres RLS authorizes database
  operations. A Vercel Function handling privileged work must validate the
  access token/claims and must not trust caller-supplied user IDs or the
  user object from an unvalidated `getSession()` result.
- Prefer university-managed OIDC/Google Workspace or email OTP. Do not assume
  that every real university ends in `.edu`; maintain an explicit
  campus-domain allowlist.
- A confirmed Auth email with an exact active domain match is currently
  auto-verified for one year. A nonmatching domain creates only a pending
  membership; it never falls back to self-asserted verification.
- Exact-domain matching happens inside `claim_campus_from_verified_email()`.
  The active domain allowlist is not readable by an ordinary student.
- Pending college-ID review uses a derived membership request RPC. The current
  browser does not upload or retain an ID image; adding evidence collection
  requires a private bucket or reviewed verification provider, decoder checks,
  reviewer access controls, audit records, and short retention.
- Validate the provider's verified email/domain server-side. OAuth hints such
  as `hd` improve UX but are not authorization.
- Enable email confirmation, custom SMTP, and Cloudflare Turnstile or hCaptcha.
- Keep OTP validity short (the local baseline is 10 minutes) and configure
  Supabase Auth rate limits before launch.
- Return generic auth errors so the UI does not reveal whether an email has an
  account.
- Allow only exact production callback/redirect URLs. Do not add a broad
  `https://*.vercel.app/**` wildcard to production Auth.
- Require moderator/admin MFA and assurance level 2 for staff operations.
- Reverify campus membership periodically. The schema defaults moderator
  verification to one year.
- The SPA's session storage is reachable by JavaScript, so preventing XSS is a
  session-security requirement. If a future server layer uses cookies, follow
  current Supabase guidance and use production `Secure`/appropriate `SameSite`
  settings.

Email domain ownership proves mailbox control, not necessarily current
enrollment. If manual student-ID review is introduced, put evidence in a
separate private bucket, restrict access to trained reviewers, and delete it
soon after the decision. Do not retain identity documents “just in case.”

## Environment variables and secrets

Expected public variables:

```text
VITE_SUPABASE_URL
VITE_SUPABASE_PUBLISHABLE_KEY
VITE_GOOGLE_AUTH_ENABLED       # public rollout flag, normally false
```

Expected server-only variables, only when a route truly needs them:

```text
SUPABASE_SECRET_KEY
TURNSTILE_SECRET_KEY
SMTP_*                     # normally configured in Supabase, not the app
DATABASE_URL               # only for approved server/CI database work
```

Rules:

- A secret must never use `VITE_`, `NEXT_PUBLIC_`, or another client-exposing
  prefix.
- Mark production and preview secrets as Vercel Sensitive Environment
  Variables. Scope each value to the environment that needs it.
- Keep `.env.local`, Supabase temp files, Vercel project metadata, dumps, and
  generated credentials out of Git. Commit only an `.env.example` containing
  placeholders.
- Import service credentials only from a `server-only` module. Never pass them
  through props, serialized errors, logs, analytics, or source maps.
- Prefer the Supabase HTTPS client to a direct database connection. If direct
  Postgres is required, use the correct pooler, SSL, short timeouts, and least
  privilege.
- Rotate secrets immediately after suspected disclosure and after staff access
  changes. Environment changes require a new Vercel deployment.
- Secret scanning must cover the current tree and Git history.

Production, preview, and development keys must come from different Supabase
projects. Protect preview deployments with Vercel Authentication.

## Input handling and browser security

Validate at three layers:

1. Client validation for usable feedback
2. Server action/route validation for trust
3. Postgres types, checks, FKs, unique/exclusion constraints, triggers, and RLS

Use a shared schema library such as Zod, but do not mistake it for database
authorization.

### XSS

- Render titles, descriptions, display names, messages, pickup zones, and
  report content as text.
- Do not use `dangerouslySetInnerHTML`, template-string HTML, or an HTML
  sanitizer unless rich text becomes an explicitly reviewed feature.
- Never accept an arbitrary image URL. Store object paths and derive URLs from a
  fixed Supabase origin.
- Restrict framework remote-image patterns to the exact Supabase project and
  expected bucket path.
- Self-host fonts and install/pin runtime libraries. Do not execute CDN scripts.
- Add regression cases containing tags, quotes, event handlers, `javascript:`,
  SVG payloads, bidi controls, and very long Unicode input.

The legacy prototype's `escapeHTML` did not escape angle brackets or quotes and
then inserted listings through `innerHTML`. No code from that rendering path
should survive the rebuild.

### CSRF, redirects, and SSRF

- Use POST/PUT/PATCH/DELETE for mutations; GET is read-only.
- The current bearer-token Data API flow is not cookie-CSRF based. Any future
  cookie-backed Vercel Function must verify same-origin requests and use an
  anti-CSRF mechanism.
- Accept post-login `next` values only as relative, allowlisted application
  paths.
- Never fetch a user-provided URL from a server or image optimizer. Use exact
  remote-host/path allowlists.
- Do not enable permissive CORS. CORS is not authorization; RLS still applies.

### Money and state

- Money is stored as integer minor units plus an ISO currency code.
- The accepted price, seller/provider, campus, and item/service state come from
  Postgres, never the cart or form.
- Offer acceptance and booking creation occur in one locked transaction.
- Provider time overlap is blocked for service appointments by an exclusion
  constraint. Item offers reserve one listing atomically instead of blocking
  every unrelated activity of the listing owner.
- If payments are added, use a hosted PCI-scoped provider and verified
  webhooks. Do not store card details. Verify webhook signatures, amount,
  currency, event uniqueness, and object ownership server-side.

## Upload security

Listing uploads use:

- Maximum four image records per listing
- Maximum 20 immutable upload reservations per account in 24 hours
- Maximum 5 MiB per staging object
- JPEG, PNG, or WebP staging MIME allowlist
- Private staging and processed buckets
- Random paths, never original file names
- A separate private processed WebP bucket
- Short-lived signed read URLs after listing/owner authorization
- No browser-role Storage INSERT policy

The browser first calls `reserve_listing_image`. That audited RPC requires an
owned draft listing and verified campus membership, locks the listing, enforces
the daily reservation ledger, and returns a random staging path. A Vercel
Function must validate the caller's access token and owner-only reservation,
then use the server-only secret to issue a short-lived signed upload token for
that exact path. Never accept an arbitrary caller-supplied object path in that
route.

**Required before image uploads are enabled:** the Vercel signed-upload/read
routes, trusted decoder/processor, and orphan cleanup worker described here are
an implementation contract; they are not present in this repository yet. The
database intentionally gives browser roles no Storage INSERT policy, so uploads
remain fail-closed until those server components exist and pass the launch
tests.

The trusted processor must:

1. Download from the expected private staging path.
2. Check actual magic bytes independently of extension and `Content-Type`.
3. Decode with resource limits and reject invalid/truncated files,
   decompression bombs, extreme dimensions, animation, SVG, and embedded HTML.
4. Normalize orientation and color handling.
5. Strip EXIF, XMP, ICC data not explicitly required, thumbnails, GPS, and file
   names.
6. Resize to the product maximum, re-encode as WebP, compute a SHA-256 digest,
   and upload with a safe fixed content type.
7. Record the processed object path only in the owner-scoped
   `listing_image_uploads` row, then mark
   `listing_images.processing_status = 'ready'` only after the object is
   durable.
8. Delete staging on success and rejected/orphaned objects on a short schedule.

Do not update/delete `storage.objects` with SQL; use the Storage API. Processed
bucket writes and avatar writes require the server-only secret. The browser has
no corresponding write policy.

Signed URLs are bearer URLs. Keep their lifetime short, do not log them, and do
not place them in public analytics events.

## CSP and response headers

Deploy CSP in `Content-Security-Policy-Report-Only` first, fix violations, then
enforce it. The static Vite production build should need no inline-script
exception:

```text
default-src 'self';
base-uri 'self';
object-src 'none';
frame-ancestors 'none';
form-action 'self';
script-src 'self';
style-src 'self';
img-src 'self' data: blob: https://PROJECT_REF.supabase.co;
font-src 'self';
connect-src 'self' https://PROJECT_REF.supabase.co wss://PROJECT_REF.supabase.co;
worker-src 'self' blob:;
manifest-src 'self';
upgrade-insecure-requests;
```

Development may need a separate relaxed policy; never ship development
`unsafe-eval` to production. If future server rendering introduces inline
framework scripts, use per-request nonces rather than global `unsafe-inline`.
Add exact `https://challenges.cloudflare.com` directives to `script-src`,
`connect-src`, and `frame-src` only if Turnstile is enabled. Avoid
`*.supabase.co`.

Send these headers on HTML and application responses:

```text
X-Content-Type-Options: nosniff
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: camera=(), microphone=(), geolocation=(), payment=(), usb=(), browsing-topics=()
X-Frame-Options: DENY
Cross-Origin-Opener-Policy: same-origin
```

After confirming every current and future subdomain is HTTPS-only:

```text
Strict-Transport-Security: max-age=63072000; includeSubDomains; preload
```

`frame-ancestors 'none'` is the primary clickjacking control; `X-Frame-Options`
is retained for older clients. Do not enable HSTS preload casually because it
is deliberately difficult to reverse.

## Anti-abuse and moderation

Database-enforced initial ceilings:

| Action | Current database ceiling |
| --- | --- |
| Membership requests | 3 pending/verified memberships |
| Listings | 10 created/day, 25 open |
| Services | 5 created/day, 15 open |
| Conversations | 30 created/day |
| Messages | 20/minute, 300/day |
| Offers | 50/day |
| Service requests | 30/day |
| Reports | 10/day |
| Listing images | 4/listing, 20 reservations/account/day, 5 MiB/object |

These are safety defaults, not product promises. Tune them from reviewed
telemetry. Campus networks place many students behind one NAT, so do not rely
only on IP. Layer:

1. Supabase Auth rate limits and CAPTCHA
2. Vercel WAF IP/JA4 challenge or limits on auth and API routes
3. Atomic account quotas in Postgres
4. Per-recipient/content heuristics and moderator intervention

Start WAF rules in log mode, observe false positives, then challenge/rate-limit.
Add spend alerts so an abuse event cannot become an unbounded platform bill.

Moderators need queues for pending content and reports, clear reason codes,
least-privilege campus scope, MFA, and append-only action records. Users need
easy report/block controls and safe-meetup guidance. Blocking is mutual for new
conversations, messages, offers, and service requests without revealing who
blocked whom.

## Privacy and data minimization

- Keep email in Supabase Auth. Do not copy it into public profiles/listings.
- Do not publish phone numbers, personal email, dorm room, home address, class
  timetable, or live location.
- Use a public display name and predefined campus pickup zones.
- Profiles contain only fields suitable for public marketplace display.
- Reports, block relationships, drafts, rejected content, messages, and
  verification data are private.
- Avoid third-party advertising/tracking SDKs at launch. If nonessential
  analytics are added, minimize identifiers and obtain any required consent.
- Redact `Authorization`, cookies, OTPs, signed URLs, email, message bodies,
  report text, and exact location from logs/error monitoring.
- Do not put personal or secret data in URL paths/query strings.
- Provide user-access export, account deletion, and a clear privacy notice.
- Decide whether under-18 users are allowed before launch and build an
  appropriate policy rather than inferring age from “student.”

Proposed retention defaults, subject to product/legal approval:

| Data | Proposed retention |
| --- | --- |
| Staging uploads | Delete within 1 hour |
| Rejected/orphaned media | Delete within 24 hours |
| Removed/expired listing media | Delete after dispute window, e.g. 90 days |
| Messages/bookings | 12 months after last activity |
| Reports/moderation evidence | 18 months |
| Security audit events | 24 months |
| Manual identity evidence | Delete within 72 hours of decision |

The schema supplies lifecycle timestamps but does not install retention jobs.
Production launch requires scheduled cleanup, observable failures, and a dry-run
mode. Hard deletion must consider fraud/dispute holds and then remove database
and Storage data consistently.

## Logging, monitoring, and backups

Log:

- Request/correlation ID
- Route/action name and outcome
- Coarse latency/status
- Opaque user UUID only where needed
- RLS/RPC authorization failures as aggregate security signals
- Moderator/security actions

Do not log request bodies for auth, messaging, reports, profile, or uploads.
Protect and retain log drains according to the same access/retention policy as
production data.

Operational controls:

- Enable Supabase Security Advisor and resolve findings before every release.
- Enable database SSL enforcement.
- Apply direct Postgres network restrictions if direct connections are used.
  They do not protect Supabase HTTPS APIs; RLS still does.
- Enable daily backups on the appropriate plan and choose PITR from an explicit
  recovery point objective.
- Test a restore into a separate project; Storage objects/settings require a
  separate recovery plan.
- Enable Vercel Deployment Protection for previews.
- Enable Vercel Firewall visibility/alerts and spend alerts.
- Protect Supabase, Vercel, GitHub, SMTP, and DNS accounts with strong MFA and
  least-privilege roles.
- Keep at least two controlled recovery owners and document break-glass access.

## Secure development lifecycle

Every change must pass:

- Typecheck, lint, unit/integration, and production build
- Dependency lockfile integrity and vulnerability review
- Secret scanning across staged changes and Git history
- `supabase db lint`
- `supabase test db`
- RLS tests as anon, owner, another verified user, unverified user, participant,
  nonparticipant, moderator, and suspended member
- XSS and URL allowlist regression tests
- Upload MIME/magic-byte/decompression tests
- Auth callback/open-redirect and CSRF tests
- Preview security-header/CSP scan

The current pgTAP suite covers the core RLS/grant/AAL2/ownership and marketplace
workflow regression paths. It is not yet the exhaustive matrix above. Expand it
with every RPC's replay, wrong-campus, wrong-party, resolved-report, and
suspended-member cases before production launch.

Treat every Vercel Function, worker endpoint, Supabase RPC, and direct Data API
operation as a public endpoint. Validate input and repeat authorization inside
the data-access layer/RPC.

Do not deploy migrations manually from an unreviewed workstation. Review the
generated SQL diff, apply preview first, run policy tests there, then promote
the exact migration set to production.

## Incident response

Minimum response flow:

1. **Triage:** establish severity, affected environment/data/users, first known
   event, and whether exploitation is ongoing.
2. **Contain:** enable/challenge WAF rules, suspend affected accounts/content,
   revoke sessions, disable the vulnerable route/RPC, or roll back deployment.
3. **Credential response:** rotate any exposed Supabase secret, SMTP, CAPTCHA,
   Vercel/GitHub token, and database credential. Redeploy because Vercel env
   changes do not modify previous deployments.
4. **Preserve evidence:** record timestamps, deployment/migration versions,
   audit IDs, and relevant redacted logs with restricted access.
5. **Eradicate:** patch the root cause and add a test that failed before the fix.
6. **Recover:** deploy through preview, verify RLS/headers/alerts, restore data
   if required, and monitor for recurrence.
7. **Communicate:** follow the approved user, campus, provider, and regulatory
   notification process. Do not speculate publicly.
8. **Learn:** complete a blameless post-incident review with owners and due
   dates.

Maintain an out-of-band list of security owners and provider support links.
Do not keep the only copy of the incident plan inside the affected production
system.

## Launch checklist

### Application

- [ ] No legacy `innerHTML`/raw HTML rendering path remains
- [ ] Shared request schemas validate every mutation
- [ ] Authenticated responses are `private, no-store`
- [ ] CSRF/origin and redirect allowlists are tested
- [ ] CSP is enforced without production `unsafe-eval`
- [ ] Security headers pass an external scan
- [ ] Contact details and exact locations are not public
- [ ] Report, block, suspension, and moderation UX is usable
- [ ] Checkout language does not claim payment/order completion unless true

### Supabase

- [ ] Fresh `supabase db reset`, `db lint`, and policy tests pass
- [ ] Security Advisor has no unexplained findings
- [ ] Every exposed table has RLS and least-privilege grants
- [ ] Service key is absent from all client bundles and source history
- [ ] Real campus domains were added through a controlled process
- [ ] Email confirmation, CAPTCHA, custom SMTP, and Auth limits are configured
- [ ] Moderator accounts have MFA/AAL2 and scoped assignments
- [ ] Storage processor, signed URLs, and orphan cleanup are tested
- [ ] Realtime publishes only intentionally scoped tables
- [ ] SSL, backups, restore drill, and any network restrictions are complete

### Vercel and operations

- [ ] Preview and production use separate Supabase projects
- [ ] Secrets are sensitive, environment-scoped, and server-only
- [ ] Preview Deployment Protection is enabled
- [ ] WAF rules were observed in log mode before enforcement
- [ ] Monitoring/logging redact tokens and personal content
- [ ] Spend, error, abuse, and moderation-backlog alerts are routed
- [ ] Rollback, incident contacts, and credential rotation are rehearsed
- [ ] Privacy/terms/safety/prohibited-items and retention policies are published

## Primary references

- [Supabase Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security)
- [Supabase Storage access control](https://supabase.com/docs/guides/storage/security/access-control)
- [Supabase Storage bucket restrictions](https://supabase.com/docs/guides/storage/buckets/fundamentals)
- [Supabase JavaScript client](https://supabase.com/docs/reference/javascript/introduction)
- [Supabase SSR guidance for a future server-rendered architecture](https://supabase.com/docs/guides/auth/server-side/creating-a-client)
- [Supabase CAPTCHA](https://supabase.com/docs/guides/auth/auth-captcha)
- [Supabase Auth rate limits](https://supabase.com/docs/guides/auth/rate-limits)
- [Supabase production checklist](https://supabase.com/docs/guides/deployment/going-into-prod)
- [Supabase Security Advisor](https://supabase.com/docs/guides/database/database-advisors)
- [Supabase network restrictions](https://supabase.com/docs/guides/platform/network-restrictions)
- [Vercel production checklist](https://vercel.com/docs/production-checklist)
- [Vercel Firewall](https://vercel.com/docs/vercel-firewall)
- [Vercel Deployment Protection](https://vercel.com/docs/deployment-protection)
- [Vercel Sensitive Environment Variables](https://vercel.com/docs/environment-variables/sensitive-environment-variables)
