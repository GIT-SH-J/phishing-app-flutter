import type { Request, Response, NextFunction } from "express";
import jwt from "jsonwebtoken";
import { env } from "../config/env";

export type JwtUser = {
  userId: string;
  role: "USER" | "ADMIN";
};

declare global {
  namespace Express {
    interface Request {
      user?: JwtUser;
    }
  }
}

// 인증이 필요한 라우트에서 사용하는 미들웨어.
// - Authorization: Bearer <token> 형태만 허용
// - 검증 성공 시 req.user에 payload(userId, role)를 담아 다음 핸들러로 전달
export function requireAuth(req: Request, res: Response, next: NextFunction) {
  const header = req.header("authorization");
  if (!header?.startsWith("Bearer ")) {
    return res.status(401).json({ message: "Missing Authorization header" });
  }

  const token = header.slice("Bearer ".length);
  try {
    const payload = jwt.verify(token, env.JWT_ACCESS_SECRET) as JwtUser;
    if (!payload?.userId || !payload?.role) {
      return res.status(401).json({ message: "Invalid token" });
    }
    req.user = payload;
    return next();
  } catch {
    return res.status(401).json({ message: "Invalid token" });
  }
}

