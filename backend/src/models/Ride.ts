import mongoose, { Schema, Document, Types } from "mongoose";

export interface IRide extends Document {
  passengers: Types.ObjectId[];
  pickupPoint: {
    lat: number;
    lng: number;
  };
  destination: {
    lat: number;
    lng: number;
  };
  estimatedSavings: number;
  reducedCars: number;
  createdAt: Date;
  updatedAt: Date;
}

const rideSchema = new Schema<IRide>(
  {
    passengers: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
      },
    ],

    pickupPoint: {
      lat: Number,
      lng: Number,
    },

    destination: {
      lat: Number,
      lng: Number,
    },

    estimatedSavings: Number,

    reducedCars: Number,
  },
  {
    timestamps: true,
  },
);

export const Ride = mongoose.model<IRide>("Ride", rideSchema);
