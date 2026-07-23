# Supabase and Vercel deployment

Last reviewed: 2026-07-23

This guide prepares Venturr for Vercel hosting with Supabase Auth, Postgres,
Realtime, and Storage. It does not authorize a production launch by itself.

## 1. Separate environments

Create distinct Supabase projects for:

1. Local/development
2. Vercel Preview/staging
3. Vercel Production

Preview deployments must never read or write production data. Use separate
publishable keys and project URLs in each Vercel environment scope.

## 2. Configure Supabase locally

Install Docker Desktop and the Supabase CLI, then run:

```bash
npx supabase start
npx supabase db reset
npx supabase db lint
npx supabase test db supabase/tests/database
```

The local frontend callback is `http://127.0.0.1:5173/auth/callback`.
`supabase/seed.sql` is intentionally empty. Files under `supabase/demo/` are
local-only utilities and must never be applied to Preview or Production.

Generate types only after the migrations and tests pass:

```bash
npx supabase gen types typescript --local > src/lib/database.types.ts
```

Generated types are reviewed source; do not hand-edit them.

## 3. Apply a remote environment

Link one environment explicitly and inspect the change before applying it:

```bash
npx supabase link --project-ref PROJECT_REF
npx supabase db diff --linked
npx supabase db push --dry-run
npx supabase db push
```

Run Security Advisor after every schema release. Verify that all exposed tables
have RLS enabled and forced, grants are minimal, private schemas are not exposed,
and no ordinary browser operation requires a secret/service key.

## 4. Configure authentication

- Prefer institution-managed Google/Microsoft OIDC where available.
- Keep email OTP as a controlled fallback.
- Maintain an explicit campus-domain allowlist; not every institution uses `.edu`.
- Enable confirmation, CAPTCHA, custom SMTP, and reviewed Auth rate limits.
- Configure exact callback URLs. Do not allow a broad `*.vercel.app` production wildcard.
- Require AAL2/MFA for moderator and administrator actions.
- Reverify campus membership on an explicit expiry schedule.

Use generic public auth errors so account existence is not disclosed.

## 5. Configure Vercel variables

Set these for Development, Preview, and Production with the correct
environment-specific values:

```text
VITE_SUPABASE_URL
VITE_SUPABASE_PUBLISHABLE_KEY
```

Only add server-side variables when a narrowly scoped server or Edge Function
requires them:

```text
SUPABASE_SECRET_KEY
TURNSTILE_SECRET_KEY
```

Never prefix a secret with `VITE_`. Mark secrets as Vercel Sensitive
Environment Variables and never expose them to preview logs or client bundles.

## 6. Pin the CSP to the project

The committed CSP is a secure offline/default policy with `connect-src 'self'`.
Before enabling live Supabase requests, replace the relevant portions of the
`Content-Security-Policy` value in `vercel.json` with the exact project origin:

```text
img-src 'self' data: blob: https://PROJECT_REF.supabase.co;
connect-src 'self' https://PROJECT_REF.supabase.co wss://PROJECT_REF.supabase.co;
```

Do not use `*.supabase.co`. Add third-party origins only for integrations that
are actually enabled and reviewed.

If Turnstile is enabled, add its exact documented script, connection, and frame
origins. Test CSP in Preview before production.

## 7. Verify the build

The repository pins Node.js `22.x`, which is used locally and selected by
Vercel from `package.json`. Keep the lockfile committed and do not replace
`npm ci` with a floating install command in deployment settings.

```bash
npm ci
npm run typecheck
npm run test
npm run build
npm audit --omit=dev --audit-level=high
npm audit signatures
```

Verify that:

- `dist/client/index.html` exists
- JavaScript and CSS source maps are absent
- Marketplace deep links refresh successfully
- `/services` refreshes to the Services route
- CSP and security headers appear on HTML responses
- `index.html` revalidates and hashed `/assets/*` files cache immutably

## 8. Create the Vercel project

Import the repository into Vercel. `vercel.json` supplies:

- Framework: Vite
- Install: `npm ci`
- Build: `npm run build`
- Output: `dist/client`
- SPA filesystem-aware fallback
- Baseline security headers and caching

Protect Preview deployments with Vercel Authentication. Confirm that the
Production domain, Supabase Auth redirect allowlist, and CSP all use the same
approved hostname.

## 9. Preview release gate

- Database migrations and generated types match Preview
- Cross-user, cross-campus, participant, owner, and moderator RLS tests pass
- Auth confirmation, expiry, redirect, and abuse limits are tested
- Uploads are private and the trusted decode/re-encode pipeline is running
- Reports, blocks, suspension, and moderator audit records are operational
- Mobile light/dark UX and keyboard/focus flows pass
- Logs redact tokens, email, message bodies, reports, and signed URLs

## 10. Production release gate

- Legal owners approve privacy, terms, eligibility, prohibited items, and retention
- Real campus operators and moderator escalation owners are named
- Backups and a restore rehearsal are complete
- WAF/rate-limit rules have been observed in log mode before enforcement
- Spending, Auth, Storage, database, and error alerts are configured
- Exact-domain HTTPS is confirmed before considering HSTS preload
- Two unprivileged real test accounts complete browse, offer, chat, report,
  block, and account-deletion smoke tests

Record the Vercel deployment ID, Git commit, Supabase migration version, and
test evidence for each production release.
