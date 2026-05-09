import type { ReactNode } from "react";

import Sidebar from "./Sidebar";
import Navbar from "./Navbar";

type Props = {
  children: ReactNode;
};

function AdminLayout({ children }: Props) {
  return (
    <div className="flex">
      <Sidebar />

      <div className="flex-1 h-screen overflow-y-auto">
        <Navbar />

        <div className="p-6">{children}</div>
      </div>
    </div>
  );
}

export default AdminLayout;
