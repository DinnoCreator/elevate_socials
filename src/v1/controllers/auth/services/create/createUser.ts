import { Request, Response } from "express";
import { User } from "./createUser.dto";
import * as bcrypt from "bcrypt";
import { pool } from "../../../../../db";
import { emailRegex } from "../../../../../helpers/regex";

const register = async (req: Request, res: Response) => {
  if (req.method === "POST") {
    if (req.body) {
      const requiredFields = ["email", "password", "firstName", "lastName"];

      // check data for each field in the body
      for (const field of requiredFields) {
        if (!req?.body?.[field]) {
          return res.status(400).json({ message: `${field} field is empty.` });
        }
      }

      // Validate email format
      if (!emailRegex.test(req.body.email)) {
        return res.status(400).json({ message: "Invalid email format." });
      }

      // Get values from body
      const { email, password, firstName, lastName, ...rest } =
        req.body as User & {
          [key: string]: any;
        };

      // Check if there are any additional properties in the request body
      if (Object.keys(rest).length > 0) {
        return res.status(400).json({
          error: "Additional properties in the request body are not allowed",
        });
      }

      try {
        // Check if user already exists
        const user = await pool.query("SELECT * FROM users WHERE email = $1", [
          email,
        ]);

        if (user.rows[0])
          return res.status(409).json({ message: "User already exists!" });

        // hashes password
        const hashedPassword = await bcrypt.hash(password, 10);

        const newUser = await pool.query(
          `
        INSERT INTO users(
        first_name, last_name, email, password
          ) VALUES($1, $2, $3, $4) RETURNING *`,
          [
            firstName.toLowerCase(),
            lastName.toLowerCase(),
            email,
            hashedPassword,
          ]
        );

        // return
        return res.status(200).json({
          registration: "Successful!",
          user_created: newUser.rows[0].email,
        });
      } catch (error) {
        console.log(error);
        return res.status(500).json({ message: "Internal server error." });
      }
    } else {
      return res.status(400).json({ message: "Parameter is required." });
    }
  } else {
    return res.status(405).json({ message: "Method not allowed." });
  }
};

export { register };
