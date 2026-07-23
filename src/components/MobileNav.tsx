import {
  BookmarkSimple,
  ChatCircle,
  Package,
  PlusCircle,
  UserCircle,
  UsersThree,
} from "@phosphor-icons/react";
import { NavLink } from "react-router-dom";
import { useApp } from "../context/AppContext";

export function MobileNav() {
  const { openPost } = useApp();

  return (
    <nav className="mobile-nav" aria-label="Mobile navigation">
      <NavLink to="/marketplace">
        <Package size={22} />
        <span>Market</span>
      </NavLink>
      <NavLink to="/services">
        <UsersThree size={22} />
        <span>Services</span>
      </NavLink>
      <button type="button" onClick={() => openPost("item")} aria-label="Create a post">
        <PlusCircle size={28} weight="fill" />
        <span>Post</span>
      </button>
      <NavLink to="/inbox">
        <ChatCircle size={22} />
        <span>Inbox</span>
      </NavLink>
      <NavLink to="/saved">
        <BookmarkSimple size={22} />
        <span>Saved</span>
      </NavLink>
    </nav>
  );
}
