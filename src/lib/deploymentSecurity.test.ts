import vercelConfig from "../../vercel.json";

describe("Vercel security policy", () => {
  it("allows only the configured Supabase project for browser API traffic", () => {
    const globalHeaders = vercelConfig.headers.find((entry) => entry.source === "/(.*)");
    const csp = globalHeaders?.headers.find(
      (header) => header.key === "Content-Security-Policy",
    )?.value;

    expect(csp).toContain(
      "connect-src 'self' https://hukipusfhvrejiisxymp.supabase.co wss://hukipusfhvrejiisxymp.supabase.co",
    );
    expect(csp).not.toContain("*.supabase.co");
    expect(csp).not.toContain("service_role");
  });
});
