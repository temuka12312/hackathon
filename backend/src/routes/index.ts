import { Express } from "express";

import authRoutes from "./auth.routes";
import reportRoutes from "./report.routes";
import rideRoutes from "./ride.routes";
import routeRoutes from "./route.routes";

const registerRoutes = (app: Express) => {
  app.use("/api/auth", authRoutes);
  app.use("/api/reports", reportRoutes);
  app.use("/api/rides", rideRoutes);
  app.use("/api/routes", routeRoutes);
};

export default registerRoutes;
