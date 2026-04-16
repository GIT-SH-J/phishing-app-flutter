import type { Request, Response, NextFunction } from "express";
import { redis } from "../db/redis";

// 비로그인 스캔 요청에서 device_id를 뽑아내는 로직.
// - 클라이언트가 어느 방식으로 보내도(헤더/바디/쿼리) 동작하도록 유연하게 처리합니다.
function getDeviceId(req: Request): string | null {
  const headerId = req.header("x-device-id") ?? req.header("device_id");
  const bodyId =
    (req.body && (req.body.device_id || req.body.deviceId)) ?? undefined;
  const queryId =
    (req.query && (req.query.device_id || req.query.deviceId)) ?? undefined;

  const id = headerId ?? bodyId ?? queryId;
  if (typeof id !== "string" || id.trim().length === 0) return null;
  return id.trim();
}

function todayKey(deviceId: string) {
  const today = new Date().toISOString().slice(0, 10); // YYYY-MM-DD (UTC)
  return `guest:scan:${deviceId}:${today}`;
}

export async function guestLimit(req: Request, res: Response, next: NextFunction) {
  const deviceId = getDeviceId(req);
  if (!deviceId) return res.status(400).json({ message: "Missing device_id" });

  // 하루 3회 제한.
  // - Redis INCR로 카운트하고, 첫 요청일 때만 TTL(24h)을 설정합니다.
  const key = todayKey(deviceId);
  try {
    const count = await redis.incr(key);
    if (count === 1) {
      await redis.expire(key, 60 * 60 * 24);
    }

    if (count > 3) {
      return res.status(403).json({ message: "Guest limit exceeded (max 3/day)" });
    }

    return next();
  } catch {
    return res.status(500).json({ message: "Redis error" });
  }
}

