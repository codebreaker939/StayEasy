# StayEasy AI

Flutter calls Supabase Edge Functions; only those functions call the OpenAI Responses API. The OpenAI key and database credentials never enter Flutter. Requests use structured JSON output with `store: false`; functions return categorized errors rather than provider details.

## Capabilities

- `ai-search` extracts canonical search intent only. The client applies parsed filters to the existing `SearchState` and filters real hotel/room repository data for the displayed result count. AI does not rank hotels, inspect availability, or set prices.
- `ai-review-insights` fetches verified reviews for the selected hotel through a caller-scoped Supabase client, preserving RLS. It selects up to eight reviews using the same month/nearby-season/exact-room/verified/helpfulness/recency weights and stable ID tie-break as the Dart ranker. Fewer than three relevant verified reviews returns `insufficient_evidence` without a model call. User/profile fields are never sent to OpenAI; every generated bullet must cite evidence IDs from that selected set.
- The AI summary is a separate, secondary view. The existing deterministic Dart review ordering is unchanged and does not consume AI output.

Both functions validate the caller's Supabase user token. This also limits anonymous cost abuse; guest browsing and normal search remain available without AI. Browser calls require an exact web origin in `APP_ALLOWED_ORIGINS` (comma-separated); native calls without an `Origin` header are supported.

## Runtime configuration and deployment

Set project Edge Function secrets by name in the Supabase Dashboard:

- `OPENAI_API_KEY` (required; if absent, the endpoint returns `AI_NOT_CONFIGURED`)
- `OPENAI_MODEL` (optional; defaults to `gpt-5.6-luna`)
- `APP_ALLOWED_ORIGINS` (required for Flutter Web; exact origins, comma-separated)

Then deploy with the Supabase CLI: `supabase functions deploy ai-search` and `supabase functions deploy ai-review-insights`. Do not put these values in Flutter, `--dart-define`, local app config, or source control. Local Edge Function tests mock the OpenAI fetch; live AI is not claimed unless the project secret is configured and an authenticated request is actually made.
