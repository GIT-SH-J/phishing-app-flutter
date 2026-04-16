import { env } from "../config/env";

export type SafeBrowsingUrlResult = {
  url: string;
  isMalicious: boolean;
  threatTypes?: string[];
};

// Google Safe Browsing API(v4) - threatMatches:find 호출 유틸.
// - 입력: URL 리스트
// - 출력: 각 URL의 악성 여부
// 참고: "Update API v4"라는 표현이 섞여 쓰이지만, 일반적으로 서버에서 즉시 판별은
// threatMatches:find 엔드포인트를 사용합니다.
export async function checkUrlsWithSafeBrowsing(
  urls: string[],
): Promise<SafeBrowsingUrlResult[]> {
  const unique = Array.from(
    new Set(urls.map((u) => u.trim()).filter((u) => u.length > 0)),
  );

  if (unique.length === 0) return [];

  const endpoint = `https://safebrowsing.googleapis.com/v4/threatMatches:find?key=${encodeURIComponent(
    env.GOOGLE_SAFE_BROWSING_API_KEY,
  )}`;

  const body = {
    client: {
      clientId: "smishing-backend",
      clientVersion: "0.1.0",
    },
    threatInfo: {
      threatTypes: [
        "MALWARE",
        "SOCIAL_ENGINEERING",
        "UNWANTED_SOFTWARE",
        "POTENTIALLY_HARMFUL_APPLICATION",
      ],
      platformTypes: ["ANY_PLATFORM"],
      threatEntryTypes: ["URL"],
      threatEntries: unique.map((url) => ({ url })),
    },
  };

  const res = await fetch(endpoint, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });

  if (!res.ok) {
    throw Object.assign(new Error("Safe Browsing API request failed"), {
      statusCode: 502,
    });
  }

  const json = (await res.json()) as { matches?: any[] };
  const matches = Array.isArray(json.matches) ? json.matches : [];

  const byUrl = new Map<string, { threatTypes: string[] }>();
  for (const m of matches) {
    const url = m?.threat?.url;
    const t = m?.threatType;
    if (typeof url !== "string") continue;
    if (typeof t !== "string") continue;
    const cur = byUrl.get(url) ?? { threatTypes: [] };
    cur.threatTypes.push(t);
    byUrl.set(url, cur);
  }

  return unique.map((url) => {
    const hit = byUrl.get(url);
    return {
      url,
      isMalicious: Boolean(hit),
      threatTypes: hit?.threatTypes,
    };
  });
}

