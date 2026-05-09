import express from "express";
import { startTrip } from "../controllers/trip/startTrip.controller";
import { endTrip } from "../controllers/trip/endTrip.controller";

const router = express.Router();

router.post("/start", startTrip);
router.post("/end", endTrip);

export default router;
