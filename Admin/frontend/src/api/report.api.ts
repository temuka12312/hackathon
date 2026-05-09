import axios from "axios";

const API = axios.create({
  baseURL: "http://localhost:3030/api",
});

export async function getReports() {
  const response = await API.get("/reports");

  return response.data;
}
