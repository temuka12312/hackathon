import express from "express";
import cors from "cors";
import dotenv from "dotenv";

import connectDB from "./config/db";
import authRoutes from "./routes/auth.routes";

dotenv.config();

connectDB();

const app = express();

const port = Number(process.env.PORT) || 3000;

app.use(cors());
app.use(express.json());
app.use("/api/auth", authRoutes);

app.get("/", (_req, res) => {
  res.json({
    message: "Backend is running",
  });
});

app.get("/api/health", (_req, res) => {
  res.json({
    status: "ok",
    message: "Express backend connected successfully",
    timestamp: new Date().toISOString(),
  });
});

app.listen(port, () => {
  console.log(`Backend listening on http://localhost:${port}`);
});
