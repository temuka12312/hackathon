import { useEffect, useState, useMemo } from "react";
import {
  Users,
  UserRound,
  ShieldCheck,
  Search,
  ChevronRight,
  ChevronLeft,
  RefreshCw,
} from "lucide-react";

import AdminLayout from "../../components/layout/AdminLayout";
import { getUsers, type User } from "../../api/user.api";

const ITEMS_PER_PAGE = 10;

/* ---------------- UI HELPERS ---------------- */

function getRoleConfig(role: string) {
  const r = (role || "user").toLowerCase();

  if (r.includes("admin")) {
    return {
      label: "Admin",
      color: "#f43f5e",
      bg: "rgba(244,63,94,0.09)",
      border: "rgba(244,63,94,0.22)",
      glow: "rgba(244,63,94,0.35)",
      Icon: ShieldCheck,
    };
  }

  if (r.includes("manager")) {
    return {
      label: "Manager",
      color: "#f97316",
      bg: "rgba(249,115,22,0.09)",
      border: "rgba(249,115,22,0.22)",
      glow: "rgba(249,115,22,0.35)",
      Icon: Users,
    };
  }

  return {
    label: "User",
    color: "#22c55e",
    bg: "rgba(34,197,94,0.09)",
    border: "rgba(34,197,94,0.22)",
    glow: "rgba(34,197,94,0.35)",
    Icon: UserRound,
  };
}

function timeAgo(dateStr?: string) {
  if (!dateStr) return "";
  const d = new Date(dateStr);
  if (isNaN(d.getTime())) return "";

  const diff = Math.floor((Date.now() - d.getTime()) / 1000);

  if (diff < 60) return `${diff}s ago`;
  if (diff < 3600) return `${Math.floor(diff / 60)}m ago`;
  if (diff < 86400) return `${Math.floor(diff / 3600)}h ago`;
  return `${Math.floor(diff / 86400)}d ago`;
}

/* ---------------- PAGE ---------------- */

export default function UsersPage() {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState("");
  const [currentPage, setCurrentPage] = useState(1);

  useEffect(() => {
    loadUsers();
  }, []);

  async function loadUsers() {
    setLoading(true);
    try {
      const data = await getUsers();
      setUsers(data);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  }

  const filtered = useMemo(() => {
    const q = search.toLowerCase();
    return users.filter(
      (u) =>
        (u.name || "").toLowerCase().includes(q) ||
        (u.email || "").toLowerCase().includes(q),
    );
  }, [users, search]);

  const totalPages = Math.max(1, Math.ceil(filtered.length / ITEMS_PER_PAGE));
  const safePage = Math.min(currentPage, totalPages);

  const paginated = filtered.slice(
    (safePage - 1) * ITEMS_PER_PAGE,
    safePage * ITEMS_PER_PAGE,
  );

  const stats = [
    { label: "Total", value: users.length, color: "#388bfd" },
    { label: "Active", value: users.length, color: "#22c55e" },
    {
      label: "Admins",
      value: users.filter((u) => u.role === "admin").length,
      color: "#f43f5e",
    },
  ];

  function getPageNumbers() {
    if (totalPages <= 7)
      return Array.from({ length: totalPages }, (_, i) => i + 1);

    if (safePage <= 4) return [1, 2, 3, 4, 5, "…", totalPages];
    if (safePage >= totalPages - 3)
      return [
        1,
        "…",
        totalPages - 4,
        totalPages - 3,
        totalPages - 2,
        totalPages - 1,
        totalPages,
      ];

    return [1, "…", safePage - 1, safePage, safePage + 1, "…", totalPages];
  }

  return (
    <AdminLayout>
      <style>{`
        .up-wrap {
          font-family: 'DM Sans', sans-serif;
          padding: 32px;
          min-height: 100vh;
          background: #080C14;
          color: white;
        }

        .up-inner { position: relative; z-index: 1; }

        .up-header {
          display: flex;
          justify-content: space-between;
          align-items: flex-end;
          margin-bottom: 22px;
        }

        .up-title {
          font-family: 'Syne', sans-serif;
          font-size: 26px;
          font-weight: 800;
        }

        .up-title span { color: #388bfd; }

        .up-sub {
          font-size: 12px;
          color: rgba(255,255,255,0.25);
          margin-top: 6px;
        }

        .refresh-btn {
          display: flex;
          align-items: center;
          gap: 6px;
          padding: 8px 12px;
          background: rgba(56,139,253,0.08);
          border: 1px solid rgba(56,139,253,0.2);
          border-radius: 8px;
          color: #388bfd;
          font-size: 12px;
          cursor: pointer;
        }

        .summary {
          display: flex;
          gap: 10px;
          margin-bottom: 14px;
        }

        .summary-box {
          flex: 1;
          background: rgba(255,255,255,0.03);
          border: 1px solid rgba(255,255,255,0.06);
          border-radius: 12px;
          padding: 14px;
        }

        .summary-val {
          font-family: 'Syne';
          font-size: 22px;
          font-weight: 800;
        }

        .summary-label {
          font-size: 10px;
          color: rgba(255,255,255,0.25);
          text-transform: uppercase;
          letter-spacing: 0.1em;
        }

        .toolbar {
          display: flex;
          gap: 10px;
          margin-bottom: 12px;
        }

        .search {
          flex: 1;
          display: flex;
          align-items: center;
          gap: 8px;
          background: rgba(255,255,255,0.03);
          border: 1px solid rgba(255,255,255,0.07);
          border-radius: 10px;
          padding: 0 12px;
          height: 40px;
        }

        .search input {
          background: none;
          border: none;
          outline: none;
          color: white;
          width: 100%;
        }

        /* TABLE STYLE (same as reports) */
        .table-panel {
          background: rgba(255,255,255,0.02);
          border: 1px solid rgba(255,255,255,0.06);
          border-radius: 14px;
          overflow: hidden;
        }

        .table-head, .user-row {
          display: grid;
          grid-template-columns: 52px 1fr 200px 140px 120px 40px;
          padding: 12px 18px;
        }

        .table-head {
          border-bottom: 1px solid rgba(255,255,255,0.06);
          font-size: 10px;
          text-transform: uppercase;
          letter-spacing: 0.12em;
          color: rgba(255,255,255,0.2);
        }

        .user-row {
          border-bottom: 1px solid rgba(255,255,255,0.04);
          align-items: center;
          transition: 0.2s;
        }

        .user-row:hover {
          background: rgba(255,255,255,0.03);
        }

        .index {
          font-family: 'Syne';
          font-size: 11px;
          color: rgba(255,255,255,0.2);
        }

        .name {
          font-size: 13px;
          font-weight: 500;
        }

        .email {
          font-size: 11px;
          color: rgba(255,255,255,0.3);
        }

        .role-badge {
          display: inline-flex;
          gap: 5px;
          align-items: center;
          font-size: 10px;
          padding: 4px 8px;
          border-radius: 6px;
          border: 1px solid;
        }

        .time {
          font-size: 11px;
          color: rgba(255,255,255,0.3);
        }

        .arrow {
          opacity: 0.2;
        }

        .pagination {
          display: flex;
          justify-content: center;
          gap: 6px;
          padding: 12px;
        }

        .page {
          padding: 6px 10px;
          border-radius: 6px;
          background: rgba(255,255,255,0.03);
          border: 1px solid rgba(255,255,255,0.06);
          cursor: pointer;
          font-size: 12px;
        }

        .active {
          background: rgba(56,139,253,0.15);
          border-color: rgba(56,139,253,0.3);
          color: #388bfd;
        }
      `}</style>

      <div className="up-wrap">
        <div className="up-inner">
          {/* HEADER */}
          <div className="up-header">
            <div>
              <div className="up-title">
                Platform <span>Users</span>
              </div>
              <div className="up-sub">Manage all registered accounts</div>
            </div>

            <button className="refresh-btn" onClick={loadUsers}>
              <RefreshCw size={12} />
              Refresh
            </button>
          </div>

          {/* SUMMARY */}
          <div className="summary">
            {stats.map((s) => (
              <div className="summary-box" key={s.label}>
                <div className="summary-val" style={{ color: s.color }}>
                  {s.value}
                </div>
                <div className="summary-label">{s.label}</div>
              </div>
            ))}
          </div>

          {/* SEARCH */}
          <div className="toolbar">
            <div className="search">
              <Search size={14} />
              <input
                value={search}
                onChange={(e) => {
                  setSearch(e.target.value);
                  setCurrentPage(1);
                }}
                placeholder="Search users..."
              />
            </div>
          </div>

          {/* TABLE */}
          <div className="table-panel">
            <div className="table-head">
              <div>#</div>
              <div>User</div>
              <div>Email</div>
              <div>Role</div>
              <div>Joined</div>
              <div />
            </div>

            {paginated.map((u, i) => {
              const role = getRoleConfig(u.role || "user");
              const Icon = role.Icon;

              return (
                <div className="user-row" key={u._id}>
                  <div className="index">
                    {(safePage - 1) * ITEMS_PER_PAGE + i + 1}
                  </div>

                  <div>
                    <div className="name">{u.name}</div>
                    <div className="email">{u.email}</div>
                  </div>

                  <div className="email">{u.email}</div>

                  <div>
                    <span
                      className="role-badge"
                      style={{
                        color: role.color,
                        background: role.bg,
                        borderColor: role.border,
                      }}
                    >
                      <Icon size={10} />
                      {role.label}
                    </span>
                  </div>

                  <div className="time">{timeAgo(u.createdAt)}</div>

                  <div className="arrow">
                    <ChevronRight size={14} />
                  </div>
                </div>
              );
            })}

            {/* PAGINATION */}
            <div className="pagination">
              <button
                className="page"
                onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
              >
                <ChevronLeft size={14} />
              </button>

              {getPageNumbers().map((p, i) =>
                p === "…" ? (
                  <span key={i} style={{ opacity: 0.2 }}>
                    …
                  </span>
                ) : (
                  <button
                    key={p}
                    className={`page ${safePage === p ? "active" : ""}`}
                    onClick={() => setCurrentPage(p as number)}
                  >
                    {p}
                  </button>
                ),
              )}

              <button
                className="page"
                onClick={() =>
                  setCurrentPage((p) => Math.min(totalPages, p + 1))
                }
              >
                <ChevronRight size={14} />
              </button>
            </div>
          </div>
        </div>
      </div>
    </AdminLayout>
  );
}
