import type { Request, Response } from "express";
import { AuthService } from "./auth.service";

type HttpError = Error & { statusCode?: number };

// controller는 HTTP 레이어를 담당합니다.
// - service의 메서드를 호출하고
// - 성공/실패에 맞는 HTTP status + JSON 응답을 만들어 반환합니다.
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

export class AuthController {
  constructor(private readonly authService: AuthService) {}

  // POST /api/auth/signup
  signup = async (req: Request, res: Response) => {
    try {
      const result = await this.authService.signup(req.body);
      return res.status(201).json(result);
    } catch (err) {
      return res.status(getStatusCode(err)).json(toErrorResponse(err));
    }
  };

  // POST /api/auth/login
  login = async (req: Request, res: Response) => {
    try {
      const result = await this.authService.login(req.body);
      return res.status(200).json(result);
    } catch (err) {
      return res.status(getStatusCode(err)).json(toErrorResponse(err));
    }
  };

  // POST /api/auth/oauth
  oauth = async (req: Request, res: Response) => {
    try {
      const result = await this.authService.oauth(req.body);
      return res.status(200).json(result);
    } catch (err) {
      return res.status(getStatusCode(err)).json(toErrorResponse(err));
    }
  };
}

