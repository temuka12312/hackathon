import AdminLayout from "../../components/layout/AdminLayout";

import MapView from "../../components/map/MapView";

function LiveMapPage() {
  return (
    <AdminLayout>
      <div className="bg-slate-900 border border-slate-800 rounded-2xl p-5 h-200">
        <div className="flex items-center justify-between mb-5">
          <div>
            <h1 className="text-3xl font-black">Live Smart City Map</h1>

            <p className="text-slate-400 mt-1">Real-time monitoring</p>
          </div>

          <div className="flex gap-3">
            <button className="bg-red-500/20 text-red-400 px-4 py-2 rounded-xl">
              Accidents
            </button>

            <button className="bg-yellow-500/20 text-yellow-400 px-4 py-2 rounded-xl">
              Traffic
            </button>

            <button className="bg-blue-500/20 text-blue-400 px-4 py-2 rounded-xl">
              Shared Rides
            </button>
          </div>
        </div>

        <MapView />
      </div>
    </AdminLayout>
  );
}

export default LiveMapPage;
