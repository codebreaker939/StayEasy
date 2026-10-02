/** Check the public client key without requiring a signed-in Supabase user. */
export function hasValidPublishableApiKey(request: Request): boolean {
  const provided = request.headers.get("apikey");
  const configured = Deno.env.get("SUPABASE_PUBLISHABLE_KEYS");
  if (!provided || !provided.startsWith("sb_publishable_") || !configured) {
    return false;
  }

  try {
    const parsed: unknown = JSON.parse(configured);
    if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
      return false;
    }
    return Object.values(parsed).some(
      (key) =>
        typeof key === "string" && key.startsWith("sb_publishable_") &&
        key === provided,
    );
  } catch {
    return false;
  }
}
