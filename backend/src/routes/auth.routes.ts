import express, { Request, Response } from "express";
import { AuthUser } from "../models/AuthUser";
import { hashPassword, verifyPassword } from "../utils/password";

const router = express.Router();

router.post("/register", async (req: Request, res: Response) => {
  try {
    const name = String(req.body.name ?? "").trim();
    const email = String(req.body.email ?? "")
      .trim()
      .toLowerCase();
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

router.post("/login", async (req: Request, res: Response) => {
  try {
    const email = String(req.body.email ?? "")
      .trim()
      .toLowerCase();
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
