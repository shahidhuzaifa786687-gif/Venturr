# Venturr agent instructions

## Goal and product boundary

Venturr is a campus-local student exchange. Preserve the core flow:

`discover → save/offer → in-app chat → public campus handoff → confirm/review`

Do not reintroduce a retail cart, quantities, multi-seller checkout, public
contact details, or fake orders. Marketplace items support sale, rental, free,
and wanted states.

Marketplace and Services are separate top-level domains:

- `MarketplacePage` renders item listings only.
- `ServicesPage` renders service offers only.
- Never place a “Student services” feed or service cards inside Marketplace.
- Shared identity is allowed; item and service transaction logic is not shared.

Student services may coach, explain, review, debug, collaborate, or provide
practical help. They may not impersonate a student, sit an assessment, or
complete/submit graded work for someone.

## Design direction

The approved reference is `docs/design/venturr-final-direction.png`, amended by
the rule that its lower service section belongs only on `/services`.

Maintain a clean, modern industrial system:

- Off-white/light and near-black/dark surfaces
- Strong condensed Archivo headings and readable Inter body copy
- Blue interaction accent, orange create action, restrained olive/green trust cues
- Thin borders, small-to-medium radii, structured grids, and limited shadows
- Real imagery and Phosphor icons; no emoji, CSS illustrations, or placeholder art
- Low clutter, clear grouping, and one dominant action per area
- Full light/dark parity and WCAG 2.2 AA-minded focus/contrast behavior

Keep responsive behavior tested at 390px mobile and 1440px desktop. Mobile
keeps Marketplace and Services in the bottom navigation and uses an
item/service-aware post flow.

## Code and data rules

- Build application UI in `src/`.
- Use TypeScript strict mode and Zod at user-input boundaries.
- Render user content as React text. Do not use `dangerouslySetInnerHTML`.
- Do not construct HTML strings from user data.
- Do not expose personal email, phone, dorm room, home address, or live location.
- Use coarse configured campus pickup zones.
- Never accept a Supabase secret/service-role key in browser code or a `VITE_` variable.
- Treat RLS, grants, constraints, and narrow RPCs as the authorization boundary.
- Owner, campus, lifecycle, price, moderation, and verification fields are server-derived.
- Store money as integer minor units when live data is connected.
- User uploads remain private until a trusted decoder validates and re-encodes them.
- Do not claim a production image processor exists until it is implemented.

The browser bundle contains no preview people, campuses, listings, services,
conversations, ratings, or asset fixtures. Keep production routes empty until
records come from the authorized Supabase data layer. Demo SQL belongs only in
`supabase/demo/`, must use the manifest, and must never run automatically.

## Required checks

Before handoff:

```bash
npm run typecheck
npm run test
npm run build
npm audit --omit=dev --audit-level=high
```

When Docker/Supabase CLI are available:

```bash
npx supabase db reset
npx supabase db lint
npx supabase test db supabase/tests/database
```

Add a regression test for each security, route-separation, lifecycle, or policy
bug. Cross-user and denied cases matter as much as successful cases.

## Documentation discipline

Update the corresponding document when behavior changes:

- Product rationale and external evidence: `docs/PRODUCT_RESEARCH.md`
- Architecture or route/data ownership: `docs/ARCHITECTURE.md`
- Security, privacy, abuse, or retention: `docs/SECURITY.md`
- Deployment or environment procedure: `docs/DEPLOYMENT.md`
- Visual/responsive verification: `design-qa.md`

Keep `README.md` honest about preview versus production readiness.

## Repository hygiene

The unsafe pre-React prototype and the unused bundled-hosting adapter were
removed after their findings were preserved in `docs/LEGACY_AUDIT.md`. Recover
historical source from Git when needed; do not reintroduce its localStorage
authentication, `innerHTML` rendering, fake checkout, or unsafe escaping.

Do not commit generated output, dependency directories, environment files,
temporary screenshots, deployment state, or editor-specific configuration.
Vercel is the supported frontend deployment target.

Run the local server and open the verified preview yourself when the available
environment supports it.
