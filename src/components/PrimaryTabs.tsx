import { Package, UsersThree } from "@phosphor-icons/react";
import { NavLink } from "react-router-dom";

export function PrimaryTabs() {
  return (
    <nav className="primary-tabs" aria-label="Browse Venturr">
      <NavLink to="/marketplace">
        <Package size={22} aria-hidden="true" />
        Marketplace
      </NavLink>
      <NavLink to="/services">
        <UsersThree size={22} aria-hidden="true" />
        Services
      </NavLink>
    </nav>
  );
}
