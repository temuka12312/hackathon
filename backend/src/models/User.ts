import mongoose, { Schema, Document } from "mongoose";

export interface IUser extends Document {
  name: string;
  currentLocation: {
    lat: number;
    lng: number;
  };
  destination: {
    lat: number;
    lng: number;
  };
  transportMode: "car" | "bike" | "wheelchair" | "walk";
  createdAt: Date;
  updatedAt: Date;
}

const userSchema = new Schema<IUser>(
  {
    name: String,

    currentLocation: {
      lat: Number,
      lng: Number,
    },

    destination: {
      lat: Number,
      lng: Number,
    },

    transportMode: {
      type: String,
      enum: ["car", "bike", "wheelchair", "walk"],
      default: "car",
    },
  },
  {
    timestamps: true,
  },
);

export const User = mongoose.model<IUser>("User", userSchema);
