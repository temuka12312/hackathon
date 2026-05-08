import express, { Request, Response } from "express";
import { Report } from "../models/Report";

const router = express.Router();

router.post("/", async (req: Request, res: Response) => {
  try {
    const report = await Report.create(req.body);
    res.json(report);
  } catch (error) {
    res.status(500).json({
      message: "Failed to create report",
    });
  }
});

router.get("/", async (_req: Request, res: Response) => {
  const reports = await Report.find().sort({ createdAt: -1 });
  res.json(reports);
});

export default router;
