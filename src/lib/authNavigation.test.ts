import {
  consumeAuthReturnPath,
  rememberAuthReturnPath,
  safeAuthReturnPath,
} from "./authNavigation";

describe("auth return navigation", () => {
  it("allows only known internal product routes", () => {
    expect(safeAuthReturnPath("/marketplace?q=books")).toBe("/marketplace?q=books");
    expect(safeAuthReturnPath("/services")).toBe("/services");
    expect(safeAuthReturnPath("//attacker.example")).toBeNull();
    expect(safeAuthReturnPath("https://attacker.example")).toBeNull();
    expect(safeAuthReturnPath("/auth/callback")).toBeNull();
  });

  it("consumes a remembered destination once", () => {
    rememberAuthReturnPath("/saved");
    expect(consumeAuthReturnPath()).toBe("/saved");
    expect(consumeAuthReturnPath()).toBe("/marketplace");
  });
});
