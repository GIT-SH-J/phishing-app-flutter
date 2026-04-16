import type { Request, Response } from "express";
import { UsersService } from "./users.service";

type HttpError = Error & { statusCode?: number };

// controller는 인증 미들웨어(requireAuth)가 채워준 req.user를 기반으로 동작합니다.
function getStatusCode(err: unknown, fallback = 500) {
  if (err && typeof err === "object" && "statusCode" in err) {
    const code = (err as HttpError).statusCode;
    if (typeof code === "number") return code;
  }
  return fallback;
}

function toErrorResponse(err: unknown) {
  if (err instanceof Error) return { message: err.message };
  return { message: "Unknown error" };
}

export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  // GET /api/users/me
  me = async (req: Request, res: Response) => {
    try {
      const userId = req.user?.userId;
      if (!userId) return res.status(401).json({ message: "Unauthorized" });

      const result = await this.usersService.getMe(userId);
      return res.status(200).json(result);
    } catch (err) {
      return res.status(getStatusCode(err)).json(toErrorResponse(err));
    }
  };

  // DELETE /api/users/me
  deleteMe = async (req: Request, res: Response) => {
    try {
      const userId = req.user?.userId;
      if (!userId) return res.status(401).json({ message: "Unauthorized" });

      const result = await this.usersService.deleteMe(userId);
      return res.status(200).json(result);
    } catch (err) {
      return res.status(getStatusCode(err)).json(toErrorResponse(err));
    }
  };
}

