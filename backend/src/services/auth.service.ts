import { AuthUser } from "../models/AuthUser";
import { hashPassword } from "../utils/password";

type RegisterUserInput = {
  name: string;
  email: string;
  password: string;
};

export const registerUser = async ({
  name,
  email,
  password,
}: RegisterUserInput) => {
  const normalizedName = String(name ?? "").trim();
  const normalizedEmail = String(email ?? "").trim().toLowerCase();
  const normalizedPassword = String(password ?? "");

  if (!normalizedName || !normalizedEmail || !normalizedPassword) {
    return {
      status: 400,
      body: {
        message: "Нэр, имэйл, нууц үг бүгд шаардлагатай.",
      },
    };
  }

  if (!normalizedEmail.includes("@")) {
    return {
      status: 400,
      body: {
        message: "Имэйл хаяг буруу байна.",
      },
    };
  }

  if (normalizedPassword.length < 6) {
    return {
      status: 400,
      body: {
        message: "Нууц үг хамгийн багадаа 6 тэмдэгт байна.",
      },
    };
  }

  const existingUser = await AuthUser.findOne({ email: normalizedEmail });

  if (existingUser) {
    return {
      status: 409,
      body: {
        message: "Энэ имэйлээр бүртгэл аль хэдийн үүссэн байна.",
      },
    };
  }

  const user = await AuthUser.create({
    name: normalizedName,
    email: normalizedEmail,
    passwordHash: hashPassword(normalizedPassword),
  });

  return {
    status: 201,
    body: {
      message: "Хэрэглэгч амжилттай бүртгэгдлээ.",
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
      },
    },
  };
};
