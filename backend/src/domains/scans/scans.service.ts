import { prisma } from "../../db/prisma";
import { checkUrlsWithSafeBrowsing } from "../../utils/googleSafeBrowsing";

type ScanTextInput = {
  device_id: string;
  content: string;
  source_app?: string;
  sender?: string;
};

type ScanUrlInput = {
  device_id: string;
  url: string;
  source_app?: string;
  sender?: string;
};

function extractUrls(text: string): string[] {
  // 단순 URL 추출(정교한 파서는 추후 교체 가능)
  const regex = /\bhttps?:\/\/[^\s<>"']+/gi;
  return Array.from(text.match(regex) ?? []);
}

function decideFinalGrade(params: {
  isMaliciousBySafeBrowsing: boolean;
  mockAiGrade: "SAFE" | "SUSPICIOUS" | "DANGER";
}): "SAFE" | "SUSPICIOUS" | "DANGER" {
  if (params.isMaliciousBySafeBrowsing) return "DANGER";
  return params.mockAiGrade;
}

async function mockAiPipeline(): Promise<{
  grade: "SAFE" | "SUSPICIOUS" | "DANGER";
  riskScore: number;
  xgboostScore?: number | null;
  kcelectraIntent?: string | null;
  llmGuide?: string | null;
}> {
  // TODO: AI 서버(FastAPI) 연동이 준비되면 아래를 axios/fetch로 호출하도록 교체
  // const res = await axios.post(`${env.AI_BASE_URL}/...`, payload)
  // return res.data
  return {
    grade: "SAFE",
    riskScore: 0,
    xgboostScore: null,
    kcelectraIntent: null,
    llmGuide: null,
  };
}

export class ScansService {
  // text 스캔: 메시지 원문에서 URL을 추출하고 파이프라인을 수행합니다.
  async scanText(params: {
    input: ScanTextInput;
    userId?: string | null;
  }) {
    const { input } = params;
    const urls = extractUrls(input.content);
    return this.runPipeline({
      userId: params.userId ?? null,
      deviceId: input.device_id,
      content: input.content,
      sourceApp: input.source_app ?? null,
      sender: input.sender ?? null,
      extractedUrls: urls,
    });
  }

  // URL 단독 검사: URL 1개를 파이프라인으로 돌립니다(원문은 url로 저장).
  async scanUrl(params: { input: ScanUrlInput; userId?: string | null }) {
    const { input } = params;
    const urls = [input.url];
    return this.runPipeline({
      userId: params.userId ?? null,
      deviceId: input.device_id,
      content: input.url,
      sourceApp: input.source_app ?? null,
      sender: input.sender ?? null,
      extractedUrls: urls,
    });
  }

  private async runPipeline(args: {
    userId: string | null;
    deviceId: string;
    content: string;
    sourceApp: string | null;
    sender: string | null;
    extractedUrls: string[];
  }) {
    // message_logs.device_id는 devices.device_id를 FK로 참조합니다.
    // 따라서 message_logs를 저장하기 전에 device 레코드가 반드시 존재해야 합니다.
    await prisma.device.upsert({
      where: { deviceId: args.deviceId },
      create: {
        deviceId: args.deviceId,
        userId: args.userId ? BigInt(args.userId) : null,
      },
      update: {
        // 게스트로 먼저 사용하다가 로그인한 경우, userId를 연결해줄 수 있습니다.
        userId: args.userId ? BigInt(args.userId) : undefined,
      },
      select: { deviceId: true },
    });

    // 1단계: message_logs 저장
    const log = await prisma.messageLog.create({
      data: {
        userId: args.userId ? BigInt(args.userId) : null,
        deviceId: args.deviceId,
        sourceApp: args.sourceApp,
        sender: args.sender,
        content: args.content,
        hasUrl: args.extractedUrls.length > 0,
      },
      select: { id: true },
    });

    // 2단계: Google Safe Browsing URL 검사 (URL이 있을 때만)
    const safeBrowsingResults =
      args.extractedUrls.length > 0
        ? await checkUrlsWithSafeBrowsing(args.extractedUrls)
        : [];

    const isMaliciousBySafeBrowsing = safeBrowsingResults.some(
      (r) => r.isMalicious,
    );

    // 3~4단계: AI 서버(미구현) → Mock으로 대체
    const ai = await mockAiPipeline();

    // 5단계: detection_results 저장 + 최종 등급 결정
    const finalRiskGrade = decideFinalGrade({
      isMaliciousBySafeBrowsing,
      mockAiGrade: ai.grade,
    });

    const step1Safebrowsing: "CLEAN" | "MALICIOUS" | null =
      args.extractedUrls.length === 0
        ? null
        : isMaliciousBySafeBrowsing
          ? "MALICIOUS"
          : "CLEAN";

    const detection = await prisma.detectionResult.create({
      data: {
        logId: log.id,
        extractedUrls:
          args.extractedUrls.length > 0 ? JSON.stringify(args.extractedUrls) : null,
        step1Safebrowsing,
        step2XgboostScore: ai.xgboostScore ?? null,
        step3KcelectraIntent: ai.kcelectraIntent ?? null,
        finalRiskScore: ai.riskScore,
        finalRiskGrade,
        llmResponseGuide: ai.llmGuide ?? null,
      },
      select: {
        id: true,
        logId: true,
        step1Safebrowsing: true,
        finalRiskScore: true,
        finalRiskGrade: true,
        analyzedAt: true,
      },
    });

    return {
      log_id: log.id.toString(),
      result_id: detection.id.toString(),
      extracted_urls: args.extractedUrls,
      safe_browsing: safeBrowsingResults,
      final_risk_grade: detection.finalRiskGrade,
      final_risk_score: detection.finalRiskScore,
      analyzed_at: detection.analyzedAt,
    };
  }
}

