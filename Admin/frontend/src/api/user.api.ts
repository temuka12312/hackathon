const API_URL = "http://localhost:3030/api/auth";

export type User = {
  _id: string;
  name: string;
  email: string;

  // ADD THESE:
  role?: "user" | "admin" | "manager" | string;
  createdAt?: string;
  updatedAt?: string;
};

export const getUsers = async (): Promise<User[]> => {
  const response = await fetch(`${API_URL}/users`);

  if (!response.ok) {
    throw new Error("Failed to fetch users");
  }

  const data = await response.json();

  return data.users;
};