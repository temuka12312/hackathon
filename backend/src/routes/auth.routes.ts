import express, { Request, Response } from "express";
<<<<<<< HEAD
import { AuthUser } from "../models/AuthUser";
import { hashPassword, verifyPassword } from "../utils/password";
=======
import { loginUser, registerUser } from "../services/auth.service";
>>>>>>> ff4d34b5abbaf7de8c00a97eebfc5677583bfcaa

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
<<<<<<< HEAD
    const email = String(req.body.email ?? "").trim().toLowerCase();
    const password = String(req.body.password ?? "");

    if (!email || !password) {
      return res.status(400).json({
        message: "Имэйл, нууц үг бүгд шаардлагатай.",
      });
    }

    const user = await AuthUser.findOne({ email });

    if (!user || !verifyPassword(password, user.passwordHash)) {
      return res.status(401).json({
        message: "Имэйл эсвэл нууц үг буруу байна.",
      });
    }

    return res.status(200).json({
      message: "Амжилттай нэвтэрлээ.",
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
      },
    });
=======
    const result = await loginUser(req.body);

    return res.status(result.status).json(result.body);
>>>>>>> ff4d34b5abbaf7de8c00a97eebfc5677583bfcaa
  } catch (error) {
    console.error(error);

    return res.status(500).json({
      message: "Нэвтрэх үед алдаа гарлаа.",
    });
  }
});

export default router;
