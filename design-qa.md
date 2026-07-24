# Venturr design QA

Date: 2026-07-24
Final result: **passed**

## Current implementation

The current entry surface is authentication-first, with a public `/explore`
product tour that contains no marketplace or service records. Google OAuth is
visibly disabled until its deployment flag is enabled. Confirmed email users
continue through a campus-aware onboarding flow before member routes unlock.
The profile route exposes editable student details and read-only account and
verification status.

The earlier Marketplace and Services captures under `docs/design/` document
the product direction that preceded the authentication, onboarding, and
empty-data pass. They are design history, not claims about current inventory.

## Visual and responsive checks

| Surface | Viewport | Theme | Result |
| --- | ---: | --- | --- |
| Sign in | 1440 x 1024 | Light | Passed |
| Public explore | 1440 x 1024 | Light | Passed |
| Public explore | 390 x 843 | Light | Passed |
| Create account | 375 x 811 | Light | Passed |
| Email-matched onboarding | 1440 x 1000 | Light | Passed |
| Email-matched onboarding | 390 x 844 | Light | Passed |
| Profile editing | 390 x 844 | Light | Passed |

Verified characteristics:

- Industrial off-white, charcoal, blue, and restrained olive palette
- Clear split between the public product story and secure access
- Consistent Archivo/Inter typography and Phosphor iconography
- Sign-in and account-creation tabs remain the strongest controls
- No fake marketplace counts, testimonials, ratings, students, or inventory
- No horizontal overflow at desktop or mobile widths
- Mobile authentication appears before the longer product story
- Onboarding and profile forms preserve the existing card and field system
- Campus and verification states use restrained trust colors and plain language
- Light and dark themes preserve hierarchy and contrast

## Interaction and access checks

- Sign-in and account-creation tabs update the URL and document title.
- The light/dark switch works at desktop and mobile breakpoints.
- Empty sign-in submission returns an inline validation error.
- Marketplace and other member routes redirect signed-out visitors to `/`.
- `/explore` remains available while signed out and exposes no record data.
- Signed-in users without completed onboarding redirect to `/onboarding`.
- A confirmed matching college email can claim its campus automatically.
- An unmatched email can request a campus and enters pending ID review.
- Google sign-in is disabled in the UI while its provider flag is false.
- Profile fields can be edited without exposing or editing the private email.
- Password visibility uses an explicitly labelled icon button.
- Terms, Privacy, and Safety routes are reachable before authentication.
- The document includes a skip link and semantic header, main, form, and
  footer landmarks.

## Automated evidence

- TypeScript strict typecheck: passed
- Vitest and React Testing Library: 17 tests passed
- Vite production build: passed
- Largest JavaScript chunk: approximately 259 KB before gzip
- Production dependency audit: 0 vulnerabilities
- Registry integrity: 194 verified signatures and 69 attestations
- Local Supabase reset: passed
- Supabase database lint: no schema errors
- Supabase pgTAP authorization suite: 53 tests passed
- Demo generator: 33 manifest-tagged rows, including 4 listings and 3 services
- Demo cleanup: returned the manifest to zero
- Cleanup guard: aborts if an untagged user or record depends on a demo entity

Full screen-reader, keyboard-only, 200% zoom, production SMTP, OAuth consent,
and real campus identity tests remain release activities against a Vercel
Preview connected to the migrated hosted Supabase project.
