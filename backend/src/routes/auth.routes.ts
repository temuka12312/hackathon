import express, { Request, Response } from "express";
import { loginUser, registerUser } from "../services/auth.service";
import { AuthUser } from "../models/AuthUser";

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

router.post("/login", async (req: Request, res: Response) => {
  try {
    const result = await loginUser(req.body);

    return res.status(result.status).json(result.body);
  } catch (error) {
    console.error(error);

    return res.status(500).json({
      message: "Нэвтрэх үед алдаа гарлаа.",
    });
  }
});

router.get("/users", async (_req: Request, res: Response) => {
  try {
    const users = await AuthUser.find().select("-passwordHash");

    return res.status(200).json({
      users,
    });
  } catch (error) {
    console.error(error);

    return res.status(500).json({
      message: "Хэрэглэгчдийн мэдээлэл авах үед алдаа гарлаа.",
    });
  }
});

export default router;
