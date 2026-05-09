import { Request, Response } from "express";
import { Trip } from "../../models/Trip";
import { distance } from "../../utils/distance";

type UpdateLocationBody = {
  tripId: string;
  lat: number;
  lng: number;
  timestamp: string;
};

export const updateLocation = async (
  req: Request<{}, {}, UpdateLocationBody>,
  res: Response,
) => {
  try {
    const { tripId, lat, lng, timestamp } = req.body;

    const trip = await Trip.findById(tripId);
    if (!trip) {
      return res.status(404).json({ message: "Trip not found" });
    }

    const newPoint = { lat, lng, timestamp };

    const lastPoint = trip.rawPoints[trip.rawPoints.length - 1];

    // 🚫 first point case
    if (!lastPoint?.lat || !lastPoint?.lng) {
      trip.rawPoints.push(newPoint);
      await trip.save();
      return res.json({ success: true });
    }

    // 🚫 noise filter
    const d = distance({ lat: lastPoint.lat!, lng: lastPoint.lng! }, newPoint);

    if (d < 8) {
      return res.json({ skipped: true });
    }

    trip.rawPoints.push(newPoint);
    await trip.save();

    res.json({ success: true });
  } catch (err) {
    res.status(500).json({
      message: "Server error",
      err,
    });
  }
};
