function LoginPage() {
  return (
    <div className="h-screen flex items-center justify-center bg-slate-950">
      <div className="w-100 bg-slate-900 border border-slate-800 rounded-3xl p-8">
        <h1 className="text-4xl font-black mb-2">Admin Login</h1>

        <p className="text-slate-400 mb-6">Smart Mobility Control Center</p>

        <div className="space-y-4">
          <input
            type="email"
            placeholder="Email"
            className="w-full bg-slate-800 p-4 rounded-xl outline-none"
          />

          <input
            type="password"
            placeholder="Password"
            className="w-full bg-slate-800 p-4 rounded-xl outline-none"
          />

          <button className="w-full bg-blue-600 hover:bg-blue-700 transition-all p-4 rounded-xl font-bold">
            Login
          </button>
        </div>
      </div>
    </div>
  );
}

export default LoginPage;
