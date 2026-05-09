import mongoose, { Schema, Document, model } from "mongoose";

export interface ITraveledRoute extends Document {
  transportMode: "car" | "walk" | "heavy" | "wheelchair";
  polyline: { lat: number; lng: number }[];
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
    polyline: [
      {
        lat: { type: Number, required: true },
        lng: { type: Number, required: true },
      },
    ],
    startTime: { type: Date, required: true },
    endTime: { type: Date, required: true },
  },
  { timestamps: true },
);

export const TraveledRoute = model<ITraveledRoute>("TraveledRoute", schema);
