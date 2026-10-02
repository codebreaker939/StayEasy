export class AiError extends Error {
  readonly code:
    | "AI_NOT_CONFIGURED"
    | "AI_UPSTREAM_ERROR"
    | "AI_INVALID_OUTPUT";
  constructor(
    code: "AI_NOT_CONFIGURED" | "AI_UPSTREAM_ERROR" | "AI_INVALID_OUTPUT",
  ) {
    super(code);
    this.code = code;
  }
}

/** Convert nullable JSON Schema anyOf forms into Gemini's supported type union form. */
export function toGeminiJsonSchema(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(toGeminiJsonSchema);
  if (!value || typeof value !== "object") return value;

  const schema = value as Record<string, unknown>;
  if (Array.isArray(schema.anyOf) && schema.anyOf.length === 2) {
    const nullIndex = schema.anyOf.findIndex((branch) =>
      branch && typeof branch === "object" &&
      (branch as Record<string, unknown>).type === "null"
    );
    if (nullIndex >= 0) {
      const other = toGeminiJsonSchema(schema.anyOf[1 - nullIndex]) as Record<
        string,
        unknown
      >;
      if (!other || typeof other.type !== "string") {
        throw new AiError("AI_INVALID_OUTPUT");
      }
      return {
        ...other,
        type: [other.type, "null"],
        ...(Array.isArray(other.enum) ? { enum: [...other.enum, null] } : {}),
      };
    }
    throw new AiError("AI_INVALID_OUTPUT");
  }

  return Object.fromEntries(
    Object.entries(schema).map((
      [key, child],
    ) => [key, toGeminiJsonSchema(child)]),
  );
}

export async function structuredResponse(
  _name: string,
  schema: Record<string, unknown>,
  instructions: string,
  input: string,
  options: {
    apiKey?: string;
    model?: string;
    fetcher?: typeof fetch;
    sleeper?: (milliseconds: number) => Promise<void>;
    random?: () => number;
  } = {},
): Promise<Record<string, unknown>> {
  const key = options.apiKey?.trim() || Deno.env.get("GEMINI_API_KEY")?.trim();
  if (!key) throw new AiError("AI_NOT_CONFIGURED");

  const model = options.model?.trim() || Deno.env.get("GEMINI_MODEL")?.trim() ||
    "gemini-3.5-flash";
  if (!/^[A-Za-z0-9.-]+$/.test(model)) throw new AiError("AI_UPSTREAM_ERROR");

  const startedAt = Date.now();
  const fetcher = options.fetcher ?? fetch;
  const sleeper = options.sleeper ??
    ((milliseconds) =>
      new Promise<void>((resolve) => setTimeout(resolve, milliseconds)));
  const random = options.random ?? Math.random;
  let response: Response | null = null;

  for (let attempt = 0; attempt < 3; attempt += 1) {
    try {
      response = await fetcher(
        `https://generativelanguage.googleapis.com/v1beta/models/${
          encodeURIComponent(model)
        }:generateContent`,
        {
          method: "POST",
          signal: AbortSignal.timeout(20_000),
          headers: {
            "Content-Type": "application/json",
            "x-goog-api-key": key,
          },
          body: JSON.stringify({
            systemInstruction: { parts: [{ text: instructions }] },
            contents: [{ role: "user", parts: [{ text: input }] }],
            generationConfig: {
              maxOutputTokens: 900,
              responseMimeType: "application/json",
              responseJsonSchema: toGeminiJsonSchema(schema),
            },
          }),
        },
      );
    } catch {
      if (attempt < 2) {
        await sleeper(retryDelayMs(attempt, null, random));
        continue;
      }
      console.error(JSON.stringify({
        event: "gemini_provider_failure",
        kind: "network",
        reason: "fetch_failed",
        attempts: attempt + 1,
        duration_ms: Date.now() - startedAt,
      }));
      throw new AiError("AI_UPSTREAM_ERROR");
    }

    if (response.ok) break;
    const reason = await providerReason(response);
    if (isRetryableStatus(response.status) && attempt < 2) {
      await sleeper(
        retryDelayMs(attempt, response.headers.get("retry-after"), random),
      );
      response = null;
      continue;
    }
    console.error(JSON.stringify({
      event: "gemini_provider_failure",
      kind: "http",
      status: response.status,
      reason,
      attempts: attempt + 1,
      duration_ms: Date.now() - startedAt,
    }));
    throw new AiError("AI_UPSTREAM_ERROR");
  }

  if (!response?.ok) throw new AiError("AI_UPSTREAM_ERROR");
  try {
    return parseStructuredPayload(await response.json());
  } catch {
    throw new AiError("AI_INVALID_OUTPUT");
  }
}

function isRetryableStatus(status: number): boolean {
  return [429, 500, 502, 503, 504].includes(status);
}

function retryDelayMs(
  attempt: number,
  retryAfter: string | null,
  random: () => number,
): number {
  const retryAfterSeconds = Number(retryAfter);
  if (
    retryAfter != null &&
    Number.isFinite(retryAfterSeconds) &&
    retryAfterSeconds >= 0
  ) {
    return Math.min(2_000, Math.round(retryAfterSeconds * 1_000));
  }
  const base = attempt === 0 ? 300 : 900;
  return Math.round(base * (0.8 + Math.min(1, Math.max(0, random())) * 0.4));
}

async function providerReason(response: Response): Promise<string | null> {
  try {
    const payload = await response.json() as {
      error?: { status?: unknown; code?: unknown };
    };
    const error = payload?.error;
    return typeof error?.status === "string"
      ? error.status
      : typeof error?.code === "string"
      ? error.code
      : null;
  } catch {
    return null;
  }
}

export function parseStructuredPayload(
  payload: unknown,
): Record<string, unknown> {
  try {
    if (!payload || typeof payload !== "object" || Array.isArray(payload)) {
      throw new Error("missing response object");
    }
    const candidates = (payload as {
      candidates?: Array<{
        content?: { parts?: Array<{ text?: unknown }> };
        finishReason?: string;
      }>;
    }).candidates;
    const candidate = candidates?.find((item) =>
      item.finishReason !== "SAFETY" && item.finishReason !== "RECITATION"
    );
    const outputText = candidate?.content?.parts
      ?.map((part) => part.text)
      .filter((part): part is string =>
        typeof part === "string" && part.trim().length > 0
      )
      .join("")
      .trim();
    if (!outputText) throw new Error("missing candidate text");
    const parsed: unknown = JSON.parse(outputText);
    if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
      throw new Error("not a JSON object");
    }
    return parsed as Record<string, unknown>;
  } catch {
    throw new AiError("AI_INVALID_OUTPUT");
  }
}
