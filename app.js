(() => {
  'use strict';

  const STORAGE = {
    listings: 'jrent_listings_v2',
    cart: 'jrent_cart_v1',
    user: 'jrent_user_v1'
  };

  const categories = {
    all: 'All',
    electronics: 'Electronics',
    fashion: 'Fashion',
    books: 'Books',
    home: 'Home',
    services: 'Services'
  };

  const productImages = {
    electronics: 'product-phone.jpg',
    fashion: 'product-tshirt.jpg',
    books: 'product-book.jpg',
    home: 'product-home.jpg',
    services: 'product-services.jpg'
  };

  function productImageHTML(listing, className) {
    const source = listing.photos?.[0] || (listing.title.includes('AirPods') ? 'product-headphones-purple.jpg' : productImages[listing.category]);
    if (!source) return `<div class="${className} product-image product-image--placeholder">Listing photo</div>`;
    return `<div class="${className} product-image"><img src="${source}" alt="${escapeHTML(listing.title)}" loading="lazy" /></div>`;
  }
  const categoryIcons = {
    electronics: '📱',
    fashion: '👕',
    books: '📚',
    home: '🏠',
    services: '🎓'
  };

  const demoListings = [
    { id: uid(), title: 'Used AirPods (1st Gen)', category: 'electronics', price: 35, seller: 'Maya', description: 'Working well. Includes case and charging cable. No box.', location: 'Library', contact: 'maya@example.com', isDemo: true },
    { id: uid(), title: 'Handmade bracelet set', category: 'fashion', price: 12.5, seller: 'Zain', description: 'Two-piece set. Colorful beads, comfortable and lightweight.', location: 'Student Center', contact: 'zain@example.com', isDemo: true },
    { id: uid(), title: 'Calculus textbook (Vol. 1)', category: 'books', price: 18, seller: 'Sara', description: 'Good condition. Notes on first chapter only. Helpful for exam prep.', location: 'Engineering Block', contact: 'sara@example.com', isDemo: true },
      { id: uid(), title: 'Phone case — anti-slip', category: 'electronics', price: 8, seller: 'Omar', description: 'Durable grip, protects edges. Fits most iPhone models.', location: 'Campus Gate', contact: 'omar@example.com', isDemo: true },
    { id: uid(), title: 'Ceramic mug (set of 2)', category: 'home', price: 14, seller: 'Nina', description: 'Simple design with smooth glaze. Great for tea or coffee.', location: 'Dorm A', contact: 'nina@example.com', isDemo: true },
    { id: uid(), title: 'Math tutoring (Group)', category: 'services', price: 20, seller: 'Irfan', description: 'Weekly group sessions. Practice problems and quick feedback. Online or in-person.', location: 'Online / Library', contact: 'irfan@example.com', isDemo: true }
  ];

  let activeCategory = 'all';
  let sortBy = 'newest';

  const $ = (sel) => document.querySelector(sel);
  const $$ = (sel) => Array.from(document.querySelectorAll(sel));

  const els = {
    year: $('#year'),
    cardsGrid: $('#cardsGrid'),
    emptyState: $('#emptyState'),
    searchInput: $('#searchInput'),
    sortSelect: $('#sortSelect'),
    categoryChips: $('#categoryChips'),
    listingForm: $('#listingForm'),
    listingPhotos: $('#listingPhotos'),
    photoPreview: $('#photoPreview'),
    clearListings: $('#clearListings'),
    cartToggle: $('#cartToggle'),
    cartCount: $('#cartCount'),
    cartDrawer: $('#cartDrawer'),
    cartOverlay: $('#cartOverlay'),
    cartClose: $('#cartClose'),
    cartBody: $('#cartBody'),
    cartEmpty: $('#cartEmpty'),
    cartList: $('#cartList'),
    cartFooter: $('#cartFooter'),
    cartTotal: $('#cartTotal'),
    checkoutBtn: $('#checkoutBtn'),
    cartBrowse: $('#cartBrowse'),
    productModal: $('#productModal'),
    productModalContent: $('#productModalContent'),
    loginModal: $('#loginModal'),
    loginForm: $('#loginForm'),
    loginToggle: $('#loginToggle'),
    loginClose: $('#loginClose'),
    loginTitle: $('#loginTitle'),
    loginSubtitle: $('#loginSubtitle'),
    mobileLoginToggle: $('#mobileLoginToggle'),
    navToggle: $('#navToggle'),
    mobileNav: $('#mobileNav'),
    toastContainer: $('#toastContainer')
  };

  function uid() {
    try {
      const arr = new Uint32Array(4);
      crypto.getRandomValues(arr);
      return Array.from(arr, (n) => n.toString(16)).join('');
    } catch {
      return Math.random().toString(16).slice(2) + Date.now().toString(16);
    }
  }

  function load(key, fallback = null) {
    try {
      const raw = localStorage.getItem(key);
      return raw ? JSON.parse(raw) : fallback;
    } catch {
      return fallback;
    }
  }

  function save(key, data) {
    localStorage.setItem(key, JSON.stringify(data));
  }

  function formatPrice(n) {
    const v = Number(n);
    return new Intl.NumberFormat(undefined, { style: 'currency', currency: 'USD' }).format(Number.isFinite(v) ? v : 0);
  }

  function normalize(s) {
    return (s ?? '').toString().toLowerCase().trim();
  }

  function escapeHTML(str) {
    return (str ?? '').toString()
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#039;');
  }

  function toast(message, type = '') {
    const el = document.createElement('div');
    el.className = `toast${type ? ` toast--${type}` : ''}`;
    el.textContent = message;
    els.toastContainer.appendChild(el);
    setTimeout(() => {
      el.style.opacity = '0';
      el.style.transform = 'translateY(8px)';
      el.style.transition = '0.3s ease';
      setTimeout(() => el.remove(), 300);
    }, 3000);
  }

  function getUserListings() {
    return load(STORAGE.listings, []);
  }

  function getAllListings() {
    return [...getUserListings(), ...demoListings];
  }

  function getListingById(id) {
    return getAllListings().find((l) => l.id === id);
  }

  function getFilteredListings() {
    const q = normalize(els.searchInput?.value);

    let listings = getAllListings().filter((l) => {
      const matchCat = activeCategory === 'all' || l.category === activeCategory;
      if (!matchCat) return false;
      if (!q) return true;
      const hay = normalize([l.title, l.category, l.seller, l.description, l.location].join(' '));
      return hay.includes(q);
    });

    switch (sortBy) {
      case 'price-asc':
        listings.sort((a, b) => a.price - b.price);
        break;
      case 'price-desc':
        listings.sort((a, b) => b.price - a.price);
        break;
      case 'name':
        listings.sort((a, b) => a.title.localeCompare(b.title));
        break;
      default:
        break;
    }

    return listings;
  }

  function cardHTML(listing) {
    const catLabel = categories[listing.category] ?? listing.category;
    const loc = listing.location ? ` · ${listing.location}` : '';
    const isOwned = !listing.isDemo;

    return `
      <article class="card" data-id="${listing.id}">
        ${productImageHTML(listing, 'card__image')}
        <div class="card__body">
          <div class="card__top">
            <span class="card__cat">${escapeHTML(catLabel)}</span>
            <span class="card__price">${formatPrice(listing.price)}</span>
          </div>
          <h3 class="card__title">${escapeHTML(listing.title)}</h3>
          <p class="card__desc">${escapeHTML(listing.description)}</p>
          <div class="card__meta">
            <span class="card__seller">by <b>${escapeHTML(listing.seller)}</b>${escapeHTML(loc)}</span>
          </div>
          <div class="card__actions">
            <button class="btn btn--primary" type="button" data-action="cart">Add to cart</button>
            <button class="btn btn--ghost" type="button" data-action="view">View</button>
            ${isOwned ? '<button class="btn btn--danger btn--sm" type="button" data-action="delete">Delete</button>' : ''}
          </div>
        </div>
      </article>
    `;
  }

  function renderGrid() {
    if (!els.cardsGrid) return;

    const listings = getFilteredListings();
    els.cardsGrid.innerHTML = '';

    if (els.emptyState) {
      if (listings.length === 0) {
        els.emptyState.hidden = false;
        return;
      }
      els.emptyState.hidden = true;
    }

    const frag = document.createDocumentFragment();

    listings.forEach((l) => {
      const wrapper = document.createElement('div');
      wrapper.innerHTML = cardHTML(l);
      frag.appendChild(wrapper.firstElementChild);
    });

    els.cardsGrid.appendChild(frag);
    wireCardActions();
  }

  function wireCardActions() {
    els.cardsGrid.querySelectorAll('[data-action="cart"]').forEach((btn) => {
      btn.addEventListener('click', () => {
        const id = btn.closest('.card')?.dataset?.id;
        if (id) addToCart(id);
      });
    });

    els.cardsGrid.querySelectorAll('[data-action="view"]').forEach((btn) => {
      btn.addEventListener('click', () => {
        const id = btn.closest('.card')?.dataset?.id;
        if (id) openProductModal(id);
      });
    });

    els.cardsGrid.querySelectorAll('[data-action="delete"]').forEach((btn) => {
      btn.addEventListener('click', () => {
        const id = btn.closest('.card')?.dataset?.id;
        if (id && confirm('Delete this listing?')) deleteListing(id);
      });
    });
  }

  function deleteListing(id) {
    const listings = getUserListings().filter((l) => l.id !== id);
    save(STORAGE.listings, listings);
    removeFromCart(id);
    renderGrid();
    toast('Listing deleted', 'success');
  }

  function openProductModal(id) {
    if (!els.productModal || !els.productModalContent) return;

    const listing = getListingById(id);
    if (!listing) return;

    els.productModalContent.innerHTML = `
      ${productImageHTML(listing, 'modal__image')}
      <h2 class="modal__title">${escapeHTML(listing.title)}</h2>
      <div class="modal__price">${formatPrice(listing.price)}</div>
      <p class="modal__desc">${escapeHTML(listing.description)}</p>
      <div class="modal__details">
        <div class="modal__detail"><span>Category</span><span>${escapeHTML(categories[listing.category] ?? listing.category)}</span></div>
        <div class="modal__detail"><span>Seller</span><span>${escapeHTML(listing.seller)}</span></div>
        ${listing.location ? `<div class="modal__detail"><span>Location</span><span>${escapeHTML(listing.location)}</span></div>` : ''}
        ${listing.contact ? `<div class="modal__detail"><span>Contact</span><span>${escapeHTML(listing.contact)}</span></div>` : ''}
      </div>
      ${listing.photos?.length > 1 ? `<div class="photo-gallery">${listing.photos.map((photo, index) => `<button type="button" class="photo-gallery__thumb" data-gallery-photo="${index}"><img src="${photo}" alt="${escapeHTML(listing.title)} photo ${index + 1}" /></button>`).join('')}</div>` : ''}
      <div class="modal__actions">
        <button class="btn btn--primary" type="button" id="modalAddCart">Add to cart</button>
        <button class="btn btn--ghost" type="button" id="modalMessageSeller">Message seller</button>
      </div>
      <form class="seller-message" id="sellerMessageForm" hidden>
        <label>Message to ${escapeHTML(listing.seller)}<textarea name="message" rows="3" maxlength="500" required placeholder="Ask about availability, condition, or pickup..."></textarea></label>
        <button class="btn btn--primary" type="submit">Send message</button>
      </form>
    `;

    $$('#productModalContent [data-gallery-photo]').forEach((button) => {
      button.addEventListener('click', () => {
        const photo = listing.photos?.[Number(button.dataset.galleryPhoto)];
        const image = $('#productModalContent .modal__image img');
        if (photo && image) image.src = photo;
      });
    });

    $('#modalMessageSeller')?.addEventListener('click', () => {
      $('#sellerMessageForm').hidden = false;
    });

    $('#sellerMessageForm')?.addEventListener('submit', (event) => {
      event.preventDefault();
      const message = new FormData(event.currentTarget).get('message')?.toString().trim();
      if (!message) return;

      const messages = load('jrent_messages_v1', []);
      messages.unshift({ id: uid(), listingId: listing.id, seller: listing.seller, message, sentAt: Date.now() });
      save('jrent_messages_v1', messages);
      event.currentTarget.reset();
      event.currentTarget.hidden = true;
      toast(`Message saved for ${listing.seller}.`, 'success');
    });

    $('#modalAddCart')?.addEventListener('click', () => {
      addToCart(id);
      els.productModal.close();
    });

    els.productModal.showModal();
  }

  els.productModal?.addEventListener('click', (e) => {
    if (e.target === els.productModal) els.productModal.close();
  });

  function getCart() {
    return load(STORAGE.cart, []);
  }

  function saveCart(cart) {
    save(STORAGE.cart, cart);
    updateCartUI();
  }

  function addToCart(id) {
    const listing = getListingById(id);
    if (!listing) return;

    const cart = getCart();
    const existing = cart.find((c) => c.id === id);

    if (existing) {
      existing.qty += 1;
    } else {
      cart.push({ id, qty: 1 });
    }

    saveCart(cart);
    toast(`Added "${listing.title}" to cart`, 'success');
  }

  function removeFromCart(id) {
    saveCart(getCart().filter((c) => c.id !== id));
  }

  function updateCartQty(id, delta) {
    const cart = getCart();
    const item = cart.find((c) => c.id === id);
    if (!item) return;

    item.qty += delta;
    if (item.qty <= 0) {
      saveCart(cart.filter((c) => c.id !== id));
    } else {
      saveCart(cart);
    }
  }

  function updateCartUI() {
    const cart = getCart();
    const totalItems = cart.reduce((sum, c) => sum + c.qty, 0);

    if (els.cartCount) {
      if (totalItems > 0) {
        els.cartCount.hidden = false;
        els.cartCount.textContent = totalItems;
      } else {
        els.cartCount.hidden = true;
      }
    }

    if (!els.cartEmpty || !els.cartList || !els.cartFooter || !els.cartTotal) return;

    if (cart.length === 0) {
      els.cartEmpty.hidden = false;
      els.cartList.hidden = true;
      els.cartFooter.hidden = true;
      return;
    }

    els.cartEmpty.hidden = true;
    els.cartList.hidden = false;
    els.cartFooter.hidden = false;

    let total = 0;
    els.cartList.innerHTML = '';

    cart.forEach((item) => {
      const listing = getListingById(item.id);
      if (!listing) return;

      total += listing.price * item.qty;
  
  
      const li = document.createElement('li');
      li.className = 'cart-item';
      li.innerHTML = `
        ${productImageHTML(listing, 'cart-item__icon')}
        <div class="cart-item__info">
          <div class="cart-item__title">${escapeHTML(listing.title)}</div>
          <div class="cart-item__meta">${formatPrice(listing.price)} · ${escapeHTML(listing.seller)}</div>
          <div class="cart-item__actions">
            <div class="cart-item__qty">
              <button type="button" data-qty="-1" data-id="${item.id}">âˆ’</button>
              <span>${item.qty}</span>
              <button type="button" data-qty="1" data-id="${item.id}">+</button>
            </div>
            <button class="cart-item__remove" type="button" data-remove="${item.id}">Remove</button>
          </div>
        </div>
      `;
      els.cartList.appendChild(li);
    });

    els.cartTotal.textContent = formatPrice(total);

    els.cartList.querySelectorAll('[data-qty]').forEach((btn) => {
      btn.addEventListener('click', () => {
        updateCartQty(btn.dataset.id, Number(btn.dataset.qty));
      });
    });

    els.cartList.querySelectorAll('[data-remove]').forEach((btn) => {
      btn.addEventListener('click', () => removeFromCart(btn.dataset.remove));
    });
  }

  function openCart() {
    if (!els.cartDrawer) return;
    els.cartDrawer.hidden = false;
    document.body.style.overflow = 'hidden';
  }

  function closeCart() {
    if (els.cartDrawer) els.cartDrawer.hidden = true;
    document.body.style.overflow = '';
  }

  els.cartToggle?.addEventListener('click', openCart);
  els.cartClose?.addEventListener('click', closeCart);
  els.cartOverlay?.addEventListener('click', closeCart);
  els.cartBrowse?.addEventListener('click', () => {
    closeCart();
    document.querySelector('#market')?.scrollIntoView({ behavior: 'smooth' });
  });

  els.checkoutBtn?.addEventListener('click', () => {
    const cart = getCart();
    if (cart.length === 0) return;

    const sellers = cart.map((c) => getListingById(c.id)).filter(Boolean);
    const contacts = [...new Set(sellers.map((s) => s.contact).filter(Boolean))];

    saveCart([]);
    closeCart();

    if (contacts.length > 0) {
      toast('Order placed! Contact sellers to arrange pickup.', 'success');
    } else {
      toast('Order placed! Reach out to sellers on campus.', 'success');
    }
  });

  els.categoryChips?.addEventListener('click', (e) => {
    const chip = e.target.closest('.chip');
    if (!chip) return;

    $$('.chip').forEach((c) => c.setAttribute('aria-pressed', 'false'));
    chip.setAttribute('aria-pressed', 'true');
    activeCategory = chip.dataset.filter || 'all';
    renderGrid();
  });

  els.searchInput?.addEventListener('input', renderGrid);

  els.sortSelect?.addEventListener('change', () => {
    sortBy = els.sortSelect.value;
    renderGrid();
  });

  let pendingPhotos = [];

  function resizePhoto(file) {
    return new Promise((resolve, reject) => {
      const image = new Image();
      const objectUrl = URL.createObjectURL(file);

      image.onload = () => {
        const maxSide = 960;
        const scale = Math.min(1, maxSide / Math.max(image.width, image.height));
        const canvas = document.createElement('canvas');
        canvas.width = Math.round(image.width * scale);
        canvas.height = Math.round(image.height * scale);
        canvas.getContext('2d').drawImage(image, 0, 0, canvas.width, canvas.height);
        URL.revokeObjectURL(objectUrl);
        resolve(canvas.toDataURL('image/jpeg', 0.76));
      };

      image.onerror = () => {
        URL.revokeObjectURL(objectUrl);
        reject(new Error('Could not read image'));
      };

      image.src = objectUrl;
    });
  }

  function renderPhotoPreview() {
    if (!els.photoPreview) return;
    els.photoPreview.innerHTML = pendingPhotos
      .map((photo, index) => `<img src="${photo}" alt="Selected photo ${index + 1}" />`)
      .join('');
  }

  els.listingPhotos?.addEventListener('change', async () => {
    const files = Array.from(els.listingPhotos.files || []).slice(0, 4);

    try {
      pendingPhotos = await Promise.all(files.map(resizePhoto));
      renderPhotoPreview();
      if ((els.listingPhotos.files?.length || 0) > 4) toast('Only the first 4 photos were selected.');
    } catch {
      pendingPhotos = [];
      renderPhotoPreview();
      toast('One of the selected photos could not be read.');
    }
  });

  els.listingForm?.addEventListener('submit', (e) => {
    e.preventDefault();
    const fd = new FormData(els.listingForm);

    const listing = {
      id: uid(),
      title: fd.get('title')?.toString().trim(),
      category: fd.get('category')?.toString(),
      price: Number(fd.get('price')) || 0,
      seller: fd.get('seller')?.toString().trim() || 'Student',
      description: fd.get('description')?.toString().trim(),
      location: fd.get('location')?.toString().trim() || '',
      contact: fd.get('contact')?.toString().trim() || '',
      photos: pendingPhotos
    };

    const current = getUserListings();
    current.unshift(listing);
    save(STORAGE.listings, current);

    els.listingForm.reset();
    pendingPhotos = [];
    renderPhotoPreview();
    renderGrid();
    toast('Listing published!', 'success');

    document.querySelector('#market')?.scrollIntoView({ behavior: 'smooth' });
  });

  els.clearListings?.addEventListener('click', () => {
    if (!confirm('Clear all your saved listings?')) return;
    localStorage.removeItem(STORAGE.listings);
    renderGrid();
    toast('Your listings cleared', 'success');
  });

  function getUser() {
    return load(STORAGE.user, null);
  }

  function setUser(user) {
    save(STORAGE.user, user);
    updateLoginUI();
  }

  function updateLoginUI() {
    const user = getUser();
    const actionsEl = document.querySelector('.topbar__actions');

    actionsEl?.querySelector('.user-badge')?.remove();

    if (user) {
      if (els.loginToggle) els.loginToggle.textContent = 'Logout';
      if (els.mobileLoginToggle) els.mobileLoginToggle.textContent = 'Logout';

      const badge = document.createElement('div');
      badge.className = 'user-badge';
      badge.innerHTML = `
        <span class="user-badge__avatar">${escapeHTML(user.name.charAt(0).toUpperCase())}</span>
        <span>${escapeHTML(user.name.split(' ')[0])}</span>
      `;
      actionsEl?.insertBefore(badge, els.cartToggle);
    } else {
      if (els.loginToggle) els.loginToggle.textContent = 'Login';
      if (els.mobileLoginToggle) els.mobileLoginToggle.textContent = 'Login';
    }
  }

  function openLogin() {
    if (!els.loginModal || !els.loginTitle || !els.loginSubtitle) return;

    const user = getUser();
    if (user) {
      setUser(null);
      toast('Logged out');
      return;
    }

    els.loginTitle.textContent = 'Welcome to Jrent';
    els.loginSubtitle.textContent = 'Sign in to track your listings and cart.';
    els.loginModal.showModal();
  }

  els.loginToggle?.addEventListener('click', openLogin);
  els.mobileLoginToggle?.addEventListener('click', openLogin);
  els.loginClose?.addEventListener('click', () => els.loginModal.close());

  els.loginModal?.addEventListener('click', (e) => {
    if (e.target === els.loginModal) els.loginModal.close();
  });

  els.loginForm?.addEventListener('submit', (e) => {
    e.preventDefault();
    const fd = new FormData(els.loginForm);
    const name = fd.get('name')?.toString().trim();
    const email = fd.get('email')?.toString().trim();

    if (!name || !email) return;

    setUser({ name, email, joined: Date.now() });
    els.loginModal.close();
    els.loginForm.reset();
    toast(`Welcome, ${name.split(' ')[0]}!`, 'success');
  });

  els.navToggle?.addEventListener('click', () => {
    const open = els.mobileNav.hidden;
    els.mobileNav.hidden = !open;
    els.navToggle.setAttribute('aria-expanded', String(open));
  });

  els.mobileNav?.querySelectorAll('a').forEach((link) => {
    link.addEventListener('click', () => {
      els.mobileNav.hidden = true;
      els.navToggle.setAttribute('aria-expanded', 'false');
    });
  });

  if (els.year) els.year.textContent = new Date().getFullYear();

  updateLoginUI();
  updateCartUI();
  renderGrid();
})();


