import { ITraveledRoute, TraveledRoute } from "../models/TraveledRoute";

type SaveRouteInput = Pick<
  ITraveledRoute,
  "transportMode" | "polyline" | "startTime" | "endTime"
>;

export const saveRoute = async (payload: SaveRouteInput) => {
  return TraveledRoute.create(payload);
};

export const getRoutes = async () => {
  return TraveledRoute.find().sort({ createdAt: -1 });
};
