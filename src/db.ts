import dotenv from "dotenv";
import { Pool } from "pg";

dotenv.config();

const pool = new Pool({
  // user: "myapp_4hvr_user",
  user: "postgres",
  password: process.env.DB_PASSWORD,
  // host: "dpg-ci30ahrhp8u1a1d74bog-a",
  // host: "dpg-ci30ahrhp8u1a1d74bog-a.oregon-postgres.render.com",
  port: 5432,
  database: "elevatesocials",
  // database: "reventlify",
  // ssl: true,
});
export { pool };
