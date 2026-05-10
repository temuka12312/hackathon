import polyline from "@mapbox/polyline";
import { TraveledRoute } from "../models/TraveledRoute";

type Point = { lat: number; lng: number; ele?: number };

type SaveRouteInput = {
  transportMode: "car" | "walk" | "heavy" | "wheelchair";
  polyline: Point[];
  startTime: Date | string;
  endTime: Date | string;
};

function haversineM(a: Point, b: Point): number {
  const R = 6_371_000;
  const dLat = ((b.lat - a.lat) * Math.PI) / 180;
  const dLng = ((b.lng - a.lng) * Math.PI) / 180;
  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((a.lat * Math.PI) / 180) *
      Math.cos((b.lat * Math.PI) / 180) *
      Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.asin(Math.sqrt(h));
}

function crossTrackM(p: Point, a: Point, b: Point): number {
  const ab = haversineM(a, b);
  if (ab === 0) return haversineM(p, a);
  const ap = haversineM(a, p);
  const bp = haversineM(b, p);
  const s = (ab + ap + bp) / 2;
  const area = Math.sqrt(Math.max(0, s * (s - ab) * (s - ap) * (s - bp)));
  return (2 * area) / ab;
}

function rdp(pts: Point[], eps: number): Point[] {
  if (pts.length < 3) return pts;
  let maxD = 0;
  let idx = 0;
  for (let i = 1; i < pts.length - 1; i++) {
    const d = crossTrackM(pts[i], pts[0], pts[pts.length - 1]);
    if (d > maxD) {
      maxD = d;
      idx = i;
    }
  }
  if (maxD > eps) {
    return [
      ...rdp(pts.slice(0, idx + 1), eps).slice(0, -1),
      ...rdp(pts.slice(idx), eps),
    ];
  }
  return [pts[0], pts[pts.length - 1]];
}

function cleanRoute(pts: Point[]): Point[] {
  if (pts.length < 2) return pts;
  const filtered: Point[] = [pts[0]];
  for (let i = 1; i < pts.length; i++) {
    if (haversineM(filtered[filtered.length - 1], pts[i]) <= 300) {
      filtered.push(pts[i]);
    }
  }
  return rdp(filtered, 8);
}

export const saveRoute = async (payload: SaveRouteInput) => {
  const cleaned = cleanRoute(payload.polyline);
  const encodedPolyline = polyline.encode(
    cleaned.map((p) => [p.lat, p.lng] as [number, number]),
  );
  const elevations = cleaned.map((p) => p.ele ?? 0);
  return TraveledRoute.create({
    transportMode: payload.transportMode,
    encodedPolyline,
    elevations,
    startTime: payload.startTime,
    endTime: payload.endTime,
  });
};

export const getRoutes = async () => {
  const docs = await TraveledRoute.find().sort({ createdAt: -1 });
  return docs
    .filter((doc) => doc.encodedPolyline)
    .map((doc) => {
      const latLngs = polyline.decode(doc.encodedPolyline);
      return {
        _id: doc._id,
        transportMode: doc.transportMode,
        polyline: latLngs.map(([lat, lng], i) => ({
          lat,
          lng,
          ...(doc.elevations[i] !== undefined ? { ele: doc.elevations[i] } : {}),
        })),
        startTime: doc.startTime,
        endTime: doc.endTime,
        createdAt: doc.createdAt,
      };
    });
};
