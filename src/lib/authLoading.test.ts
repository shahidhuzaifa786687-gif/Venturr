import { describe, expect, it } from "vitest";
import { isAccountBootstrapPending } from "./authLoading";

describe("isAccountBootstrapPending", () => {
  it("waits for authentication and the first account load", () => {
    expect(isAccountBootstrapPending(true, null, null)).toBe(true);
    expect(isAccountBootstrapPending(false, "user-1", null)).toBe(true);
    expect(isAccountBootstrapPending(false, "user-2", "user-1")).toBe(true);
  });

  it("does not remount routes during a background account refresh", () => {
    expect(isAccountBootstrapPending(false, "user-1", "user-1")).toBe(false);
  });

  it("finishes loading when there is no signed-in user", () => {
    expect(isAccountBootstrapPending(false, null, null)).toBe(false);
  });
});
