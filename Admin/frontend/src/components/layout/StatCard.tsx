import type { LucideIcon } from "lucide-react";

type Props = {
  title: string;
  value: string;
  icon: LucideIcon;
};

function StatCard({ title, value, icon: Icon }: Props) {
  return (
    <div className="bg-slate-900 border border-slate-800 rounded-2xl p-5 hover:border-blue-500 transition-all">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-slate-400">{title}</p>

          <h2 className="text-3xl font-black mt-3">{value}</h2>
        </div>

        <div className="w-14 h-14 rounded-2xl bg-blue-600/20 flex items-center justify-center">
          <Icon className="text-blue-500" />
        </div>
      </div>
    </div>
  );
}

export default StatCard;
