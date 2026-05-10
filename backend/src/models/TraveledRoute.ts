import mongoose, { Schema, Document, model } from "mongoose";

export interface ITraveledRoute extends Document {
  transportMode: "car" | "walk" | "heavy" | "wheelchair";
  encodedPolyline: string;
  elevations: number[];
  startTime: Date;
  endTime: Date;
  createdAt: Date;
  updatedAt: Date;
}

const schema = new Schema<ITraveledRoute>(
  {
    transportMode: {
      type: String,
      enum: ["car", "walk", "heavy", "wheelchair"],
      required: true,
    },
    encodedPolyline: { type: String, required: true },
    elevations: [{ type: Number }],
    startTime: { type: Date, required: true },
    endTime: { type: Date, required: true },
  },
  { timestamps: true },
);

export const TraveledRoute = model<ITraveledRoute>("TraveledRoute", schema);