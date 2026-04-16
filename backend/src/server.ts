import { app } from "./app";
import { env } from "./config/env";

// 서버 엔트리 포인트.
// - env.ts에서 환경변수를 검증/파싱하고
// - app.ts에서 라우터/미들웨어를 구성한 뒤
// - 여기서 실제 포트를 열어 요청을 받습니다.
app.listen(env.PORT, () => {
  // eslint-disable-next-line no-console
  console.log(`[api] listening on :${env.PORT} (${env.NODE_ENV})`);
});

