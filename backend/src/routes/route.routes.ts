import express, { Request, Response } from "express";
import { saveRoute, getRoutes } from "../services/route.service";

const router = express.Router();

router.post("/", async (req: Request, res: Response) => {
  try {
    const route = await saveRoute(req.body);
    return res.status(201).json(route);
  } catch (error) {
    return res.status(500).json({ message: "Failed to save route" });
  }
});

router.get("/", async (_req: Request, res: Response) => {
  const routes = await getRoutes();
  return res.json(routes);
});

export default router;
