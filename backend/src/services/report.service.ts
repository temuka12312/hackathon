import { IReport, Report } from "../models/Report";

type CreateReportInput = Pick<IReport, "type" | "description" | "image" | "location">;

export const createReport = async (payload: CreateReportInput) => {
  return Report.create(payload);
};

export const listReports = async () => {
  return Report.find().sort({ createdAt: -1 });
};
