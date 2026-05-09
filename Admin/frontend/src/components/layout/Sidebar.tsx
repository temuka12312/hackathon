import { LayoutDashboard, Map, TriangleAlert, Users, Car } from "lucide-react";
import { NavLink } from "react-router-dom";

const menus = [
  { label: "Dashboard", icon: LayoutDashboard, path: "/", desc: "Overview" },
  { label: "Live Map", icon: Map, path: "/map", desc: "Real-time" },
  {
    label: "Reports",
    icon: TriangleAlert,
    path: "/reports",
    desc: "Analytics",
  },
  { label: "Users", icon: Users, path: "/users", desc: "Management" },
  { label: "Rides", icon: Car, path: "/rides", desc: "Tracking" },
];

function Sidebar() {
  return (
    <>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Syne:wght@700;800&family=DM+Sans:wght@300;400;500&display=swap');

        .sidebar {
          width: 260px;
          height: 100vh;
          background: #080C14;
          display: flex;
          flex-direction: column;
          padding: 0;
          position: relative;
          overflow: hidden;
          flex-shrink: 0;
          border-right: 1px solid rgba(255,255,255,0.04);
        }

        /* Ambient glow at top */
        .sidebar::before {
          content: '';
          position: absolute;
          top: -60px;
          left: -40px;
          width: 220px;
          height: 220px;
          background: radial-gradient(circle, rgba(56,139,253,0.12) 0%, transparent 70%);
          pointer-events: none;
          z-index: 0;
        }

        /* Subtle grid lines */
        .sidebar::after {
          content: '';
          position: absolute;
          inset: 0;
          background-image:
            linear-gradient(rgba(255,255,255,0.015) 1px, transparent 1px),
            linear-gradient(90deg, rgba(255,255,255,0.015) 1px, transparent 1px);
          background-size: 32px 32px;
          pointer-events: none;
          z-index: 0;
        }

        .sidebar-inner {
          position: relative;
          z-index: 1;
          display: flex;
          flex-direction: column;
          height: 100%;
          padding: 28px 20px 24px;
        }

        /* Logo area */
        .logo-block {
          padding-bottom: 28px;
          margin-bottom: 8px;
          border-bottom: 1px solid rgba(255,255,255,0.06);
        }

        .logo-badge {
          display: inline-flex;
          align-items: center;
          gap: 8px;
          margin-bottom: 10px;
        }

        .logo-icon {
          width: 32px;
          height: 32px;
          background: linear-gradient(135deg, #1d6feb 0%, #0f4fbd 100%);
          border-radius: 8px;
          display: flex;
          align-items: center;
          justify-content: center;
          box-shadow: 0 0 16px rgba(29,111,235,0.4);
        }

        .logo-icon svg {
          width: 16px;
          height: 16px;
          fill: none;
          stroke: white;
          stroke-width: 2;
          stroke-linecap: round;
          stroke-linejoin: round;
        }

        .logo-title {
          font-family: 'Syne', sans-serif;
          font-weight: 800;
          font-size: 17px;
          letter-spacing: 0.04em;
          color: #ffffff;
          line-height: 1;
        }

        .logo-title span {
          color: #388bfd;
        }

        .logo-sub {
          font-family: 'DM Sans', sans-serif;
          font-weight: 300;
          font-size: 11px;
          letter-spacing: 0.14em;
          text-transform: uppercase;
          color: rgba(255,255,255,0.28);
          padding-left: 2px;
        }

        /* Status pill */
        .status-pill {
          display: inline-flex;
          align-items: center;
          gap: 6px;
          margin-top: 12px;
          background: rgba(34,197,94,0.08);
          border: 1px solid rgba(34,197,94,0.18);
          border-radius: 20px;
          padding: 4px 10px;
        }

        .status-dot {
          width: 6px;
          height: 6px;
          border-radius: 50%;
          background: #22c55e;
          box-shadow: 0 0 6px rgba(34,197,94,0.8);
          animation: pulse-dot 2s ease-in-out infinite;
        }

        @keyframes pulse-dot {
          0%, 100% { opacity: 1; box-shadow: 0 0 6px rgba(34,197,94,0.8); }
          50% { opacity: 0.6; box-shadow: 0 0 10px rgba(34,197,94,0.4); }
        }

        .status-text {
          font-family: 'DM Sans', sans-serif;
          font-size: 10px;
          font-weight: 500;
          letter-spacing: 0.08em;
          color: rgba(34,197,94,0.85);
          text-transform: uppercase;
        }

        /* Nav section */
        .nav-label {
          font-family: 'DM Sans', sans-serif;
          font-size: 10px;
          font-weight: 500;
          letter-spacing: 0.16em;
          text-transform: uppercase;
          color: rgba(255,255,255,0.2);
          padding: 0 4px;
          margin-bottom: 8px;
          margin-top: 4px;
        }

        .nav-list {
          display: flex;
          flex-direction: column;
          gap: 3px;
          flex: 1;
        }

        /* Nav items */
        .nav-item {
          display: flex;
          align-items: center;
          gap: 12px;
          padding: 10px 12px;
          border-radius: 10px;
          text-decoration: none;
          position: relative;
          transition: all 0.2s ease;
          group: true;
          border: 1px solid transparent;
        }

        .nav-item:hover {
          background: rgba(255,255,255,0.04);
          border-color: rgba(255,255,255,0.05);
        }

        .nav-item.active {
          background: linear-gradient(135deg, rgba(29,111,235,0.18) 0%, rgba(29,111,235,0.08) 100%);
          border-color: rgba(56,139,253,0.2);
          box-shadow: inset 0 1px 0 rgba(255,255,255,0.05);
        }

        /* Active left accent */
        .nav-item.active::before {
          content: '';
          position: absolute;
          left: -1px;
          top: 50%;
          transform: translateY(-50%);
          width: 3px;
          height: 60%;
          background: linear-gradient(180deg, #388bfd, #1d6feb);
          border-radius: 0 3px 3px 0;
          box-shadow: 2px 0 8px rgba(56,139,253,0.5);
        }

        .nav-icon-wrap {
          width: 34px;
          height: 34px;
          border-radius: 8px;
          display: flex;
          align-items: center;
          justify-content: center;
          background: rgba(255,255,255,0.04);
          flex-shrink: 0;
          transition: all 0.2s ease;
          color: rgba(255,255,255,0.35);
        }

        .nav-item:hover .nav-icon-wrap {
          background: rgba(255,255,255,0.07);
          color: rgba(255,255,255,0.65);
        }

        .nav-item.active .nav-icon-wrap {
          background: rgba(56,139,253,0.18);
          color: #388bfd;
          box-shadow: 0 0 12px rgba(56,139,253,0.2);
        }

        .nav-text {
          flex: 1;
          min-width: 0;
        }

        .nav-text-label {
          font-family: 'DM Sans', sans-serif;
          font-size: 13.5px;
          font-weight: 500;
          color: rgba(255,255,255,0.55);
          line-height: 1;
          transition: color 0.2s;
          display: block;
        }

        .nav-text-desc {
          font-family: 'DM Sans', sans-serif;
          font-size: 10.5px;
          font-weight: 300;
          color: rgba(255,255,255,0.2);
          margin-top: 2px;
          display: block;
          transition: color 0.2s;
        }

        .nav-item:hover .nav-text-label {
          color: rgba(255,255,255,0.8);
        }

        .nav-item:hover .nav-text-desc {
          color: rgba(255,255,255,0.35);
        }

        .nav-item.active .nav-text-label {
          color: rgba(255,255,255,0.95);
          font-weight: 500;
        }

        .nav-item.active .nav-text-desc {
          color: rgba(56,139,253,0.7);
        }

        /* Chevron */
        .nav-arrow {
          opacity: 0;
          transition: opacity 0.2s, transform 0.2s;
          color: rgba(255,255,255,0.2);
          transform: translateX(-4px);
        }

        .nav-item:hover .nav-arrow,
        .nav-item.active .nav-arrow {
          opacity: 1;
          transform: translateX(0);
        }

        .nav-item.active .nav-arrow {
          color: rgba(56,139,253,0.6);
        }

        /* Bottom user block */
        .sidebar-footer {
          margin-top: auto;
          padding-top: 20px;
          border-top: 1px solid rgba(255,255,255,0.06);
        }

        .user-block {
          display: flex;
          align-items: center;
          gap: 10px;
          padding: 10px 12px;
          border-radius: 10px;
          background: rgba(255,255,255,0.03);
          border: 1px solid rgba(255,255,255,0.05);
          cursor: pointer;
          transition: all 0.2s;
        }

        .user-block:hover {
          background: rgba(255,255,255,0.05);
          border-color: rgba(255,255,255,0.08);
        }

        .user-avatar {
          width: 32px;
          height: 32px;
          border-radius: 8px;
          background: linear-gradient(135deg, #1d4ed8 0%, #7c3aed 100%);
          display: flex;
          align-items: center;
          justify-content: center;
          font-family: 'Syne', sans-serif;
          font-size: 12px;
          font-weight: 700;
          color: white;
          flex-shrink: 0;
        }

        .user-info {
          flex: 1;
          min-width: 0;
        }

        .user-name {
          font-family: 'DM Sans', sans-serif;
          font-size: 12.5px;
          font-weight: 500;
          color: rgba(255,255,255,0.75);
          display: block;
          white-space: nowrap;
          overflow: hidden;
          text-overflow: ellipsis;
        }

        .user-role {
          font-family: 'DM Sans', sans-serif;
          font-size: 10px;
          font-weight: 300;
          color: rgba(255,255,255,0.25);
          display: block;
          text-transform: uppercase;
          letter-spacing: 0.08em;
        }

        .user-more {
          color: rgba(255,255,255,0.2);
          flex-shrink: 0;
        }
      `}</style>

      <div className="sidebar">
        <div className="sidebar-inner">
          {/* Logo */}
          <div className="logo-block">
            <div className="logo-badge">
              <div className="logo-icon">
                <svg viewBox="0 0 24 24">
                  <polygon points="12 2 22 8.5 22 15.5 12 22 2 15.5 2 8.5" />
                  <line x1="12" y1="2" x2="12" y2="22" />
                  <line x1="2" y1="8.5" x2="22" y2="8.5" />
                  <line x1="2" y1="15.5" x2="22" y2="15.5" />
                </svg>
              </div>
              <div className="logo-title">
                NEXT GEN <span>UB</span>
              </div>
            </div>
            <div className="logo-sub">Smart City Dashboard</div>
            <div className="status-pill">
              <div className="status-dot" />
              <span className="status-text">All Systems Live</span>
            </div>
          </div>

          {/* Nav */}
          <div className="nav-label">Navigation</div>
          <nav className="nav-list">
            {menus.map((menu) => {
              const Icon = menu.icon;
              return (
                <NavLink
                  key={menu.path}
                  to={menu.path}
                  end={menu.path === "/"}
                  className={({ isActive }) =>
                    `nav-item${isActive ? " active" : ""}`
                  }
                >
                  <div className="nav-icon-wrap">
                    <Icon size={16} />
                  </div>
                  <div className="nav-text">
                    <span className="nav-text-label">{menu.label}</span>
                    <span className="nav-text-desc">{menu.desc}</span>
                  </div>
                  <svg
                    className="nav-arrow"
                    width="14"
                    height="14"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  >
                    <path d="M9 18l6-6-6-6" />
                  </svg>
                </NavLink>
              );
            })}
          </nav>

          {/* Footer */}
          <div className="sidebar-footer">
            <div className="user-block">
              <div className="user-avatar">AD</div>
              <div className="user-info">
                <span className="user-name">Admin User</span>
                <span className="user-role">Super Admin</span>
              </div>
              <svg
                className="user-more"
                width="14"
                height="14"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <circle cx="12" cy="5" r="1" />
                <circle cx="12" cy="12" r="1" />
                <circle cx="12" cy="19" r="1" />
              </svg>
            </div>
          </div>
        </div>
      </div>
    </>
  );
}

export default Sidebar;
