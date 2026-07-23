# Agent handoff

The canonical agent instructions are in [`AGENTS.md`](./AGENTS.md).

Start with:

1. [`README.md`](./README.md) for product and repository status.
2. [`docs/PRODUCT_RESEARCH.md`](./docs/PRODUCT_RESEARCH.md) for market rationale.
3. [`docs/ARCHITECTURE.md`](./docs/ARCHITECTURE.md) for route and data ownership.
4. [`docs/SECURITY.md`](./docs/SECURITY.md) before changing Auth, data, uploads,
   messaging, moderation, or deployment.

Critical invariant: Marketplace is item-only; student services live only on
the Services route.

Additional invariants:

- `/` is the public sign-in/account-creation landing page.
- Member product routes stay protected by Supabase Auth.
- The application must remain empty when the database is empty.
- Never import demo identities or records into browser source.
- Optional fixtures live only in `supabase/demo/` and every inserted record
  must be tracked by `private.venturr_demo_manifest`.
- Run `npm run verify`, `npx supabase db lint`, and the pgTAP suite before a
  release handoff.
