import { Request, Response } from "express";
import { Trip } from "../../models/Trip";

type StartTripBody = {
  userId: string;
  lat: number;
  lng: number;
};

export const startTrip = async (
  req: Request<{}, {}, StartTripBody>,
  res: Response
) => {
  try {
    const { userId, lat, lng } = req.body;

    const newTrip = await Trip.create({
      userId,

      startTime: new Date(),

      startLocation: {
        lat,
        lng,
      },

      rawPoints: [],
      cleanedPath: [],
    });

    res.status(201).json({
      success: true,
      tripId: newTrip._id,
      trip: newTrip,
    });
  } catch (err) {
    res.status(500).json({
      message: "Failed to start trip",
      error: err,
    });
  }
};