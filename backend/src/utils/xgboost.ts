import { env } from "../config/env";

export type XgboostVerdict = "safe" | "suspicious" | "malicious";

export type XgboostUrlResult = {
  url: string;
  score: number;
  verdict: XgboostVerdict;
  pipeline?: string;
  warnings?: string[];
};

type XgboostApiResponse = {
  url?: unknown;
  score?: unknown;
  verdict?: unknown;
  pipeline?: unknown;
  warnings?: unknown;
};

function normalizeVerdict(input: unknown): XgboostVerdict {
  if (input === "malicious") return "malicious";
  if (input === "suspicious") return "suspicious";
  return "safe";
}

function normalizeScore(input: unknown): number {
  const n = Number(input);
  if (!Number.isFinite(n)) return 0;
  if (n < 0) return 0;
  if (n > 1) return 1;
  return n;
}

async function checkUrlWithXgboost(params: {
  url: string;
  sourceApp?: string;
  messageText?: string;
}): Promise<XgboostUrlResult> {
  const endpoint = `${env.AI_BASE_URL.replace(/\/+$/, "")}/predict`;

  const res = await fetch(endpoint, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      url: params.url,
      sourceApp: params.sourceApp ?? null,
      messageText: params.messageText ?? null,
    }),
  });

  if (!res.ok) {
    throw Object.assign(new Error("XGBoost API request failed"), {
      statusCode: 502,
    });
  }

  const json = (await res.json()) as XgboostApiResponse;

  return {
    url: typeof json.url === "string" && json.url.length > 0 ? json.url : params.url,
    score: normalizeScore(json.score),
    verdict: normalizeVerdict(json.verdict),
    pipeline: typeof json.pipeline === "string" ? json.pipeline : undefined,
    warnings: Array.isArray(json.warnings)
      ? json.warnings.filter((w): w is string => typeof w === "string")
      : undefined,
  };
}

export async function checkUrlsWithXgboost(
  urls: string[],
  context?: {
    sourceApp?: string | null;
    messageText?: string | null;
  },
): Promise<XgboostUrlResult[]> {
  const unique = Array.from(
    new Set(urls.map((u) => u.trim()).filter((u) => u.length > 0)),
  );

  if (unique.length === 0) return [];

  return Promise.all(
    unique.map((url) =>
      checkUrlWithXgboost({
        url,
        sourceApp: context?.sourceApp ?? undefined,
        messageText: context?.messageText ?? undefined,
      }),
    ),
  );
}
