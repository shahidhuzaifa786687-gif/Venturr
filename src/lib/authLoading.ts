export function isAccountBootstrapPending(
  authLoading: boolean,
  sessionUserId: string | null,
  loadedAccountUserId: string | null,
): boolean {
  if (authLoading) return true;
  if (!sessionUserId) return false;
  return loadedAccountUserId !== sessionUserId;
}
