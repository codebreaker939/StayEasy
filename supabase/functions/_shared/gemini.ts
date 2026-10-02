export class AiError extends Error {
  readonly code: 'AI_NOT_CONFIGURED' | 'AI_UPSTREAM_ERROR' | 'AI_INVALID_OUTPUT';
  constructor(code: 'AI_NOT_CONFIGURED' | 'AI_UPSTREAM_ERROR' | 'AI_INVALID_OUTPUT') {
    super(code);
    this.code = code;
  }
}

/** Convert nullable JSON Schema anyOf forms into Gemini's supported type union form. */
export function toGeminiJsonSchema(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(toGeminiJsonSchema);
  if (!value || typeof value !== 'object') return value;

  const schema = value as Record<string, unknown>;
  if (Array.isArray(schema.anyOf) && schema.anyOf.length === 2) {
    const nullIndex = schema.anyOf.findIndex((branch) =>
      branch && typeof branch === 'object' && (branch as Record<string, unknown>).type === 'null'
    );
    if (nullIndex >= 0) {
      const other = toGeminiJsonSchema(schema.anyOf[1 - nullIndex]) as Record<string, unknown>;
      if (!other || typeof other.type !== 'string') throw new AiError('AI_INVALID_OUTPUT');
      return {
        ...other,
        type: [other.type, 'null'],
        ...(Array.isArray(other.enum) ? { enum: [...other.enum, null] } : {}),
      };
    }
    throw new AiError('AI_INVALID_OUTPUT');
  }

  return Object.fromEntries(Object.entries(schema).map(([key, child]) => [key, toGeminiJsonSchema(child)]));
}

export async function structuredResponse(
  _name: string,
  schema: Record<string, unknown>,
  instructions: string,
  input: string,
  options: { apiKey?: string; model?: string; fetcher?: typeof fetch } = {},
): Promise<Record<string, unknown>> {
  const key = options.apiKey?.trim() || Deno.env.get('GEMINI_API_KEY')?.trim();
  if (!key) throw new AiError('AI_NOT_CONFIGURED');

  const model = options.model?.trim() || Deno.env.get('GEMINI_MODEL')?.trim() || 'gemini-3.5-flash';
  if (!/^[A-Za-z0-9.-]+$/.test(model)) throw new AiError('AI_UPSTREAM_ERROR');

  let response: Response;
  try {
    response = await (options.fetcher ?? fetch)(
      `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent`,
      {
        method: 'POST',
        signal: AbortSignal.timeout(20_000),
        headers: { 'Content-Type': 'application/json', 'x-goog-api-key': key },
        body: JSON.stringify({
          systemInstruction: { parts: [{ text: instructions }] },
          contents: [{ role: 'user', parts: [{ text: input }] }],
          generationConfig: {
            maxOutputTokens: 900,
            responseMimeType: 'application/json',
            responseJsonSchema: toGeminiJsonSchema(schema),
          },
        }),
      },
    );
  } catch {
    throw new AiError('AI_UPSTREAM_ERROR');
  }

  if (!response.ok) throw new AiError('AI_UPSTREAM_ERROR');
  try {
    return parseStructuredPayload(await response.json());
  } catch {
    throw new AiError('AI_INVALID_OUTPUT');
  }
}

export function parseStructuredPayload(payload: unknown): Record<string, unknown> {
  try {
    if (!payload || typeof payload !== 'object' || Array.isArray(payload)) {
      throw new Error('missing response object');
    }
    const candidates = (payload as {
      candidates?: Array<{
        content?: { parts?: Array<{ text?: unknown }> };
        finishReason?: string;
      }>;
    }).candidates;
    const candidate = candidates?.find((item) => item.finishReason !== 'SAFETY' && item.finishReason !== 'RECITATION');
    const outputText = candidate?.content?.parts
      ?.map((part) => part.text)
      .filter((part): part is string => typeof part === 'string' && part.trim().length > 0)
      .join('')
      .trim();
    if (!outputText) throw new Error('missing candidate text');
    const parsed: unknown = JSON.parse(outputText);
    if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) {
      throw new Error('not a JSON object');
    }
    return parsed as Record<string, unknown>;
  } catch {
    throw new AiError('AI_INVALID_OUTPUT');
  }
}
