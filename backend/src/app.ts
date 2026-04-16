import express from "express";
import cors from "cors";
import morgan from "morgan";

import { authRouter } from "./domains/auth/auth.router";
import { usersRouter } from "./domains/users/users.router";
import { scansRouter } from "./domains/scans/scans.router";
import { statsRouter } from "./domains/stats/stats.router";

export const app = express();

// 공통 미들웨어
app.use(cors());
app.use(express.json({ limit: "1mb" }));
app.use(morgan("dev"));

// 헬스체크(배포/모니터링용)
app.get("/health", (_req, res) => res.json({ ok: true }));

// 도메인별 라우팅 진입점
app.use("/api/auth", authRouter);
app.use("/api/users", usersRouter);
app.use("/api/scans", scansRouter);
app.use("/api/stats", statsRouter);

// 기본 404 핸들러(이 아래로 내려오면 라우터 매칭 실패)
app.use((req, res) => {
  res.status(404).json({ message: "Not Found", path: req.path });
});

