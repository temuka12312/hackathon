import mongoose from "mongoose";

const TripSchema = new mongoose.Schema({
  userId: String,

  startTime: Date,
  endTime: Date,

  startLocation: {
    lat: Number,
    lng: Number,
  },

  endLocation: {
    lat: Number,
    lng: Number,
  },

  rawPoints: [
    {
      lat: Number,
      lng: Number,
      timestamp: Date,
      accuracy: Number,
    },
  ],

  cleanedPath: [
    {
      lat: Number,
      lng: Number,
    },
  ],

  distanceMeters: Number,
});

export const Trip = mongoose.model("Trip", TripSchema);
