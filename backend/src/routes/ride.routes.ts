import express, { Request, Response } from "express";
import { User } from "../models/User";
import { Ride } from "../models/Ride";
import findMatches from "../services/matchRide";

const router = express.Router();

router.post("/match", async (req: Request, res: Response) => {
  try {
    const user = await User.create(req.body);

    const matches = await findMatches(user);

    if (matches.length === 0) {
      return res.json({
        matched: false,
        message: "No nearby passengers found",
      });
    }

    const ride = await Ride.create({
      passengers: [user._id, matches[0]._id],
      pickupPoint: user.currentLocation,
      destination: user.destination,
      estimatedSavings: 40,
      reducedCars: 1,
    });

    res.json({
      matched: true,
      ride,
      matchedUser: matches[0],
    });
  } catch (error) {
    console.error(error);

    res.status(500).json({
      message: "Ride matching failed",
    });
  }
});

export default router;
