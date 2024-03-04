import { Router } from "express";
import { login, register } from "../controllers/auth/authController";

const router = Router();

// registers user
router.post("/register", register);

// login user
router.post("/login", login);

export default router;
