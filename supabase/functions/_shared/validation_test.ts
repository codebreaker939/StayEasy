import { sanitizeSearch, validateSearchInput } from './search.ts';
import { sanitizeInsights, selectReviewEvidence, runInsightIfEvidenceSufficient, type EvidenceReview } from './review-insights.ts';
import { structuredResponse, AiError, parseStructuredPayload, toGeminiJsonSchema } from './gemini.ts';
import { SEARCH_SCHEMA } from './search.ts';
import { INSIGHT_SCHEMA } from './review-insights.ts';

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}
function assertThrows(operation: () => unknown, expected: string) {
  try { operation(); } catch (error) { assert(error instanceof Error && error.message === expected, `expected ${expected}`); return; }
  throw new Error(`expected ${expected} to be thrown`);
}

const parsedSearch = {
  status: 'parsed',
  filters: {
    city: 'Mumbai', month: 10, check_in: null, check_out: null, guests: 2,
    max_price_inr: 5000, min_rating: 4, amenities: ['Wi-Fi', 'not real'],
    room_types: ['Suite', 'Penthouse'], vibes: ['Quiet stay', 'party'],
  },
  clarification: null,
};

Deno.test('search trims and bounds user input', () => {
  assert(validateSearchInput('  stay please  ') === 'stay please', 'query was not trimmed');
  assertThrows(() => validateSearchInput('   '), 'INVALID_REQUEST');
  assertThrows(() => validateSearchInput('x'.repeat(501)), 'INVALID_REQUEST');
});

Deno.test('search output canonicalizes known values and removes unsupported values', () => {
  const value = sanitizeSearch(parsedSearch);
  assert(value.status === 'parsed', 'status');
  assert(value.filters.amenities.join(',') === 'Wi-Fi', 'unsupported amenity retained');
  assert(value.filters.room_types.join(',') === 'Suite', 'unsupported room type retained');
  assert(value.filters.vibes.join(',') === 'Quiet stay', 'unsupported vibe retained');
});

Deno.test('search validation rejects out-of-range numbers and invalid date relationships safely', () => {
  const value = sanitizeSearch({
    ...parsedSearch,
    filters: { ...parsedSearch.filters, month: 13, guests: 90, max_price_inr: -5, min_rating: 9, check_in: '2026-02-30', check_out: '2026-01-01' },
  });
  assert(value.filters.month === null && value.filters.guests === null, 'invalid integers were retained');
  assert(value.filters.max_price_inr === null && value.filters.min_rating === null, 'invalid numeric bounds retained');
  assert(value.filters.check_in === null && value.filters.check_out === '2026-01-01', 'invalid ISO date handling failed');
  const outOfOrder = sanitizeSearch({
    ...parsedSearch,
    filters: { ...parsedSearch.filters, check_in: '2026-10-22', check_out: '2026-10-18' },
  });
  assert(outOfOrder.filters.check_in === null && outOfOrder.filters.check_out === null, 'checkout must follow check-in');
  const unsupported = sanitizeSearch({
    ...parsedSearch,
    filters: { ...parsedSearch.filters, city: 'Atlantis', room_types: ['Wi-Fi'], vibes: ['Balcony'] },
  });
  assert(unsupported.filters.city === null, 'unsupported city retained');
  assert(unsupported.filters.room_types.length === 0 && unsupported.filters.vibes.length === 0, 'cross-vocabulary values leaked');
  assert(value.filters.month === null, 'out-of-range month retained');
  assert(sanitizeSearch(parsedSearch).filters.check_in === null, 'month-only input invented exact dates');
  assertThrows(() => sanitizeSearch({ ...parsedSearch, status: 'other' }), 'AI_INVALID_OUTPUT');
});

Deno.test('clarification fields are parsed against canonical cities only', () => {
  const value = sanitizeSearch({
    ...parsedSearch,
    status: 'needs_clarification',
    clarification: { question: 'Which city?', options: ['Mumbai', 'Atlantis'] },
  });
  assert(value.status === 'needs_clarification', 'status not retained');
  assert(value.clarification?.options.join(',') === 'Mumbai', 'unsupported option retained');
});

Deno.test('Gemini schema conversion preserves nullable fields without unsupported anyOf', () => {
  for (const schema of [SEARCH_SCHEMA, INSIGHT_SCHEMA]) {
    const converted = toGeminiJsonSchema(schema) as Record<string, unknown>;
    const serialized = JSON.stringify(converted);
    assert(!serialized.includes('anyOf'), 'unsupported anyOf was not converted');
  }
  const search = toGeminiJsonSchema(SEARCH_SCHEMA) as Record<string, unknown>;
  const properties = ((search.properties as Record<string, unknown>).filters as Record<string, unknown>).properties as Record<string, Record<string, unknown>>;
  assert(JSON.stringify(properties.city.type) === '["string","null"]', 'nullable city type changed');
  assert((properties.city.enum as unknown[]).includes(null), 'nullable city enum must retain null');
});

Deno.test('evidence selection mirrors ranker, excludes unverified and unrelated seasons', async () => {
  const fixture = JSON.parse(await Deno.readTextFile(new URL('./fixtures/review-ranking.json', import.meta.url)));
  const evidence = selectReviewEvidence(fixture.reviews as EvidenceReview[], fixture.month, fixture.year, fixture.room_id);
  assert(evidence.map((item) => item.id).join(',') === fixture.evidence_ids.join(','), 'rank/evidence order drift');
  assert(!evidence.some((item) => item.id === 'oct-unverified'), 'unverified review leaked to model evidence');
  assert(!evidence.some((item) => item.id === 'old-far'), 'unrelated review leaked to evidence');
});

Deno.test('insight output rejects unknown source ids and accepts sourced claims', () => {
  const evidence = [{ id: 'review-1' }, { id: 'review-2' }, { id: 'review-3' }] as EvidenceReview[];
  const body = {
    status: 'ready', title: 'October stay insights', source_count: 3,
    bullets: [
      { text: 'Guests praised the location.', source_review_ids: ['review-1'] },
      { text: 'Several liked the quiet rooms.', source_review_ids: ['review-2', 'review-3'] },
    ], caution: null,
  };
  assert(sanitizeInsights(body, evidence).bullets.length === 2, 'valid insights rejected');
  assertThrows(() => sanitizeInsights({ ...body, bullets: [{ text: 'Unsupported claim', source_review_ids: ['other'] }, body.bullets[1]] }, evidence), 'AI_INVALID_OUTPUT');
});

Deno.test('Gemini generateContent request is mocked, schema constrained and malformed output is rejected', async () => {
  const captured: { body?: Record<string, unknown>; url?: string; headers?: Headers } = {};
  const fetcher: typeof fetch = async (_input, init) => {
    captured.url = String(_input);
    captured.headers = new Headers(init?.headers);
    captured.body = JSON.parse(String(init?.body));
    return new Response(JSON.stringify({ candidates: [{ content: { parts: [{ text: '{"ok":true}' }] } }] }), { status: 200 });
  };
  const schema = { type: 'object', properties: { ok: { type: 'boolean' } } };
  const value = await structuredResponse('fixture', schema, 'instruction', 'input', { apiKey: 'test-only', fetcher });
  assert(value.ok === true, 'mock structured output was not parsed');
  assert(captured.url === 'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.5-flash:generateContent', 'default Gemini model endpoint missing');
  assert(captured.headers?.get('x-goog-api-key') === 'test-only', 'Gemini API-key header missing');
  assert(captured.body?.generationConfig && (captured.body.generationConfig as Record<string, unknown>).responseMimeType === 'application/json', 'JSON response mode missing');
  assert(JSON.stringify((captured.body?.generationConfig as Record<string, unknown>).responseJsonSchema) === JSON.stringify(schema), 'JSON schema was not sent');
  assertThrows(() => parseStructuredPayload({ candidates: [] }), 'AI_INVALID_OUTPUT');
  assertThrows(() => parseStructuredPayload({ candidates: [{ finishReason: 'SAFETY' }] }), 'AI_INVALID_OUTPUT');
  assertThrows(() => parseStructuredPayload({ candidates: [{ content: { parts: [{ text: 'not JSON' }] } }] }), 'AI_INVALID_OUTPUT');
  let failed = false;
  try {
    await structuredResponse('fixture', {}, 'instruction', 'input', {
      apiKey: 'test-only', fetcher: async () => new Response('{}', { status: 429 }),
    });
  } catch (error) { failed = error instanceof AiError && error.code === 'AI_UPSTREAM_ERROR'; }
  assert(failed, 'provider failure was not categorized');
});

Deno.test('insufficient verified evidence skips the model call', async () => {
  let called = false;
  const result = await runInsightIfEvidenceSufficient(
    [{ id: 'one', is_verified: true } as EvidenceReview],
    async () => { called = true; return 'unexpected'; },
  );
  assert(result == null && !called, 'model generation should not run for insufficient evidence');
});
