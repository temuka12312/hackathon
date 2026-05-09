import { create } from "zustand";

type DashboardStore = {
  loading: boolean;

  setLoading: (value: boolean) => void;
};

export const useDashboardStore = create<DashboardStore>((set) => ({
  loading: false,

  setLoading: (value) =>
    set({
      loading: value,
    }),
}));
