const AUTH_RETURN_KEY = "venturr_auth_return_v1";

const allowedDestinations = new Set([
  "/marketplace",
  "/services",
  "/saved",
  "/inbox",
  "/profile",
]);

export function safeAuthReturnPath(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const trimmed = value.trim();
  if (!trimmed.startsWith("/") || trimmed.startsWith("//")) return null;

  const [pathname] = trimmed.split(/[?#]/, 1);
  return pathname && allowedDestinations.has(pathname) ? trimmed : null;
}

export function rememberAuthReturnPath(value: unknown) {
  const safePath = safeAuthReturnPath(value);
  if (safePath) window.sessionStorage.setItem(AUTH_RETURN_KEY, safePath);
}

export function readAuthReturnPath(): string {
  return safeAuthReturnPath(window.sessionStorage.getItem(AUTH_RETURN_KEY)) ?? "/marketplace";
}

export function consumeAuthReturnPath(): string {
  const destination = readAuthReturnPath();
  window.sessionStorage.removeItem(AUTH_RETURN_KEY);
  return destination;
}
