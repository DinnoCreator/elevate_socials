// Load environment variables from .env file
import dotenv from "dotenv";
dotenv.config();

// Other imports
import express from "express";
import cors from "cors";
const port = 5000;

const app = express();
const whitelist = ["https://admin.socket.io", process.env.URL];

const corsOptions = {
  optionsSuccessStatus: 200,
  credentials: true,
  origin: whitelist,
  // origin: "*",
};

//middlewares
app.use(express.urlencoded({ extended: true }));
app.use(express.static("public"));
app.use(
  express.json({
    limit: "50mb",
  })
);
app.use(cors(corsOptions));

const server = app.listen(port, () => {
  console.log(`Server has started on port ${port}`);
});
