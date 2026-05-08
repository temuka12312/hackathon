import mongoose, { Schema, Document } from "mongoose";

export interface IReport extends Document {
  type: "traffic" | "pothole" | "accident" | "blocked-road";
  description: string;
  image?: string;
  location: {
    lat: number;
    lng: number;
  };
  createdAt: Date;
  updatedAt: Date;
}

const reportSchema = new Schema<IReport>(
  {
    type: {
      type: String,
      enum: ["traffic", "pothole", "accident", "blocked-road"],
    },

    description: String,

    image: String,

    location: {
      lat: Number,
      lng: Number,
    },
  },
  {
    timestamps: true,
  },
);

export const Report = mongoose.model<IReport>("Report", reportSchema);
