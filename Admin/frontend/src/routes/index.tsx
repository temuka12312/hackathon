import { Routes, Route } from "react-router-dom";

import DashboardPage from "../pages/dashboard/DashboardPage";
import ReportsPage from "../pages/reports/ReportsPage";
import UsersPage from "../pages/users/UsersPage";
import RidesPage from "../pages/rides/RidesPage";
import LiveMapPage from "../pages/map/LiveMapPage";
import LoginPage from "../pages/auth/LoginPage";

function AppRoutes() {
  return (
   <Routes>
      <Route path="/" element={<DashboardPage />} />

      <Route path="/reports" element={<ReportsPage />} />

      <Route path="/users" element={<UsersPage />} />

      <Route path="/rides" element={<RidesPage />} />

      <Route path="/map" element={<LiveMapPage />} />

      <Route path="/login" element={<LoginPage />} />
    </Routes>
  );
}

export default AppRoutes;