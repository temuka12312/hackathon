import express, { Request, Response } from "express";
import { createReport, listReports } from "../services/report.service";

const router = express.Router();

router.post("/", async (req: Request, res: Response) => {
  try {
    const report = await createReport(req.body);
    return res.json(report);
  } catch (error) {
    return res.status(500).json({
      message: "Failed to create report",
    });
  }
});

router.get("/", async (_req: Request, res: Response) => {
  const reports = await listReports();
  return res.json(reports);
});

export default router;
