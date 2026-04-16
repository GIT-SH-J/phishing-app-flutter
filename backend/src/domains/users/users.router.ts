import { Router } from "express";
import { requireAuth } from "../../middlewares/auth";
import { UsersController } from "./users.controller";
import { UsersService } from "./users.service";

export const usersRouter = Router();

// 단순 DI
const usersController = new UsersController(new UsersService());

// GET /api/users/guest
usersRouter.get("/guest", (_req, res) => {
  res.status(501).json({ message: "Not implemented" });
});

// GET /api/users/me
usersRouter.get("/me", requireAuth, usersController.me);

// DELETE /api/users/me
usersRouter.delete("/me", requireAuth, usersController.deleteMe);

