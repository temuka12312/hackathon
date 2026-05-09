import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import os from "os";

import connectDB from "./config/db";
import registerRoutes from "./routes";

dotenv.config();

connectDB();

const app = express();

const port = Number(process.env.PORT) || 3000;
const host = process.env.HOST || "0.0.0.0";

app.use(cors());
app.use(express.json());
registerRoutes(app);

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

app.listen(port, host, () => {
  const networkInterfaces = os.networkInterfaces();
  const localIps = Object.values(networkInterfaces)
    .flat()
    .filter((detail) => detail?.family === "IPv4" && !detail.internal)
    .map((detail) => detail!.address);

  console.log(`Backend listening on http://${host}:${port}`);
  console.log(`Local access: http://localhost:${port}`);

  if (localIps.length > 0) {
    console.log(
      `Device access: ${localIps
        .map((ip) => `http://${ip}:${port}`)
        .join(", ")}`,
    );
  }
});
