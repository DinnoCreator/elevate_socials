import { Router } from "express";
import authenticateToken from "../../utilities/authenticateToken/authenticateToken";
import { isLoggedIn } from "../controllers/users/usersController";

const router = Router();

// Checks is user is logged in
router.get("/isloggedin", authenticateToken, isLoggedIn);

export default router;
