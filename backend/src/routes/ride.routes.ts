import express, { Request, Response } from "express";
import { matchRide } from "../services/ride.service";

const router = express.Router();

router.post("/match", async (req: Request, res: Response) => {
  try {
    const result = await matchRide(req.body);

    return res.json(result);
  } catch (error) {
    console.error(error);

    return res.status(500).json({
      message: "Ride matching failed",
    });
  }
});

export default router;
