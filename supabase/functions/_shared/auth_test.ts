import { hasValidPublishableApiKey } from "./auth.ts";

Deno.test("guest AI auth requires an exact configured publishable key", () => {
  const name = "SUPABASE_PUBLISHABLE_KEYS";
  const original = Deno.env.get(name);
  const publishable = "sb_publishable_stayeasy_test";
  const request = (key?: string) =>
    new Request("https://example.test", {
      headers: key ? { apikey: key } : {},
    });

  try {
    Deno.env.set(
      name,
      JSON.stringify({
        default: publishable,
        preview: "sb_publishable_preview_test",
      }),
    );
    if (!hasValidPublishableApiKey(request(publishable))) {
      throw new Error("configured publishable key was rejected");
    }
    if (!hasValidPublishableApiKey(request("sb_publishable_preview_test"))) {
      throw new Error("configured secondary publishable key was rejected");
    }
    if (
      hasValidPublishableApiKey(request("sb_publishable_unconfigured_test"))
    ) {
      throw new Error("unconfigured publishable key was accepted");
    }
    if (hasValidPublishableApiKey(request())) {
      throw new Error("missing apikey header was accepted");
    }

    Deno.env.set(name, JSON.stringify({ default: "sb_secret_stayeasy_test" }));
    if (hasValidPublishableApiKey(request("sb_secret_stayeasy_test"))) {
      throw new Error("secret key was accepted as a publishable key");
    }

    Deno.env.set(name, "{invalid json");
    if (hasValidPublishableApiKey(request(publishable))) {
      throw new Error("malformed configured keys were accepted");
    }
  } finally {
    if (original == null) Deno.env.delete(name);
    else Deno.env.set(name, original);
  }
});
