import { Router } from "express";
import { requireAuth } from "../../middlewares/auth";

export const statsRouter = Router();

// GET /api/stats/dashboard
statsRouter.get("/dashboard", requireAuth, (_req, res) => {
  res.status(501).json({ message: "Not implemented" });
});

// GET /api/stats/risk-level
statsRouter.get("/risk-level", requireAuth, (_req, res) => {
  res.status(501).json({ message: "Not implemented" });
});

