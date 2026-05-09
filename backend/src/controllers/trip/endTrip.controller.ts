import { Request, Response } from "express";
import { Trip } from "../../models/Trip";

type EndTripBody = {
  tripId: string;
  lat: number;
  lng: number;
};

export const endTrip = async (
  req: Request<{}, {}, EndTripBody>,
  res: Response
) => {
  try {
    const { tripId, lat, lng } = req.body;

    const trip = await Trip.findById(tripId);
    if (!trip) {
      return res.status(404).json({ message: "Trip not found" });
    }

    trip.endTime = new Date();

    trip.endLocation = {
      lat,
      lng,
    };

    // ✅ FIXED: force compatibility with Mongoose DocumentArray
    trip.cleanedPath = trip.rawPoints.map((p: any) => ({
      lat: p.lat,
      lng: p.lng,
    })) as any;

    await trip.save();

    res.json({
      success: true,
      trip,
    });
  } catch (err) {
    res.status(500).json({
      message: "Failed to end trip",
      error: err,
    });
  }
};