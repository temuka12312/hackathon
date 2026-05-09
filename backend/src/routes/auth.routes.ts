import express, { Request, Response } from "express";
import { registerUser } from "../services/auth.service";

const router = express.Router();

router.post("/register", async (req: Request, res: Response) => {
  try {
    const result = await registerUser(req.body);

    return res.status(result.status).json(result.body);
  } catch (error) {
    console.error(error);

    return res.status(500).json({
      message: "Хэрэглэгч бүртгэх үед алдаа гарлаа.",
    });
  }
});

export default router;
