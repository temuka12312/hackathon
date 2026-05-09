import AdminLayout from "../../components/layout/AdminLayout";

function RidesPage() {
  return (
    <AdminLayout>
      <div className="bg-slate-900 border border-slate-800 rounded-2xl p-5">
        <h1 className="text-3xl font-black mb-5">Shared Rides</h1>

        <div className="space-y-4">
          <div className="bg-slate-800 p-5 rounded-xl">
            Ride from Zaisan → Sukhbaatar
          </div>

          <div className="bg-slate-800 p-5 rounded-xl">
            Ride from 13th District → Airport
          </div>
        </div>
      </div>
    </AdminLayout>
  );
}

export default RidesPage;
