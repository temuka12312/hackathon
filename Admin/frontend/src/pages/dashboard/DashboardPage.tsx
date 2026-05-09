import {
  Users,
  TriangleAlert,
  Car,
  Activity,
  ArrowUpRight,
  ArrowDownRight,
  Clock,
  MapPin,
  Zap,
} from "lucide-react";
import AdminLayout from "../../components/layout/AdminLayout";
import StatCard from "../../components/layout/StatCard";

const recentActivity = [
  {
    id: 1,
    icon: TriangleAlert,
    color: "#f97316",
    glow: "rgba(249,115,22,0.25)",
    bg: "rgba(249,115,22,0.08)",
    border: "rgba(249,115,22,0.18)",
    label: "New accident report",
    sub: "Intersection 4th & Main",
    time: "2 min ago",
    badge: "URGENT",
    badgeColor: "#f97316",
  },
  {
    id: 2,
    icon: Car,
    color: "#388bfd",
    glow: "rgba(56,139,253,0.25)",
    bg: "rgba(56,139,253,0.06)",
    border: "rgba(56,139,253,0.14)",
    label: "Shared ride matched",
    sub: "3 passengers • Route 7B",
    time: "8 min ago",
    badge: "MATCHED",
    badgeColor: "#388bfd",
  },
  {
    id: 3,
    icon: Activity,
    color: "#f43f5e",
    glow: "rgba(244,63,94,0.25)",
    bg: "rgba(244,63,94,0.06)",
    border: "rgba(244,63,94,0.14)",
    label: "Traffic increased",
    sub: "Downtown corridor — HIGH",
    time: "15 min ago",
    badge: "ALERT",
    badgeColor: "#f43f5e",
  },
  {
    id: 4,
    icon: Users,
    color: "#22c55e",
    glow: "rgba(34,197,94,0.25)",
    bg: "rgba(34,197,94,0.06)",
    border: "rgba(34,197,94,0.14)",
    label: "New user registered",
    sub: "Verified via mobile",
    time: "31 min ago",
    badge: "NEW",
    badgeColor: "#22c55e",
  },
];

const trafficZones = [
  { name: "Downtown Core", level: 87, color: "#f43f5e" },
  { name: "East Boulevard", level: 54, color: "#f97316" },
  { name: "West Corridor", level: 32, color: "#388bfd" },
  { name: "North Ring Rd", level: 19, color: "#22c55e" },
];

const statData = [
  {
    title: "Total Users",
    value: "12,430",
    change: "+8.2%",
    up: true,
    icon: Users,
    accent: "#388bfd",
    glow: "rgba(56,139,253,0.15)",
    sub: "vs last month",
  },
  {
    title: "Active Reports",
    value: "245",
    change: "+14.5%",
    up: true,
    icon: TriangleAlert,
    accent: "#f97316",
    glow: "rgba(249,115,22,0.15)",
    sub: "vs last month",
  },
  {
    title: "Shared Rides",
    value: "89",
    change: "-3.1%",
    up: false,
    icon: Car,
    accent: "#a78bfa",
    glow: "rgba(167,139,250,0.15)",
    sub: "vs last month",
  },
  {
    title: "Traffic Level",
    value: "HIGH",
    change: "↑ Rising",
    up: false,
    icon: Activity,
    accent: "#f43f5e",
    glow: "rgba(244,63,94,0.15)",
    sub: "current status",
  },
];

function DashboardPage() {
  return (
    <AdminLayout>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Syne:wght@700;800&family=DM+Sans:wght@300;400;500&display=swap');

        .dash-wrap {
          font-family: 'DM Sans', sans-serif;
          padding: 32px;
          min-height: 100vh;
          background: #080C14;
          color: white;
          position: relative;
          overflow-x: hidden;
        }

        /* Background mesh */
        .dash-wrap::before {
          content: '';
          position: fixed;
          top: 0; right: 0;
          width: 600px; height: 600px;
          background: radial-gradient(circle at 80% 10%, rgba(56,139,253,0.07) 0%, transparent 60%);
          pointer-events: none;
          z-index: 0;
        }
        .dash-wrap::after {
          content: '';
          position: fixed;
          bottom: 0; left: 200px;
          width: 500px; height: 400px;
          background: radial-gradient(circle at 30% 80%, rgba(244,63,94,0.05) 0%, transparent 60%);
          pointer-events: none;
          z-index: 0;
        }

        .dash-inner {
          position: relative;
          z-index: 1;
        }

        /* Page header */
        .page-header {
          display: flex;
          align-items: flex-end;
          justify-content: space-between;
          margin-bottom: 28px;
        }

        .page-title {
          font-family: 'Syne', sans-serif;
          font-size: 26px;
          font-weight: 800;
          letter-spacing: -0.01em;
          color: #fff;
          line-height: 1;
        }

        .page-title span {
          color: #388bfd;
        }

        .page-date {
          font-size: 12px;
          font-weight: 300;
          color: rgba(255,255,255,0.25);
          letter-spacing: 0.06em;
          margin-top: 6px;
        }

        .header-right {
          display: flex;
          align-items: center;
          gap: 10px;
        }

        .refresh-btn {
          display: flex;
          align-items: center;
          gap: 6px;
          padding: 8px 14px;
          background: rgba(56,139,253,0.1);
          border: 1px solid rgba(56,139,253,0.2);
          border-radius: 8px;
          color: #388bfd;
          font-size: 12px;
          font-weight: 500;
          cursor: pointer;
          transition: all 0.2s;
          font-family: 'DM Sans', sans-serif;
          letter-spacing: 0.04em;
        }

        .refresh-btn:hover {
          background: rgba(56,139,253,0.18);
          border-color: rgba(56,139,253,0.35);
        }

        /* Stat cards grid */
        .stats-grid {
          display: grid;
          grid-template-columns: repeat(4, 1fr);
          gap: 16px;
          margin-bottom: 20px;
        }

        .stat-card {
          background: rgba(255,255,255,0.025);
          border: 1px solid rgba(255,255,255,0.06);
          border-radius: 14px;
          padding: 20px;
          position: relative;
          overflow: hidden;
          transition: all 0.25s ease;
          cursor: default;
          animation: fadeUp 0.4s ease both;
        }

        .stat-card:nth-child(1) { animation-delay: 0.05s; }
        .stat-card:nth-child(2) { animation-delay: 0.1s; }
        .stat-card:nth-child(3) { animation-delay: 0.15s; }
        .stat-card:nth-child(4) { animation-delay: 0.2s; }

        @keyframes fadeUp {
          from { opacity: 0; transform: translateY(12px); }
          to   { opacity: 1; transform: translateY(0); }
        }

        .stat-card:hover {
          border-color: rgba(255,255,255,0.1);
          transform: translateY(-2px);
          box-shadow: 0 8px 32px rgba(0,0,0,0.3);
        }

        .stat-card-glow {
          position: absolute;
          top: -30px; right: -30px;
          width: 120px; height: 120px;
          border-radius: 50%;
          pointer-events: none;
        }

        .stat-top {
          display: flex;
          align-items: center;
          justify-content: space-between;
          margin-bottom: 14px;
        }

        .stat-label {
          font-size: 11px;
          font-weight: 500;
          letter-spacing: 0.12em;
          text-transform: uppercase;
          color: rgba(255,255,255,0.3);
        }

        .stat-icon {
          width: 32px; height: 32px;
          border-radius: 8px;
          display: flex;
          align-items: center;
          justify-content: center;
        }

        .stat-value {
          font-family: 'Syne', sans-serif;
          font-size: 28px;
          font-weight: 800;
          color: #fff;
          line-height: 1;
          letter-spacing: -0.02em;
          margin-bottom: 8px;
        }

        .stat-footer {
          display: flex;
          align-items: center;
          gap: 6px;
        }

        .stat-change {
          display: flex;
          align-items: center;
          gap: 3px;
          font-size: 11px;
          font-weight: 500;
          border-radius: 4px;
          padding: 2px 6px;
        }

        .stat-sub {
          font-size: 11px;
          color: rgba(255,255,255,0.22);
        }

        /* Bottom grid */
        .bottom-grid {
          display: grid;
          grid-template-columns: 1fr 1fr 1fr;
          gap: 16px;
          margin-top: 4px;
          animation: fadeUp 0.4s ease 0.25s both;
        }

        /* Panel base */
        .panel {
          background: rgba(255,255,255,0.025);
          border: 1px solid rgba(255,255,255,0.06);
          border-radius: 14px;
          padding: 22px;
          position: relative;
          overflow: hidden;
        }

        .panel-header {
          display: flex;
          align-items: center;
          justify-content: space-between;
          margin-bottom: 18px;
        }

        .panel-title {
          font-family: 'Syne', sans-serif;
          font-size: 14px;
          font-weight: 700;
          color: rgba(255,255,255,0.85);
          letter-spacing: 0.01em;
        }

        .panel-badge {
          font-size: 10px;
          font-weight: 500;
          letter-spacing: 0.1em;
          text-transform: uppercase;
          padding: 3px 8px;
          border-radius: 20px;
          background: rgba(56,139,253,0.1);
          border: 1px solid rgba(56,139,253,0.2);
          color: #388bfd;
        }

        /* Activity items */
        .activity-item {
          display: flex;
          align-items: center;
          gap: 12px;
          padding: 11px 0;
          border-bottom: 1px solid rgba(255,255,255,0.04);
          transition: all 0.2s;
        }

        .activity-item:last-child { border-bottom: none; padding-bottom: 0; }
        .activity-item:first-child { padding-top: 0; }

        .activity-icon {
          width: 36px; height: 36px;
          border-radius: 9px;
          display: flex;
          align-items: center;
          justify-content: center;
          flex-shrink: 0;
          border: 1px solid;
        }

        .activity-body { flex: 1; min-width: 0; }

        .activity-label {
          font-size: 13px;
          font-weight: 500;
          color: rgba(255,255,255,0.8);
          display: block;
          white-space: nowrap;
          overflow: hidden;
          text-overflow: ellipsis;
        }

        .activity-sub {
          font-size: 11px;
          font-weight: 300;
          color: rgba(255,255,255,0.28);
          margin-top: 2px;
          display: block;
        }

        .activity-right {
          display: flex;
          flex-direction: column;
          align-items: flex-end;
          gap: 4px;
          flex-shrink: 0;
        }

        .activity-time {
          font-size: 10px;
          color: rgba(255,255,255,0.2);
          display: flex;
          align-items: center;
          gap: 3px;
        }

        .activity-badge {
          font-size: 9px;
          font-weight: 700;
          letter-spacing: 0.1em;
          padding: 2px 6px;
          border-radius: 4px;
        }

        /* Traffic zone bars */
        .zone-item {
          margin-bottom: 16px;
        }

        .zone-item:last-child { margin-bottom: 0; }

        .zone-top {
          display: flex;
          justify-content: space-between;
          align-items: center;
          margin-bottom: 7px;
        }

        .zone-name {
          font-size: 12.5px;
          font-weight: 500;
          color: rgba(255,255,255,0.65);
          display: flex;
          align-items: center;
          gap: 6px;
        }

        .zone-pct {
          font-family: 'Syne', sans-serif;
          font-size: 13px;
          font-weight: 700;
          color: rgba(255,255,255,0.55);
        }

        .zone-bar-track {
          height: 5px;
          background: rgba(255,255,255,0.05);
          border-radius: 99px;
          overflow: hidden;
        }

        .zone-bar-fill {
          height: 100%;
          border-radius: 99px;
          transition: width 0.6s cubic-bezier(0.4,0,0.2,1);
        }

        /* Quick stats panel */
        .quick-grid {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 10px;
        }

        .quick-tile {
          background: rgba(255,255,255,0.03);
          border: 1px solid rgba(255,255,255,0.06);
          border-radius: 10px;
          padding: 14px;
          text-align: center;
        }

        .quick-val {
          font-family: 'Syne', sans-serif;
          font-size: 20px;
          font-weight: 800;
          line-height: 1;
          margin-bottom: 4px;
        }

        .quick-label {
          font-size: 10.5px;
          font-weight: 300;
          color: rgba(255,255,255,0.28);
          letter-spacing: 0.06em;
          text-transform: uppercase;
        }

        .divider-line {
          width: 100%;
          height: 1px;
          background: rgba(255,255,255,0.05);
          margin: 14px 0;
        }

        .response-row {
          display: flex;
          align-items: center;
          justify-content: space-between;
          padding: 8px 0;
          border-bottom: 1px solid rgba(255,255,255,0.04);
        }

        .response-row:last-child { border-bottom: none; }

        .response-label {
          font-size: 12px;
          color: rgba(255,255,255,0.4);
          font-weight: 300;
        }

        .response-val {
          font-size: 12.5px;
          font-weight: 500;
          color: rgba(255,255,255,0.75);
        }

        .dot-map {
          position: absolute;
          top: 0; right: 0;
          width: 120px; height: 80px;
          opacity: 0.15;
        }
      `}</style>

      <div className="dash-wrap">
        <div className="dash-inner">
          {/* Header */}
          <div className="page-header">
            <div>
              <div className="page-title">
                City <span>Overview</span>
              </div>
              <div className="page-date">
                Sunday, May 10, 2026 · Ulaanbaatar
              </div>
            </div>
            <div className="header-right">
              <button className="refresh-btn">
                <Zap size={12} />
                Live Data
              </button>
            </div>
          </div>

          {/* Stat Cards */}
          <div className="stats-grid">
            {statData.map((s) => {
              const Icon = s.icon;
              return (
                <div className="stat-card" key={s.title}>
                  <div
                    className="stat-card-glow"
                    style={{
                      background: `radial-gradient(circle, ${s.glow} 0%, transparent 70%)`,
                    }}
                  />
                  <div className="stat-top">
                    <span className="stat-label">{s.title}</span>
                    <div
                      className="stat-icon"
                      style={{
                        background: `${s.glow}`,
                        border: `1px solid ${s.accent}30`,
                      }}
                    >
                      <Icon size={15} color={s.accent} />
                    </div>
                  </div>
                  <div
                    className="stat-value"
                    style={{
                      color: s.title === "Traffic Level" ? s.accent : "#fff",
                    }}
                  >
                    {s.value}
                  </div>
                  <div className="stat-footer">
                    <span
                      className="stat-change"
                      style={{
                        color: s.up ? "#22c55e" : "#f43f5e",
                        background: s.up
                          ? "rgba(34,197,94,0.08)"
                          : "rgba(244,63,94,0.08)",
                      }}
                    >
                      {s.up ? (
                        <ArrowUpRight size={10} />
                      ) : (
                        <ArrowDownRight size={10} />
                      )}
                      {s.change}
                    </span>
                    <span className="stat-sub">{s.sub}</span>
                  </div>
                </div>
              );
            })}
          </div>

          {/* Bottom panels */}
          <div className="bottom-grid">
            {/* Recent Activity */}
            <div className="panel" style={{ gridColumn: "span 1" }}>
              <div className="panel-header">
                <span className="panel-title">Recent Activity</span>
                <span className="panel-badge">Live</span>
              </div>

              {recentActivity.map((item) => {
                const Icon = item.icon;
                return (
                  <div className="activity-item" key={item.id}>
                    <div
                      className="activity-icon"
                      style={{
                        background: item.bg,
                        borderColor: item.border,
                        boxShadow: `0 0 10px ${item.glow}`,
                      }}
                    >
                      <Icon size={15} color={item.color} />
                    </div>
                    <div className="activity-body">
                      <span className="activity-label">{item.label}</span>
                      <span className="activity-sub">
                        <MapPin
                          size={9}
                          style={{
                            display: "inline",
                            marginRight: 3,
                            opacity: 0.5,
                          }}
                        />
                        {item.sub}
                      </span>
                    </div>
                    <div className="activity-right">
                      <span
                        className="activity-badge"
                        style={{
                          background: `${item.badgeColor}15`,
                          color: item.badgeColor,
                          border: `1px solid ${item.badgeColor}30`,
                        }}
                      >
                        {item.badge}
                      </span>
                      <span className="activity-time">
                        <Clock size={9} />
                        {item.time}
                      </span>
                    </div>
                  </div>
                );
              })}
            </div>

            {/* Traffic Zones */}
            <div className="panel">
              <div className="panel-header">
                <span className="panel-title">Traffic Zones</span>
                <span
                  className="panel-badge"
                  style={{
                    color: "#f43f5e",
                    background: "rgba(244,63,94,0.08)",
                    border: "1px solid rgba(244,63,94,0.18)",
                  }}
                >
                  HIGH
                </span>
              </div>

              {trafficZones.map((zone) => (
                <div className="zone-item" key={zone.name}>
                  <div className="zone-top">
                    <span className="zone-name">
                      <span
                        style={{
                          width: 6,
                          height: 6,
                          borderRadius: "50%",
                          background: zone.color,
                          display: "inline-block",
                          boxShadow: `0 0 6px ${zone.color}`,
                          flexShrink: 0,
                        }}
                      />
                      {zone.name}
                    </span>
                    <span className="zone-pct" style={{ color: zone.color }}>
                      {zone.level}%
                    </span>
                  </div>
                  <div className="zone-bar-track">
                    <div
                      className="zone-bar-fill"
                      style={{
                        width: `${zone.level}%`,
                        background: `linear-gradient(90deg, ${zone.color}80, ${zone.color})`,
                        boxShadow: `0 0 8px ${zone.color}60`,
                      }}
                    />
                  </div>
                </div>
              ))}

              <div className="divider-line" />

              <div className="response-row">
                <span className="response-label">Avg response time</span>
                <span className="response-val" style={{ color: "#22c55e" }}>
                  4.2 min
                </span>
              </div>
              <div className="response-row">
                <span className="response-label">Active incidents</span>
                <span className="response-val" style={{ color: "#f97316" }}>
                  12
                </span>
              </div>
              <div className="response-row">
                <span className="response-label">Cleared today</span>
                <span className="response-val">38</span>
              </div>
            </div>

            {/* Quick Stats */}
            <div className="panel">
              <div className="panel-header">
                <span className="panel-title">Quick Stats</span>
              </div>

              <div className="quick-grid">
                <div className="quick-tile">
                  <div className="quick-val" style={{ color: "#388bfd" }}>
                    98.2%
                  </div>
                  <div className="quick-label">Uptime</div>
                </div>
                <div className="quick-tile">
                  <div className="quick-val" style={{ color: "#22c55e" }}>
                    1,204
                  </div>
                  <div className="quick-label">Active now</div>
                </div>
                <div className="quick-tile">
                  <div className="quick-val" style={{ color: "#a78bfa" }}>
                    34
                  </div>
                  <div className="quick-label">Shared rides</div>
                </div>
                <div className="quick-tile">
                  <div className="quick-val" style={{ color: "#f97316" }}>
                    17
                  </div>
                  <div className="quick-label">Pending</div>
                </div>
              </div>

              <div className="divider-line" />

              <div className="response-row">
                <span className="response-label">New users today</span>
                <span className="response-val">+143</span>
              </div>
              <div className="response-row">
                <span className="response-label">Reports resolved</span>
                <span className="response-val" style={{ color: "#22c55e" }}>
                  91%
                </span>
              </div>
              <div className="response-row">
                <span className="response-label">Peak hour</span>
                <span className="response-val">08:00 – 09:30</span>
              </div>
              <div className="response-row">
                <span className="response-label">Data freshness</span>
                <span
                  className="response-val"
                  style={{
                    color: "#22c55e",
                    display: "flex",
                    alignItems: "center",
                    gap: 4,
                  }}
                >
                  <span
                    style={{
                      width: 5,
                      height: 5,
                      borderRadius: "50%",
                      background: "#22c55e",
                      display: "inline-block",
                    }}
                  />
                  Live
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </AdminLayout>
  );
}

export default DashboardPage;
