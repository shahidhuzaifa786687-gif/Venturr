# Venturr

Venturr is a student-first campus exchange for buying, renting, giving away, and
requesting useful items from nearby verified students. It also includes a
separate Services area where students can offer tutoring, coaching, debugging,
creative feedback, and practical help.

This repository is a from-scratch React rebuild of the original browser-only
prototype. The unsafe legacy implementation has been removed from the working
tree; its audit remains in `docs/LEGACY_AUDIT.md` and its source remains
recoverable from Git history.

## Current status

The responsive frontend now starts with a real Supabase authentication entry:

- Public sign-in and account-creation landing page
- Email/password sign-up with confirmation callback support
- A public `/explore` product tour with no student or marketplace data
- Google OAuth wiring behind a disabled `VITE_GOOGLE_AUTH_ENABLED` gate
- Mandatory post-confirmation onboarding with exact college-domain campus matching
- Pending college-ID review requests for email domains that are not recognized
- Owner-only profile editing for display name, course, graduation year, and bio
- Protected marketplace, services, saved, inbox, and profile routes
- Item-only Marketplace with sale, rental, free, and wanted filters
- A distinct Services route and service-posting flow
- Search, category/rate/zone filters, saved items, inbox, profile, and safety pages
- Offer, request, message, and post dialogs
- Light and dark themes
- Desktop, tablet, and mobile navigation
- Academic-integrity boundaries for student services
- Client validation, safe React text rendering, and private-contact UX

No campus, student, listing, service, conversation, rating, or image fixture is
bundled into the browser. Authenticated product routes therefore start empty
until the remaining Supabase catalog read/write modules are connected.

Supabase migrations, RLS policies, Storage policy scaffolding, opt-in demo SQL,
and database policy tests are included.

## Product model

Marketplace and Services are intentionally separate:

| Marketplace | Services |
| --- | --- |
| One-off physical inventory | Repeatable student availability |
| Sale, rental, free, or wanted | Hourly, session, or scoped-project rate |
| Item condition and pickup zone | Scope, format, availability, and integrity |
| Offer, chat, inspect, handoff | Request, chat, session, completion |

The Marketplace must never render service cards. Services that enable
impersonation, assessment-taking, or submission of another student's graded
work are prohibited.

## Technology

- React 19, TypeScript, and Vite
- React Router
- Supabase JS with PKCE-ready browser configuration
- Zod validation
- Phosphor icons
- Self-hosted Archivo and Inter variable fonts
- Vitest and React Testing Library
- Supabase Postgres migrations and pgTAP policy tests
- Vercel-ready SPA configuration

## Run locally

Requirements:

- Node.js 22.x
- npm 10 or newer

```bash
npm ci
npm run dev
```

Open `http://127.0.0.1:5173/`. The authentication landing page renders without
environment variables, but sign-up and sign-in require Supabase configuration.

To prepare for Supabase:

```bash
copy .env.example .env.local
```

For the local Supabase stack, run `npx supabase start`, then copy its `API_URL`
and `PUBLISHABLE_KEY` into:

```text
VITE_SUPABASE_URL=http://127.0.0.1:54321
VITE_SUPABASE_PUBLISHABLE_KEY=<local PUBLISHABLE_KEY>
VITE_GOOGLE_AUTH_ENABLED=false
```

`.env.local` takes precedence over `.env`, which lets local development use
the local Supabase stack without overwriting hosted Preview or production
settings. Restart Vite after changing either environment file.

Local email confirmation is enabled. After creating an account, open the local
development inbox at `http://127.0.0.1:54324`, confirm the address, and then
sign in. Hosted environments must use their configured SMTP provider instead.

Never place a Supabase secret/service-role key, database URL, SMTP credential,
or CAPTCHA secret in a `VITE_` variable. Vite embeds those values in the public
browser bundle.

## Quality commands

```bash
npm run typecheck
npm run test
npm run build
npm audit --omit=dev --audit-level=high
```

`npm run check` runs the typecheck, UI/unit tests, and production build.
`npm run verify` adds a production-dependency vulnerability audit. Both local
development and Vercel install the exact dependency graph from
`package-lock.json` with `npm ci`.

## Supabase

The backend source of truth is in `supabase/`:

- Ordered migrations under `supabase/migrations/`
- Local configuration in `supabase/config.toml`
- A deliberately empty default `supabase/seed.sql`
- Isolated demo utilities under `supabase/demo/`
- Authorization tests in `supabase/tests/database/`

With Docker Desktop and the Supabase CLI available:

```bash
npx supabase start
npx supabase db reset
npx supabase db lint
npx supabase test db supabase/tests/database
```

Use separate Supabase projects for development, Vercel Preview, and production.
RLS and least-privilege grants are the final authorization boundary; the UI is
never an authorization control.

## Vercel

`vercel.json` provides the Vite build, SPA fallback, immutable hashed-asset
caching, CSP, and baseline security headers.

The committed CSP is pinned to the currently configured hosted Supabase
project. If the production project changes, update both exact HTTPS/WebSocket
origins in `vercel.json`; do not use `https://*.supabase.co`.

See `docs/DEPLOYMENT.md` for the complete environment, migration, CSP, Auth,
preview, and production checklist.

## Repository map

```text
src/                  React application, routes, components, state, and tests
supabase/             Database migrations, RLS, Storage policies, and tests
docs/                 Product, architecture, security, research, and QA docs
```

## Documentation

- `docs/PRODUCT_RESEARCH.md` — dated market research and the rationale for added features
- `docs/ARCHITECTURE.md` — product, frontend, data, and deployment architecture
- `docs/SECURITY.md` — threat model, RLS, uploads, privacy, anti-abuse, and launch controls
- `docs/DEPLOYMENT.md` — Supabase and Vercel setup/release procedure
- `docs/CAMPUS_IDENTITY.md` — college-domain and pending student-ID verification setup
- `docs/LEGACY_AUDIT.md` — findings from the original prototype
- `design-qa.md` — implementation/reference comparison and responsive QA result
- `AGENTS.md` — durable implementation rules for future coding agents

## Production limitations

The following are launch gates, not finished production claims:

- Apply `202607240005_account_onboarding.sql` before deploying the matching frontend
- Replace demo campus configuration with reviewed real campuses, college email domains,
  categories, and public pickup zones
- Connect server-backed listing, service, favorite, conversation, and review queries/mutations
- Rerun the passing local database policy suite against the integrated Preview
  project and expand the production role/abuse matrix
- Implement the trusted image decode, metadata-strip, WebP re-encode, and cleanup worker
- Add operational moderation, reports, blocks, retention jobs, and alerting
- Load profiles, listings, services, conversations, and reputation from verified records
- Complete legal review for privacy, eligibility, prohibited items, and payments

Until those gates are complete, this build is a high-fidelity functional
prototype and hardened backend foundation—not a live transactional marketplace.
