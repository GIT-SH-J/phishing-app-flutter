import { z } from "zod";
import "dotenv/config";

// 환경변수는 런타임에서 가장 먼저 검증되어야 합니다.
// - 잘못된 설정(예: JWT secret 길이 부족, REDIS_URL 누락)이면 서버가 즉시 실패하도록 해서
//   배포/운영 중에 애매한 오류가 생기는 걸 방지합니다.
const envSchema = z.object({
  PORT: z.coerce.number().int().positive().default(4000),
  NODE_ENV: z.enum(["development", "test", "production"]).default("development"),
  DATABASE_URL: z.string().min(1),
  REDIS_URL: z.string().min(1),
  GOOGLE_SAFE_BROWSING_API_KEY: z.string().min(1),
  AI_BASE_URL: z.string().url(),
  JWT_ACCESS_SECRET: z.string().min(16),
  JWT_ACCESS_EXPIRES_IN: z.string().min(1).default("15m"),
});

export const env = envSchema.parse(process.env);

