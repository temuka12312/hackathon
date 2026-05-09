import { useEffect, useState, useMemo } from "react";
import {
  TriangleAlert,
  Car,
  AlertOctagon,
  Clock,
  MapPin,
  ChevronRight,
  ChevronLeft,
  Search,
  ArrowUpRight,
  CheckCircle2,
  XCircle,
  Loader2,
  RefreshCw,
} from "lucide-react";
import AdminLayout from "../../components/layout/AdminLayout";
import { getReports } from "../../api/report.api";

const ITEMS_PER_PAGE = 10;

function getSeverityConfig(report: any) {
  const type = (report.type || "").toLowerCase();
  if (type.includes("accident") || type.includes("crash")) {
    return {
      label: "Critical",
      color: "#f43f5e",
      bg: "rgba(244,63,94,0.09)",
      border: "rgba(244,63,94,0.22)",
      glow: "rgba(244,63,94,0.35)",
    };
  }
  if (type.includes("traffic") || type.includes("congestion")) {
    return {
      label: "High",
      color: "#f97316",
      bg: "rgba(249,115,22,0.09)",
      border: "rgba(249,115,22,0.22)",
      glow: "rgba(249,115,22,0.35)",
    };
  }
  return {
    label: "Medium",
    color: "#eab308",
    bg: "rgba(234,179,8,0.09)",
    border: "rgba(234,179,8,0.22)",
    glow: "rgba(234,179,8,0.35)",
  };
}

function getStatusConfig(report: any) {
  const status = (report.status || "active").toLowerCase();
  if (status === "resolved")
    return {
      label: "Resolved",
      color: "#22c55e",
      bg: "rgba(34,197,94,0.08)",
      border: "rgba(34,197,94,0.2)",
      Icon: CheckCircle2,
    };
  if (status === "investigating")
    return {
      label: "Investigating",
      color: "#f97316",
      bg: "rgba(249,115,22,0.08)",
      border: "rgba(249,115,22,0.2)",
      Icon: Loader2,
    };
  return {
    label: "Active",
    color: "#f43f5e",
    bg: "rgba(244,63,94,0.08)",
    border: "rgba(244,63,94,0.2)",
    Icon: XCircle,
  };
}

function getTypeIcon(report: any) {
  const type = (report.type || "").toLowerCase();
  if (type.includes("accident") || type.includes("crash")) return AlertOctagon;
  if (type.includes("traffic") || type.includes("congestion")) return Car;
  return TriangleAlert;
}

function formatDate(dateStr: string) {
  if (!dateStr) return "—";
  const d = new Date(dateStr);
  if (isNaN(d.getTime())) return dateStr;
  return d.toLocaleTimeString("en-US", { hour: "2-digit", minute: "2-digit" });
}

function timeAgo(dateStr: string) {
  if (!dateStr) return "";
  const d = new Date(dateStr);
  if (isNaN(d.getTime())) return "";
  const diff = Math.floor((Date.now() - d.getTime()) / 1000);
  if (diff < 60) return `${diff}s ago`;
  if (diff < 3600) return `${Math.floor(diff / 60)} min ago`;
  if (diff < 86400) return `${Math.floor(diff / 3600)} hr ago`;
  return `${Math.floor(diff / 86400)}d ago`;
}

function ReportsPage() {
  const [reports, setReports] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState("");
  const [filterType, setFilterType] = useState("All");
  const [currentPage, setCurrentPage] = useState(1);

  useEffect(() => {
    loadReports();
  }, []);

  async function loadReports() {
    setLoading(true);
    setError(null);
    try {
      const data = await getReports();
      setReports(data);
    } catch (err: any) {
      setError("Failed to load reports.");
      console.error(err);
    } finally {
      setLoading(false);
    }
  }

  const types = useMemo(() => {
    const all = reports.map((r) => r.type).filter(Boolean);
    return ["All", ...Array.from(new Set<string>(all))];
  }, [reports]);

  const filtered = useMemo(() => {
    return reports.filter((r) => {
      const matchesType = filterType === "All" || r.type === filterType;
      const q = search.toLowerCase();
      const matchesSearch =
        !q ||
        (r.title || "").toLowerCase().includes(q) ||
        (r.description || "").toLowerCase().includes(q) ||
        (r.type || "").toLowerCase().includes(q) ||
        (r.location || "").toLowerCase().includes(q);
      return matchesType && matchesSearch;
    });
  }, [reports, search, filterType]);

  const totalPages = Math.max(1, Math.ceil(filtered.length / ITEMS_PER_PAGE));
  const safePage = Math.min(currentPage, totalPages);
  const paginated = filtered.slice(
    (safePage - 1) * ITEMS_PER_PAGE,
    safePage * ITEMS_PER_PAGE,
  );

  useEffect(() => {
    setCurrentPage(1);
  }, [search, filterType]);

  const summaryStats = [
    { label: "Total", value: reports.length, color: "#388bfd" },
    {
      label: "Active",
      value: reports.filter(
        (r) => (r.status || "active").toLowerCase() === "active",
      ).length,
      color: "#f43f5e",
    },
    {
      label: "Resolved",
      value: reports.filter(
        (r) => (r.status || "").toLowerCase() === "resolved",
      ).length,
      color: "#22c55e",
    },
  ];

  function getPageNumbers(): (number | "…")[] {
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
        @import url('https://fonts.googleapis.com/css2?family=Syne:wght@700;800&family=DM+Sans:wght@300;400;500&display=swap');

        .rp-wrap {
          font-family: 'DM Sans', sans-serif;
          padding: 32px;
          min-height: 100vh;
          background: #080C14;
          color: white;
          position: relative;
        }
        .rp-wrap::before {
          content: '';
          position: fixed;
          top: 0; right: 0;
          width: 500px; height: 500px;
          background: radial-gradient(circle at 80% 10%, rgba(244,63,94,0.06) 0%, transparent 60%);
          pointer-events: none;
          z-index: 0;
        }
        .rp-inner { position: relative; z-index: 1; }

        .rp-header {
          display: flex;
          align-items: flex-end;
          justify-content: space-between;
          margin-bottom: 24px;
        }
        .rp-title {
          font-family: 'Syne', sans-serif;
          font-size: 26px;
          font-weight: 800;
          letter-spacing: -0.01em;
          color: #fff;
          line-height: 1;
        }
        .rp-title span { color: #f43f5e; }
        .rp-sub {
          font-size: 12px;
          font-weight: 300;
          color: rgba(255,255,255,0.25);
          letter-spacing: 0.06em;
          margin-top: 6px;
        }

        .refresh-btn {
          display: flex;
          align-items: center;
          gap: 6px;
          padding: 8px 14px;
          background: rgba(244,63,94,0.08);
          border: 1px solid rgba(244,63,94,0.2);
          border-radius: 9px;
          color: #f43f5e;
          font-family: 'DM Sans', sans-serif;
          font-size: 12.5px;
          font-weight: 500;
          cursor: pointer;
          transition: all 0.2s;
        }
        .refresh-btn:hover:not(:disabled) { background: rgba(244,63,94,0.14); border-color: rgba(244,63,94,0.35); }
        .refresh-btn:disabled { opacity: 0.4; cursor: not-allowed; }

        .summary-bar {
          display: flex;
          gap: 12px;
          margin-bottom: 18px;
          animation: fadeUp 0.35s ease both;
        }
        .summary-tile {
          flex: 1;
          background: rgba(255,255,255,0.025);
          border: 1px solid rgba(255,255,255,0.06);
          border-radius: 12px;
          padding: 16px 20px;
          display: flex;
          align-items: center;
          justify-content: space-between;
        }
        .summary-val {
          font-family: 'Syne', sans-serif;
          font-size: 26px;
          font-weight: 800;
          line-height: 1;
        }
        .summary-label {
          font-size: 10.5px;
          font-weight: 400;
          letter-spacing: 0.1em;
          text-transform: uppercase;
          color: rgba(255,255,255,0.25);
          margin-top: 5px;
        }

        .toolbar {
          display: flex;
          gap: 10px;
          margin-bottom: 12px;
          animation: fadeUp 0.35s ease 0.05s both;
          align-items: center;
          flex-wrap: wrap;
        }
        .search-box {
          flex: 1;
          min-width: 200px;
          display: flex;
          align-items: center;
          gap: 8px;
          background: rgba(255,255,255,0.03);
          border: 1px solid rgba(255,255,255,0.07);
          border-radius: 10px;
          padding: 0 14px;
          height: 40px;
          color: rgba(255,255,255,0.3);
          transition: border-color 0.2s;
        }
        .search-box:focus-within {
          border-color: rgba(244,63,94,0.3);
        }
        .search-box input {
          background: transparent;
          border: none;
          outline: none;
          color: rgba(255,255,255,0.75);
          font-family: 'DM Sans', sans-serif;
          font-size: 13px;
          flex: 1;
        }
        .search-box input::placeholder { color: rgba(255,255,255,0.2); }

        .filter-chips { display: flex; gap: 6px; flex-wrap: wrap; }
        .chip {
          padding: 6px 13px;
          border-radius: 20px;
          font-family: 'DM Sans', sans-serif;
          font-size: 11.5px;
          font-weight: 500;
          cursor: pointer;
          border: 1px solid rgba(255,255,255,0.08);
          background: rgba(255,255,255,0.03);
          color: rgba(255,255,255,0.4);
          transition: all 0.18s;
          white-space: nowrap;
        }
        .chip:hover { background: rgba(255,255,255,0.07); color: rgba(255,255,255,0.7); }
        .chip.chip-active { background: rgba(244,63,94,0.12); border-color: rgba(244,63,94,0.3); color: #f43f5e; }

        .table-panel {
          background: rgba(255,255,255,0.02);
          border: 1px solid rgba(255,255,255,0.06);
          border-radius: 14px;
          overflow: hidden;
          animation: fadeUp 0.35s ease 0.1s both;
        }
        .table-head {
          display: grid;
          grid-template-columns: 52px 1fr 160px 110px 130px 120px 32px;
          padding: 10px 20px;
          border-bottom: 1px solid rgba(255,255,255,0.06);
          background: rgba(255,255,255,0.02);
        }
        .th {
          font-size: 10px;
          font-weight: 500;
          letter-spacing: 0.14em;
          text-transform: uppercase;
          color: rgba(255,255,255,0.2);
        }

        .report-row {
          display: grid;
          grid-template-columns: 52px 1fr 160px 110px 130px 120px 32px;
          padding: 13px 20px;
          border-bottom: 1px solid rgba(255,255,255,0.04);
          align-items: center;
          cursor: pointer;
          transition: background 0.2s;
          position: relative;
        }
        .report-row:last-child { border-bottom: none; }
        .report-row:hover { background: rgba(255,255,255,0.025); }
        .report-row.critical-row::before {
          content: '';
          position: absolute;
          left: 0; top: 20%; height: 60%;
          width: 3px;
          background: #f43f5e;
          border-radius: 0 3px 3px 0;
          box-shadow: 2px 0 8px rgba(244,63,94,0.5);
        }

        .row-index {
          font-family: 'Syne', sans-serif;
          font-size: 11px;
          font-weight: 700;
          color: rgba(255,255,255,0.2);
        }
        .row-title-main {
          font-size: 13px;
          font-weight: 500;
          color: rgba(255,255,255,0.85);
          display: block;
          white-space: nowrap;
          overflow: hidden;
          text-overflow: ellipsis;
        }
        .row-title-sub {
          font-size: 11px;
          font-weight: 300;
          color: rgba(255,255,255,0.25);
          margin-top: 2px;
          display: block;
          white-space: nowrap;
          overflow: hidden;
          text-overflow: ellipsis;
        }
        .row-location {
          display: flex;
          flex-direction: column;
          gap: 2px;
        }
        .row-loc-name {
          font-size: 12px;
          color: rgba(255,255,255,0.5);
          display: flex;
          align-items: center;
          gap: 4px;
          white-space: nowrap;
          overflow: hidden;
          text-overflow: ellipsis;
        }
        .row-loc-sub {
          font-size: 10.5px;
          font-weight: 300;
          color: rgba(255,255,255,0.2);
        }

        .severity-badge {
          display: inline-flex;
          align-items: center;
          gap: 5px;
          padding: 4px 9px;
          border-radius: 6px;
          font-size: 10.5px;
          font-weight: 600;
          letter-spacing: 0.06em;
          text-transform: uppercase;
          border: 1px solid;
        }
        .sev-dot { width: 5px; height: 5px; border-radius: 50%; flex-shrink: 0; }

        .status-badge {
          display: inline-flex;
          align-items: center;
          gap: 5px;
          padding: 4px 9px;
          border-radius: 6px;
          font-size: 10.5px;
          font-weight: 500;
          border: 1px solid;
        }

        .row-time { display: flex; flex-direction: column; gap: 2px; }
        .row-time-main {
          font-size: 12px;
          font-weight: 500;
          color: rgba(255,255,255,0.5);
          display: flex;
          align-items: center;
          gap: 4px;
        }
        .row-time-ago {
          font-size: 10.5px;
          font-weight: 300;
          color: rgba(255,255,255,0.2);
        }

        .row-arrow {
          color: rgba(255,255,255,0.14);
          transition: color 0.2s, transform 0.2s;
        }
        .report-row:hover .row-arrow { color: rgba(255,255,255,0.5); transform: translateX(2px); }

        .state-box {
          padding: 60px 20px;
          text-align: center;
          color: rgba(255,255,255,0.25);
          font-size: 13px;
          font-weight: 300;
          letter-spacing: 0.04em;
        }

        .table-footer {
          display: flex;
          align-items: center;
          justify-content: space-between;
          padding: 12px 20px;
          border-top: 1px solid rgba(255,255,255,0.05);
          background: rgba(255,255,255,0.01);
          flex-wrap: wrap;
          gap: 8px;
        }
        .footer-count {
          font-size: 12px;
          font-weight: 300;
          color: rgba(255,255,255,0.25);
        }
        .pagination { display: flex; gap: 4px; align-items: center; }
        .page-btn {
          min-width: 30px;
          height: 30px;
          padding: 0 6px;
          border-radius: 7px;
          border: 1px solid rgba(255,255,255,0.07);
          background: transparent;
          color: rgba(255,255,255,0.3);
          font-family: 'DM Sans', sans-serif;
          font-size: 12px;
          cursor: pointer;
          transition: all 0.18s;
          display: flex;
          align-items: center;
          justify-content: center;
        }
        .page-btn:hover:not(:disabled) { background: rgba(255,255,255,0.05); color: rgba(255,255,255,0.7); }
        .page-btn.page-active { background: rgba(244,63,94,0.14); border-color: rgba(244,63,94,0.3); color: #f43f5e; font-weight: 600; }
        .page-btn:disabled { opacity: 0.25; cursor: not-allowed; }

        @keyframes fadeUp {
          from { opacity: 0; transform: translateY(10px); }
          to   { opacity: 1; transform: translateY(0); }
        }
        @keyframes spin { to { transform: rotate(360deg); } }
        .spinning { animation: spin 0.9s linear infinite; }
      `}</style>

      <div className="rp-wrap">
        <div className="rp-inner">
          {/* Header */}
          <div className="rp-header">
            <div>
              <div className="rp-title">
                Traffic <span>Reports</span>
              </div>
              <div className="rp-sub">Ulaanbaatar · Live data</div>
            </div>
            <button
              className="refresh-btn"
              onClick={loadReports}
              disabled={loading}
            >
              <RefreshCw
                size={13}
                style={
                  loading ? { animation: "spin 0.9s linear infinite" } : {}
                }
              />
              {loading ? "Loading…" : "Refresh"}
            </button>
          </div>

          {/* Summary */}
          <div className="summary-bar">
            {summaryStats.map((s) => (
              <div className="summary-tile" key={s.label}>
                <div>
                  <div className="summary-val" style={{ color: s.color }}>
                    {s.value}
                  </div>
                  <div className="summary-label">{s.label}</div>
                </div>
                <ArrowUpRight
                  size={14}
                  style={{ color: "rgba(255,255,255,0.15)" }}
                />
              </div>
            ))}
          </div>

          {/* Toolbar */}
          <div className="toolbar">
            <div className="search-box">
              <Search size={14} />
              <input
                placeholder="Search title, description, type, location…"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
              />
            </div>
            {types.length > 1 && (
              <div className="filter-chips">
                {types.map((t) => (
                  <button
                    key={t}
                    className={`chip ${filterType === t ? "chip-active" : ""}`}
                    onClick={() => setFilterType(t)}
                  >
                    {t}
                  </button>
                ))}
              </div>
            )}
          </div>

          {/* Table */}
          <div className="table-panel">
            <div className="table-head">
              <div className="th">#</div>
              <div className="th">Report</div>
              <div className="th">Location</div>
              <div className="th">Severity</div>
              <div className="th">Status</div>
              <div className="th">Time</div>
              <div className="th" />
            </div>

            {loading ? (
              <div className="state-box">
                <Loader2
                  size={28}
                  style={{
                    margin: "0 auto 12px",
                    display: "block",
                    opacity: 0.25,
                    animation: "spin 0.9s linear infinite",
                  }}
                />
                Loading reports…
              </div>
            ) : error ? (
              <div className="state-box">
                <TriangleAlert
                  size={28}
                  style={{
                    margin: "0 auto 12px",
                    display: "block",
                    opacity: 0.25,
                  }}
                />
                {error}
              </div>
            ) : paginated.length === 0 ? (
              <div className="state-box">
                <Search
                  size={28}
                  style={{
                    margin: "0 auto 12px",
                    display: "block",
                    opacity: 0.25,
                  }}
                />
                No reports match your search.
              </div>
            ) : (
              paginated.map((report, i) => {
                const sev = getSeverityConfig(report);
                const st = getStatusConfig(report);
                const StatusIcon = st.Icon;
                const ReportIcon = getTypeIcon(report);
                const globalIdx = (safePage - 1) * ITEMS_PER_PAGE + i + 1;

                return (
                  <div
                    key={report._id}
                    className={`report-row${sev.label === "Critical" ? " critical-row" : ""}`}
                  >
                    <div className="row-index">{globalIdx}</div>

                    <div style={{ minWidth: 0 }}>
                      <span className="row-title-main">
                        {report.title || "Untitled Report"}
                      </span>
                      <span className="row-title-sub">
                        {report.description || report.type || "—"}
                      </span>
                    </div>

                    <div className="row-location">
                      <span className="row-loc-name">
                        <MapPin
                          size={10}
                          style={{ opacity: 0.4, flexShrink: 0 }}
                        />
                        {report.location || "Unknown location"}
                      </span>
                      <span className="row-loc-sub">
                        {report.district || report.type || ""}
                      </span>
                    </div>

                    <div>
                      <span
                        className="severity-badge"
                        style={{
                          color: sev.color,
                          background: sev.bg,
                          borderColor: sev.border,
                        }}
                      >
                        <span
                          className="sev-dot"
                          style={{
                            background: sev.color,
                            boxShadow: `0 0 5px ${sev.glow}`,
                          }}
                        />
                        {sev.label}
                      </span>
                    </div>

                    <div>
                      <span
                        className="status-badge"
                        style={{
                          color: st.color,
                          background: st.bg,
                          borderColor: st.border,
                        }}
                      >
                        <StatusIcon size={10} />
                        {st.label}
                      </span>
                    </div>

                    <div className="row-time">
                      <span className="row-time-main">
                        <Clock size={10} style={{ opacity: 0.4 }} />
                        {formatDate(report.createdAt || report.date)}
                      </span>
                      <span className="row-time-ago">
                        {timeAgo(report.createdAt || report.date)}
                      </span>
                    </div>

                    <div className="row-arrow">
                      <ChevronRight size={15} />
                    </div>
                  </div>
                );
              })
            )}

            {/* Footer */}
            {!loading && !error && filtered.length > 0 && (
              <div className="table-footer">
                <span className="footer-count">
                  Showing {(safePage - 1) * ITEMS_PER_PAGE + 1}–
                  {Math.min(safePage * ITEMS_PER_PAGE, filtered.length)} of{" "}
                  {filtered.length} report{filtered.length !== 1 ? "s" : ""}
                </span>
                <div className="pagination">
                  <button
                    className="page-btn"
                    onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
                    disabled={safePage === 1}
                  >
                    <ChevronLeft size={13} />
                  </button>

                  {getPageNumbers().map((p, i) =>
                    p === "…" ? (
                      <button
                        key={`e${i}`}
                        className="page-btn"
                        disabled
                        style={{ opacity: 0.2 }}
                      >
                        …
                      </button>
                    ) : (
                      <button
                        key={p}
                        className={`page-btn${p === safePage ? " page-active" : ""}`}
                        onClick={() => setCurrentPage(p as number)}
                      >
                        {p}
                      </button>
                    ),
                  )}

                  <button
                    className="page-btn"
                    onClick={() =>
                      setCurrentPage((p) => Math.min(totalPages, p + 1))
                    }
                    disabled={safePage === totalPages}
                  >
                    <ChevronRight size={13} />
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </AdminLayout>
  );
}

export default ReportsPage;
