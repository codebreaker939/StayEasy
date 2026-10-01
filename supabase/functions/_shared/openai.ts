export class AiError extends Error {
  readonly code: 'AI_NOT_CONFIGURED' | 'AI_UPSTREAM_ERROR' | 'AI_INVALID_OUTPUT';
  constructor(code: 'AI_NOT_CONFIGURED' | 'AI_UPSTREAM_ERROR' | 'AI_INVALID_OUTPUT') {
    super(code);
    this.code = code;
  }
}

export async function structuredResponse(
  name: string,
  schema: Record<string, unknown>,
  instructions: string,
  input: string,
  options: { apiKey?: string; model?: string; fetcher?: typeof fetch } = {},
): Promise<Record<string, unknown>> {
  const key = options.apiKey?.trim() || Deno.env.get('OPENAI_API_KEY')?.trim();
  if (!key) throw new AiError('AI_NOT_CONFIGURED');
  const model = options.model?.trim() || Deno.env.get('OPENAI_MODEL')?.trim() || 'gpt-5.6-luna';
  let response: Response;
  try {
    response = await (options.fetcher ?? fetch)('https://api.openai.com/v1/responses', {
      method: 'POST',
      signal: AbortSignal.timeout(20_000),
      headers: { Authorization: `Bearer ${key}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model,
        store: false,
        max_output_tokens: 900,
        instructions,
        input,
        text: {
          format: { type: 'json_schema', name, strict: true, schema },
        },
      }),
    });
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
    if (!payload || typeof payload !== 'object') throw new Error('missing response object');
    const output = (payload as { output?: Array<{ content?: Array<{ type?: string; text?: string }> }> }).output;
    const outputText = output?.flatMap((item) => item.content ?? [])
      .find((item) => item.type === 'output_text')?.text;
    if (typeof outputText !== 'string') throw new Error('missing output_text');
    const parsed: unknown = JSON.parse(outputText);
    if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) throw new Error('not an object');
    return parsed as Record<string, unknown>;
  } catch {
    throw new AiError('AI_INVALID_OUTPUT');
  }
}
