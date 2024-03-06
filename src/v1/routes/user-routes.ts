import { Router } from "express";
import authenticateToken from "../../utilities/authenticateToken/authenticateToken";
import {
  instagramBasicDisplayInit,
  isLoggedIn,
} from "../controllers/users/usersController";

const router = Router();

// Checks is user is logged in
router.get("/isloggedin", authenticateToken, isLoggedIn);
router.post("/insta-init", authenticateToken, instagramBasicDisplayInit);

export default router;
