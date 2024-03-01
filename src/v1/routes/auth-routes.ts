import { Router } from "express";
import { register } from "../controllers/auth/authController";

const router = Router();

// registers user
router.post("/register", register);

export default router;
