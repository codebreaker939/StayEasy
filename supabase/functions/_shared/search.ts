export const CITIES = ['Mumbai', 'Goa', 'Udaipur', 'Manali'] as const;
export const AMENITIES = [
  'Wi-Fi', 'Breakfast', 'Sea view', 'Airport transfer', 'Pool', 'Beach access',
  'Lake view', 'Restaurant', 'Rooftop', 'Mountain view', 'Heating', 'Bonfire',
  'Balcony', 'Air conditioning', 'Living area', 'Pool access',
] as const;
export const ROOM_TYPES = [
  'Queen', 'King', 'Double', 'Twin', 'Suite', 'Family suite', 'Studio',
  'Balcony room', 'Loft', 'Compact room',
] as const;
export const VIBES = [
  'Quiet stay', 'Beach stay', 'Business', 'Luxury', 'Nature', 'Design hotel',
  'Lake view', 'Mountain view', 'Budget', 'Couples',
] as const;

const schemaNullable = (type: string) => ({ anyOf: [{ type }, { type: 'null' }] });
const enumArray = (values: readonly string[]) => ({
  type: 'array', items: { type: 'string', enum: [...values] },
});

export const SEARCH_SCHEMA = {
  type: 'object', additionalProperties: false,
  required: ['status', 'filters', 'clarification'],
  properties: {
    status: { type: 'string', enum: ['parsed', 'needs_clarification'] },
    filters: {
      type: 'object', additionalProperties: false,
      required: ['city', 'month', 'check_in', 'check_out', 'guests', 'max_price_inr', 'min_rating', 'amenities', 'room_types', 'vibes'],
      properties: {
        city: { anyOf: [{ type: 'string', enum: [...CITIES] }, { type: 'null' }] },
        month: schemaNullable('integer'), check_in: schemaNullable('string'), check_out: schemaNullable('string'),
        guests: schemaNullable('integer'), max_price_inr: schemaNullable('number'), min_rating: schemaNullable('number'),
        amenities: enumArray(AMENITIES), room_types: enumArray(ROOM_TYPES), vibes: enumArray(VIBES),
      },
    },
    clarification: {
      anyOf: [{ type: 'null' }, {
        type: 'object', additionalProperties: false, required: ['question', 'options'],
        properties: { question: { type: 'string' }, options: enumArray(CITIES) },
      }],
    },
  },
};

export type SearchFilters = {
  city: string | null; month: number | null; check_in: string | null; check_out: string | null;
  guests: number | null; max_price_inr: number | null; min_rating: number | null;
  amenities: string[]; room_types: string[]; vibes: string[];
};
export type SearchInterpretation = {
  status: 'parsed' | 'needs_clarification'; filters: SearchFilters;
  clarification: { question: string; options: string[] } | null;
};

function canonicalList(value: unknown, allowed: readonly string[], aliases: Record<string, string> = {}): string[] {
  if (!Array.isArray(value)) return [];
  const byKey = new Map(allowed.map((item) => [key(item), item]));
  for (const [alias, value] of Object.entries(aliases)) {
    if (allowed.includes(value)) byKey.set(key(alias), value);
  }
  return [...new Set(value.filter((v): v is string => typeof v === 'string')
    .map((v) => byKey.get(key(v))).filter((v): v is string => Boolean(v)))];
}
function key(value: string): string { return value.toLowerCase().replace(/[^a-z0-9]+/g, ' ').trim(); }
function canonical(value: unknown, allowed: readonly string[]): string | null {
  if (typeof value !== 'string') return null;
  return allowed.find((item) => key(item) === key(value)) ?? null;
}
function isoDate(value: unknown): string | null {
  if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(value)) return null;
  const date = new Date(`${value}T00:00:00Z`);
  return Number.isNaN(date.valueOf()) || date.toISOString().slice(0, 10) !== value ? null : value;
}

export function validateSearchInput(value: unknown): string {
  if (typeof value !== 'string') throw new Error('INVALID_REQUEST');
  const query = value.trim();
  if (!query || query.length > 500) throw new Error('INVALID_REQUEST');
  return query;
}

export function sanitizeSearch(value: Record<string, unknown>): SearchInterpretation {
  if (!['parsed', 'needs_clarification'].includes(String(value.status))) throw new Error('AI_INVALID_OUTPUT');
  if (!value.filters || typeof value.filters !== 'object' || Array.isArray(value.filters)) throw new Error('AI_INVALID_OUTPUT');
  const raw = value.filters as Record<string, unknown>;
  const month = Number.isInteger(raw.month) && Number(raw.month) >= 1 && Number(raw.month) <= 12 ? Number(raw.month) : null;
  const guests = Number.isInteger(raw.guests) && Number(raw.guests) >= 1 && Number(raw.guests) <= 8 ? Number(raw.guests) : null;
  const price = typeof raw.max_price_inr === 'number' && Number.isFinite(raw.max_price_inr) && raw.max_price_inr >= 0 && raw.max_price_inr <= 1_000_000 ? raw.max_price_inr : null;
  const rating = typeof raw.min_rating === 'number' && Number.isFinite(raw.min_rating) && raw.min_rating >= 0 && raw.min_rating <= 5 ? raw.min_rating : null;
  let checkIn = isoDate(raw.check_in), checkOut = isoDate(raw.check_out);
  if (raw.check_in != null && checkIn == null) checkIn = null;
  if (raw.check_out != null && checkOut == null) checkOut = null;
  if (checkIn && checkOut && checkOut <= checkIn) { checkIn = null; checkOut = null; }
  const clarificationRaw = value.clarification;
  const clarification = value.status === 'needs_clarification' && clarificationRaw && typeof clarificationRaw === 'object'
    ? {
      question: typeof (clarificationRaw as Record<string, unknown>).question === 'string' && String((clarificationRaw as Record<string, unknown>).question).trim()
        ? String((clarificationRaw as Record<string, unknown>).question).trim().slice(0, 160) : 'Which city should I search?',
      options: canonicalList((clarificationRaw as Record<string, unknown>).options, CITIES).slice(0, 4),
    }
    : null;
  if (value.status === 'needs_clarification' && clarification == null) throw new Error('AI_INVALID_OUTPUT');
  return {
    status: clarification ? 'needs_clarification' : 'parsed',
    filters: {
      city: canonical(raw.city, CITIES), month, check_in: checkIn, check_out: checkOut, guests,
      max_price_inr: price, min_rating: rating,
      amenities: canonicalList(raw.amenities, AMENITIES, {
        wifi: 'Wi-Fi', 'wireless internet': 'Wi-Fi', wireless: 'Wi-Fi', internet: 'Wi-Fi',
        balconies: 'Balcony', 'private balcony': 'Balcony',
      }), room_types: canonicalList(raw.room_types, ROOM_TYPES),
      vibes: canonicalList(raw.vibes, VIBES),
    },
    clarification,
  };
}
