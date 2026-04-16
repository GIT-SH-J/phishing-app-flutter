import Redis from "ioredis";
import { env } from "../config/env";

// ioredis 클라이언트.
// - guestLimit(비로그인 호출 제한) 같은 기능에서 사용합니다.
// - 연결 정보는 env.ts를 통해 환경변수에서 주입합니다.
export const redis = new Redis(env.REDIS_URL, {
  maxRetriesPerRequest: 3,
  enableReadyCheck: true,
});

