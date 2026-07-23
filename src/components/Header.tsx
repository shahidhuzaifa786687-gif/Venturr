import {
  BookmarkSimple,
  Buildings,
  CaretDown,
  ChatCircle,
  ListPlus,
  MagnifyingGlass,
  Moon,
  Package,
  Plus,
  SignOut,
  Sun,
  UserCircle,
  UsersThree,
  X,
} from "@phosphor-icons/react";
import { useEffect, useRef, useState, type FormEvent } from "react";
import { NavLink, useLocation, useNavigate, useSearchParams } from "react-router-dom";
import { useApp } from "../context/AppContext";
import { useAuth } from "../context/AuthContext";
import type { Theme } from "../hooks/useTheme";
import { Avatar } from "./Avatar";
import { VisuallyHidden } from "./VisuallyHidden";

interface HeaderProps {
  theme: Theme;
  onToggleTheme: () => void;
}

export function Header({ theme, onToggleTheme }: HeaderProps) {
  const { openPost, conversations } = useApp();
  const { signOut, student } = useAuth();
  const [postMenuOpen, setPostMenuOpen] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const menuRef = useRef<HTMLDivElement>(null);
  const navigate = useNavigate();
  const location = useLocation();
  const [searchParams] = useSearchParams();
  const [search, setSearch] = useState(searchParams.get("q") ?? "");
  const unreadCount = conversations.filter((conversation) => conversation.unread).length;

  useEffect(() => {
    setSearch(searchParams.get("q") ?? "");
  }, [searchParams]);

  useEffect(() => {
    function closeOnOutsideClick(event: MouseEvent) {
      if (menuRef.current && !menuRef.current.contains(event.target as Node)) {
        setPostMenuOpen(false);
      }
    }
    document.addEventListener("mousedown", closeOnOutsideClick);
    return () => document.removeEventListener("mousedown", closeOnOutsideClick);
  }, []);

  function submitSearch(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const route = location.pathname.startsWith("/services") ? "/services" : "/marketplace";
    const query = search.trim();
    navigate(query ? `${route}?q=${encodeURIComponent(query)}` : route);
  }

  function choosePost(kind: "item" | "service") {
    openPost(kind);
    setPostMenuOpen(false);
    setMobileMenuOpen(false);
  }

  async function leave() {
    await signOut();
    navigate("/", { replace: true });
  }

  return (
    <header className="site-header">
      <a className="skip-link" href="#main-content">
        Skip to content
      </a>
      <div className="header-inner">
        <NavLink className="wordmark" to="/marketplace" aria-label="Venturr marketplace">
          Venturr
        </NavLink>

        <button className="campus-switcher" type="button" aria-label="Campus membership setup required">
          <Buildings size={21} aria-hidden="true" />
          <span>
            <strong>Campus access</strong>
            <small>Setup required</small>
          </span>
          <CaretDown size={15} aria-hidden="true" />
        </button>

        <form className="global-search" role="search" onSubmit={submitSearch}>
          <MagnifyingGlass size={20} aria-hidden="true" />
          <label className="sr-only" htmlFor="global-search-input">
            Search Venturr
          </label>
          <input
            id="global-search-input"
            value={search}
            onChange={(event) => setSearch(event.target.value)}
            maxLength={80}
            placeholder="Search items, services, books, gear…"
            type="search"
          />
          {search ? (
            <button
              className="search-clear"
              type="button"
              onClick={() => setSearch("")}
              aria-label="Clear search"
            >
              <X size={16} aria-hidden="true" />
            </button>
          ) : (
            <kbd>/</kbd>
          )}
        </form>

        <nav className="header-actions" aria-label="Account">
          <NavLink className="header-action" to="/saved">
            <BookmarkSimple size={21} aria-hidden="true" />
            <span>Saved</span>
          </NavLink>
          <NavLink className="header-action header-action--inbox" to="/inbox">
            <ChatCircle size={22} aria-hidden="true" />
            <span>Inbox</span>
            {unreadCount > 0 ? (
              <span className="notification-dot" aria-label={`${unreadCount} unread conversations`}>
                {unreadCount}
              </span>
            ) : null}
          </NavLink>
          <button
            className="theme-toggle"
            onClick={onToggleTheme}
            type="button"
            aria-label={`Switch to ${theme === "light" ? "dark" : "light"} mode`}
            title={`Switch to ${theme === "light" ? "dark" : "light"} mode`}
          >
            {theme === "light" ? (
              <Sun size={18} aria-hidden="true" />
            ) : (
              <Moon size={18} aria-hidden="true" />
            )}
          </button>
          {student ? (
            <NavLink className="profile-link" to="/profile">
              <Avatar student={student} size="small" />
              <span>Hi, {student.name.split(/\s+/)[0]}</span>
              <CaretDown size={14} aria-hidden="true" />
            </NavLink>
          ) : null}
          <button
            className="header-action"
            type="button"
            onClick={() => void leave()}
            title="Sign out"
          >
            <SignOut size={21} aria-hidden="true" />
            <span>Sign out</span>
          </button>
          <div className="post-control" ref={menuRef}>
            <button
              className="post-button"
              type="button"
              aria-haspopup="menu"
              aria-expanded={postMenuOpen}
              onClick={() => setPostMenuOpen((open) => !open)}
            >
              <Plus size={18} weight="bold" aria-hidden="true" />
              <span>Post</span>
              <CaretDown size={14} weight="bold" aria-hidden="true" />
            </button>
            {postMenuOpen ? (
              <div className="post-menu" role="menu" aria-label="Create a post">
                <button role="menuitem" type="button" onClick={() => choosePost("item")}>
                  <Package size={22} aria-hidden="true" />
                  <span>
                    <strong>List an item</strong>
                    <small>Sell, rent, give away, or request</small>
                  </span>
                </button>
                <button role="menuitem" type="button" onClick={() => choosePost("service")}>
                  <UsersThree size={22} aria-hidden="true" />
                  <span>
                    <strong>Offer a service</strong>
                    <small>Coach, tutor, create, or lend a hand</small>
                  </span>
                </button>
              </div>
            ) : null}
          </div>
        </nav>

        <button
          className="mobile-menu-toggle"
          type="button"
          aria-expanded={mobileMenuOpen}
          aria-controls="mobile-header-menu"
          onClick={() => setMobileMenuOpen((open) => !open)}
        >
          <VisuallyHidden>{mobileMenuOpen ? "Close menu" : "Open menu"}</VisuallyHidden>
          {mobileMenuOpen ? <X size={22} /> : <ListPlus size={22} />}
        </button>
      </div>

      {mobileMenuOpen ? (
        <div className="mobile-header-menu" id="mobile-header-menu">
          <NavLink to="/saved" onClick={() => setMobileMenuOpen(false)}>
            <BookmarkSimple size={20} /> Saved
          </NavLink>
          <NavLink to="/inbox" onClick={() => setMobileMenuOpen(false)}>
            <ChatCircle size={20} /> Inbox
          </NavLink>
          <NavLink to="/profile" onClick={() => setMobileMenuOpen(false)}>
            <UserCircle size={20} /> Profile
          </NavLink>
          <button type="button" onClick={onToggleTheme}>
            {theme === "light" ? <Moon size={20} /> : <Sun size={20} />}
            {theme === "light" ? "Dark mode" : "Light mode"}
          </button>
          <button type="button" onClick={() => choosePost("item")}>
            <Package size={20} /> List an item
          </button>
          <button type="button" onClick={() => choosePost("service")}>
            <UsersThree size={20} /> Offer a service
          </button>
          <button type="button" onClick={() => void leave()}>
            <SignOut size={20} /> Sign out
          </button>
        </div>
      ) : null}
    </header>
  );
}
