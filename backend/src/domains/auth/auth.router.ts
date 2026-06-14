import { Router } from "express";
import { AuthController } from "./auth.controller";
import { AuthService } from "./auth.service";
import axios from "axios";
import jwt from "jsonwebtoken";

export const authRouter = Router();

// 아주 단순한 형태의 "수동 DI(의존성 주입)".
// 규모가 커지면 컨테이너(tsyringe 등)로 대체할 수 있습니다.
const authController = new AuthController(new AuthService());

// POST /api/auth/signup
authRouter.post("/signup", authController.signup);

// POST /api/auth/login
authRouter.post("/login", authController.login);

// POST /api/auth/oauth
authRouter.post("/oauth", authController.oauth);


authRouter.get("/kakao", (req, res) => {

  const KAKAO_CLIENT_ID = "YOUR_CL_ID"; 
  const KAKAO_REDIRECT_URI = "https://smishing-team012.duckdns.org/api/auth/kakao/callback"; 
  const kakaoUrl = `https://kauth.kakao.com/oauth/authorize?client_id=${KAKAO_CLIENT_ID}&redirect_uri=${KAKAO_REDIRECT_URI}&response_type=code`;
  res.redirect(kakaoUrl);

});

authRouter.get("/naver", (req, res) => {

  const NAVER_CLIENT_ID = "YOUR_CL_ID"; 
  const NAVER_REDIRECT_URI = "https://smishing-team012.duckdns.org/api/auth/naver/callback"; 
  const state = Math.random().toString(36).substring(3, 14); 
  const naverUrl = `https://nid.naver.com/oauth2.0/authorize?response_type=code&client_id=${NAVER_CLIENT_ID}&redirect_uri=${NAVER_REDIRECT_URI}&state=${state}`;
  res.redirect(naverUrl);

});


authRouter.get("/google", (req, res) => {
  
  const GOOGLE_CLIENT_ID = "YOUR_CL_ID";
  const GOOGLE_REDIRECT_URI = "https://smishing-team012.duckdns.org/api/auth/google/callback";
  const params = new URLSearchParams({
    client_id: GOOGLE_CLIENT_ID,
    redirect_uri: GOOGLE_REDIRECT_URI,
    response_type: "code",
    scope: "email profile",
    prompt: "select_account" 
  });

  const googleUrl = `https://accounts.google.com/o/oauth2/v2/auth?${params.toString()}`;
  res.redirect(googleUrl);
});


authRouter.get("/google/callback", async (req, res) => {
  const { code } = req.query;
  
  if (!code) {
    return res.redirect("smishingapp://login-fail"); 
  }

  try {
    const tokenResponse = await axios.post("https://oauth2.googleapis.com/token", {
      code,
      client_id: "665177675693-vtn9l8fhq42gp2687bsu2387sl07lj7s.apps.googleusercontent.com",
      client_secret: "YOUR_GOOGLE_CLIENT_SECRET", 
      redirect_uri: "https://smishing-team012.duckdns.org/api/auth/google/callback",
      grant_type: "authorization_code",
    });

    const { id_token } = tokenResponse.data;
    const decodedToken: any = jwt.decode(id_token);
    const email = decodedToken.email;
    const name = decodedToken.name || email.split("@")[0];
    const appToken = "mock_jwt_token_or_server_generated_token"; 
    const encodedName = encodeURIComponent(name);
    const encodedEmail = encodeURIComponent(email);

    return res.redirect(`smishingapp://login-success?token=${appToken}&platform=google&name=${encodedName}&email=${encodedEmail}`);

  } catch (error) {
    console.error("구글 인증 오류:", error);
    return res.redirect("smishingapp://login-fail");
  }
});

authRouter.get("/kakao/callback", async (req, res) => {
  const { code } = req.query;
  if (!code) return res.redirect("smishingapp://login-fail");

  try {
    // 카카오 토큰 및 프로필 조회 로직 처리 후 자체 토큰(appToken), name, email 획득 과정 생략
    const appToken = "server_generated_kakao_token";
    const name = encodeURIComponent("카카오사용자");
    const email = encodeURIComponent("kakao@email.com");

    // 플러터 앱 호출
    return res.redirect(`smishingapp://login-success?token=${appToken}&platform=kakao&name=${name}&email=${email}`);
  } catch (e) {
    return res.redirect("smishingapp://login-fail");
  }
});

authRouter.get("/naver/callback", async (req, res) => {
  const { code } = req.query;
  if (!code) return res.redirect("smishingapp://login-fail");

  try {
    const appToken = "server_generated_naver_token";
    const name = encodeURIComponent("네이버사용자");
    const email = encodeURIComponent("naver@email.com");

    return res.redirect(`smishingapp://login-success?token=${appToken}&platform=naver&name=${name}&email=${email}`);
  } catch (e) {
    return res.redirect("smishingapp://login-fail");
  }
});
