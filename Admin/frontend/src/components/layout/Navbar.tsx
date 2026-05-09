function Navbar() {
  return (
    <div className="h-16 border-b border-slate-800 bg-slate-950/70 backdrop-blur-xl px-6 flex items-center justify-between">
      <h1 className="text-xl font-bold">Smart Mobility Admin</h1>

      <div className="flex items-center gap-3">
        <div className="w-10 h-10 rounded-full bg-blue-600" />

        <div>
          <p className="font-semibold">Admin</p>

          <p className="text-xs text-slate-400">Control Center</p>
        </div>
      </div>
    </div>
  );
}

export default Navbar;
