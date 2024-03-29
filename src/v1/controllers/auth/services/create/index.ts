import { Request, Response } from "express";
import { User } from "./createUser.dto";
import * as bcrypt from "bcrypt";
import * as nodemailer from "nodemailer";
import { pool } from "../../../../../db";
import * as Helpers from "../../../../../helpers/index";

const register = async (req: Request, res: Response) => {
  if (req.method === "POST") {
    if (req.body) {
      const requiredFields = ["email", "password", "firstName", "lastName"];

      // check data for each field in the body and validate format
      for (const field of requiredFields) {
        if (!req?.body?.[field]) {
          return res.status(400).json({ message: `${field} field is empty.` });
        } else if (
          (field === "firstName" || field === "lastName") &&
          !Helpers.nameRegex.test(req?.body?.[field])
        ) {
          return res
            .status(400)
            .json({ message: `Invalid name format in the ${field} field.` });
        }
      }

      // Validate email format
      if (!Helpers.emailRegex.test(req.body.email)) {
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
          message: "Additional properties in the request body are not allowed.",
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

        //credentials for email transportation
        const transport = nodemailer.createTransport({
          host: "smtp.office365.com",
          port: 578,
          auth: {
            user: "reventlifyhub@outlook.com",
            pass: process.env.MAIL,
          },
        });

        //Welcome Message
        const msg = {
          from: "Reventlify <reventlifyhub@outlook.com>", // sender address
          to: newUser.rows[0].email, // list of receivers
          subject: "Welcome To Elevate socials", // Subject line
          text: `${newUser.rows[0].first_name} thank you for choosing Elevate socials.`, // plain text body
          html: `<h2>Welcome To Elevate socials</h2>
        <p>${newUser.rows[0].first_name} thank you for choosing <strong>Elevate socials</strong>.</p>`, //HTML message
        };

        // send mail with defined transport object
        await transport.sendMail(msg);

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
