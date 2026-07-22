<<<<<<< HEAD
# Jrent — Student Marketplace

A modern, responsive marketplace where students can buy and sell products on campus.

## Features

- **Browse marketplace** — Search, filter by category, and sort by price or name
- **Create listings** — Publish products with title, price, description, location, and contact
- **Shopping cart** — Add items, adjust quantities, and demo checkout
- **Product details** — View full listing info and email sellers directly
- **Demo login** — Sign in with name and email (stored locally in your browser)
- **Mobile-friendly** — Responsive layout with hamburger navigation

## Quick start

No build step is required. Open [index.html](index.html) directly in a modern browser, or run a local static server:

```bash
# Python
python -m http.server 8080

# Node (if npx is available)
npx serve .
```

Then visit `http://localhost:8080`.

## Deployment notes

- The site is fully static and can be deployed to any host that serves files directly, such as GitHub Pages, Netlify, or Vercel.
- To publish, upload the repository contents to the host root and ensure the files remain in the same relative structure.
- If you later connect authentication or persistent storage, replace the browser-only LocalStorage data layer with a backend service.

## Tech stack

- HTML5, CSS3, vanilla JavaScript
- LocalStorage for listings, cart, and user session
- Plus Jakarta Sans via Google Fonts

## Project structure

```
Jrent/
├── index.html   # Main page
├── styles.css   # Styles and animations
├── app.js       # Marketplace logic
└── README.md
```

## Notes

This is a front-end demo. Listings, cart, and login data are stored in your browser's localStorage — nothing is sent to a server. To make it production-ready, connect a backend (e.g. Supabase, Firebase) for auth, payments, and persistent storage.
=======
# Jrent — Student Marketplace

A modern, responsive marketplace where students can buy and sell products on campus.

## Features

- **Browse marketplace** — Search, filter by category, and sort by price or name
- **Create listings** — Publish products with title, price, description, location, and contact
- **Shopping cart** — Add items, adjust quantities, and demo checkout
- **Product details** — View full listing info and email sellers directly
- **Demo login** — Sign in with name and email (stored locally in your browser)
- **Mobile-friendly** — Responsive layout with hamburger navigation

## Quick start

No build step is required. Open [index.html](index.html) directly in a modern browser, or run a local static server:

```bash
# Python
python -m http.server 8080

# Node (if npx is available)
npx serve .
```

Then visit `http://localhost:8080`.

## Deployment notes

- The site is fully static and can be deployed to any host that serves files directly, such as GitHub Pages, Netlify, or Vercel.
- To publish, upload the repository contents to the host root and ensure the files remain in the same relative structure.
- If you later connect authentication or persistent storage, replace the browser-only LocalStorage data layer with a backend service.

## Tech stack

- HTML5, CSS3, vanilla JavaScript
- LocalStorage for listings, cart, and user session
- Plus Jakarta Sans via Google Fonts

## Project structure

```
Jrent/
├── index.html   # Main page
├── styles.css   # Styles and animations
├── app.js       # Marketplace logic
└── README.md
```

## Notes

This is a front-end demo. Listings, cart, and login data are stored in your browser's localStorage — nothing is sent to a server. To make it production-ready, connect a backend (e.g. Supabase, Firebase) for auth, payments, and persistent storage.
>>>>>>> 7317293a36d9c483c372e1db50011a893c8c15a4
