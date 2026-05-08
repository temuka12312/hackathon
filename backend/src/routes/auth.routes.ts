import express, { Request, Response } from "express";
import { AuthUser } from "../models/AuthUser";
import { hashPassword } from "../utils/password";

const router = express.Router();

router.post("/register", async (req: Request, res: Response) => {
  try {
    const name = String(req.body.name ?? "").trim();
    const email = String(req.body.email ?? "").trim().toLowerCase();
    const password = String(req.body.password ?? "");

    if (!name || !email || !password) {
      return res.status(400).json({
        message: "Нэр, имэйл, нууц үг бүгд шаардлагатай.",
      });
    }

    if (!email.includes("@")) {
      return res.status(400).json({
        message: "Имэйл хаяг буруу байна.",
      });
    }

    if (password.length < 6) {
      return res.status(400).json({
        message: "Нууц үг хамгийн багадаа 6 тэмдэгт байна.",
      });
    }

    const existingUser = await AuthUser.findOne({ email });

    if (existingUser) {
      return res.status(409).json({
        message: "Энэ имэйлээр бүртгэл аль хэдийн үүссэн байна.",
      });
    }

    const user = await AuthUser.create({
      name,
      email,
      passwordHash: hashPassword(password),
    });

    return res.status(201).json({
      message: "Хэрэглэгч амжилттай бүртгэгдлээ.",
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
      },
    });
  } catch (error) {
    console.error(error);

    return res.status(500).json({
      message: "Хэрэглэгч бүртгэх үед алдаа гарлаа.",
    });
  }
});

export default router;
