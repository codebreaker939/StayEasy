export const REVIEW_WEIGHTS = {
  sameMonth: 100, nearbySeason: 45, exactRoom: 35, verified: 15,
  helpfulnessPerTen: 1, recencyPerYear: 3,
} as const;

export type EvidenceReview = {
  id: string; rating: number; stay_date: string | null; created_at: string;
  room_id: string | null; title: string | null; body: string | null;
  helpful_count: number; is_verified: boolean;
};

export function scoreReview(review: EvidenceReview, month: number, year: number, roomId: string | null): number {
  const date = review.stay_date ? new Date(`${review.stay_date}T00:00:00Z`) : new Date(review.created_at);
  if (Number.isNaN(date.valueOf())) return 0;
  const diff = Math.abs(date.getUTCMonth() + 1 - month);
  const circular = diff > 6 ? 12 - diff : diff;
  const seasonal = circular === 0 ? REVIEW_WEIGHTS.sameMonth : circular <= 2 ? REVIEW_WEIGHTS.nearbySeason : 0;
  const room = roomId && review.room_id === roomId ? REVIEW_WEIGHTS.exactRoom : 0;
  const verified = review.is_verified ? REVIEW_WEIGHTS.verified : 0;
  const helpful = Math.floor(Math.max(0, review.helpful_count) / 10) * REVIEW_WEIGHTS.helpfulnessPerTen;
  const age = Math.min(10, Math.max(0, year - date.getUTCFullYear()));
  return seasonal + room + verified + helpful + 10 - age * REVIEW_WEIGHTS.recencyPerYear;
}

export function selectReviewEvidence(
  reviews: EvidenceReview[], month: number, year: number, roomId: string | null, limit = 8,
): EvidenceReview[] {
  return reviews.filter((review) => {
    if (!review.is_verified || !review.body?.trim()) return false;
    const date = review.stay_date ? new Date(`${review.stay_date}T00:00:00Z`) : new Date(review.created_at);
    if (Number.isNaN(date.valueOf())) return false;
    const diff = Math.abs(date.getUTCMonth() + 1 - month);
    const circularDistance = diff > 6 ? 12 - diff : diff;
    return circularDistance <= 2 || Boolean(roomId && review.room_id === roomId);
  })
    .map((review, index) => ({ review, index, score: scoreReview(review, month, year, roomId) }))
    .sort((a, b) => b.score - a.score || (a.review.id < b.review.id ? -1 : a.review.id > b.review.id ? 1 : a.index - b.index))
    .slice(0, limit)
    .map(({ review }) => ({
      id: review.id, rating: review.rating, stay_date: review.stay_date,
      created_at: review.created_at, room_id: review.room_id,
      title: review.title == null ? null : review.title.slice(0, 120),
      body: review.body == null ? null : review.body.slice(0, 1200),
      helpful_count: review.helpful_count,
      is_verified: review.is_verified,
    }));
}

export async function runInsightIfEvidenceSufficient<T>(
  evidence: EvidenceReview[],
  generate: () => Promise<T>,
): Promise<T | null> {
  if (evidence.length < 3) return null;
  return await generate();
}

const array = (item: { type: string }) => ({ type: 'array', items: item });
const bullet = {
  type: 'object', additionalProperties: false, required: ['text', 'source_review_ids'],
  properties: { text: { type: 'string' }, source_review_ids: array({ type: 'string' }) },
};
export const INSIGHT_SCHEMA = {
  type: 'object', additionalProperties: false,
  required: ['status', 'title', 'bullets', 'caution', 'source_count'],
  properties: {
    status: { type: 'string', enum: ['ready', 'insufficient_evidence'] },
    title: { type: 'string' }, bullets: array(bullet),
    caution: { anyOf: [{ type: 'null' }, bullet] }, source_count: { type: 'integer' },
  },
};

export type InsightOutput = {
  status: 'ready' | 'insufficient_evidence'; title: string;
  bullets: { text: string; source_review_ids: string[] }[];
  caution: { text: string; source_review_ids: string[] } | null; source_count: number;
};

export function sanitizeInsights(value: Record<string, unknown>, evidence: EvidenceReview[]): InsightOutput {
  const ids = new Set(evidence.map((item) => item.id));
  const sourceCount = Number(value.source_count);
  if (!Number.isInteger(sourceCount) || sourceCount !== evidence.length) throw new Error('AI_INVALID_OUTPUT');
  const normalize = (item: unknown) => {
    if (!item || typeof item !== 'object') return null;
    const row = item as Record<string, unknown>;
    if (typeof row.text !== 'string' || !row.text.trim() || row.text.length > 240 || !Array.isArray(row.source_review_ids)) {
      throw new Error('AI_INVALID_OUTPUT');
    }
    const sources = row.source_review_ids;
    if (sources.length === 0 || sources.some((id) => typeof id !== 'string' || !ids.has(id))) {
      throw new Error('AI_INVALID_OUTPUT');
    }
    return { text: row.text.trim(), source_review_ids: [...new Set(sources as string[])] };
  };
  const status = value.status === 'ready' ? 'ready' : value.status === 'insufficient_evidence' ? 'insufficient_evidence' : null;
  if (!status) throw new Error('AI_INVALID_OUTPUT');
  const bullets = Array.isArray(value.bullets) ? value.bullets.map(normalize) : null;
  if (!bullets || bullets.some((item) => item == null)) throw new Error('AI_INVALID_OUTPUT');
  if (status === 'ready' && (bullets.length < 2 || bullets.length > 3)) throw new Error('AI_INVALID_OUTPUT');
  if (status === 'insufficient_evidence' && (bullets.length !== 0 || value.caution != null)) throw new Error('AI_INVALID_OUTPUT');
  const title = typeof value.title === 'string' && value.title.trim() ? value.title.trim().slice(0, 80) : 'Stay insights';
  return { status, title, bullets: bullets as InsightOutput['bullets'], caution: value.caution == null ? null : normalize(value.caution), source_count: sourceCount };
}

export function monthContext(body: Record<string, unknown>): { month: number; year: number; roomId: string | null } {
  const stayDate = typeof body.stay_date === 'string' ? body.stay_date : null;
  const date = stayDate && /^\d{4}-\d{2}-\d{2}$/.test(stayDate) ? new Date(`${stayDate}T00:00:00Z`) : null;
  if (stayDate && (!date || Number.isNaN(date.valueOf()) || date.toISOString().slice(0, 10) !== stayDate)) throw new Error('INVALID_REQUEST');
  const month = date && !Number.isNaN(date.valueOf()) ? date.getUTCMonth() + 1 : Number(body.month);
  const year = date && !Number.isNaN(date.valueOf()) ? date.getUTCFullYear() : Number(body.year);
  if (!Number.isInteger(month) || month < 1 || month > 12 || !Number.isInteger(year) || year < 2000 || year > 2100) throw new Error('INVALID_REQUEST');
  const roomId = body.room_id == null ? null : typeof body.room_id === 'string' && /^[0-9a-f-]{36}$/i.test(body.room_id) ? body.room_id : null;
  if (body.room_id != null && roomId == null) throw new Error('INVALID_REQUEST');
  return { month, year, roomId };
}
