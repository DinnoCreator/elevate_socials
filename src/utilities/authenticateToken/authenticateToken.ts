import { Response, NextFunction } from "express";
import jwt from "jsonwebtoken";
import dotenv from "dotenv";
import { ExtendedRequest, User } from "./authenticateToken.dto";

dotenv.config();

// Authenticate
function authenticateToken(
  req: ExtendedRequest,
  res: Response,
  next: NextFunction
) {
  const authHeader = req.headers["authorization"]; // Bearer TOKEN
  const token = authHeader && authHeader.split(" ")[1];
  if (token == null) return res.status(401).json({ error: "Null Token" });
  jwt.verify(
    token,
    process.env.ACCESS_TOKEN_SECRET as string,
    (error: any, user: User) => {
      if (error) return res.status(403).json({ error: error.message });
      req.user = user.user_id;
      req.email = user.user_email;
      req.firstName = user.user_fname;
      req.lastName = user.user_lname;
      req.nationality = user.user_nationality;
      req.permissions = user.user_permissions;
      next();
    }
  );
}

export = authenticateToken;
