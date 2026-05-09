import { MapContainer, TileLayer, Marker, Popup } from "react-leaflet";

import "leaflet/dist/leaflet.css";

function MapView() {
  return (
    <MapContainer
      center={[47.9184, 106.9177]}
      zoom={13}
      className="h-full w-full z-0 rounded-2xl"
    >
      <TileLayer
        attribution="OpenStreetMap"
        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
      />

      <Marker position={[47.9184, 106.9177]}>
        <Popup>Traffic congestion</Popup>
      </Marker>

      <Marker position={[47.922, 106.934]}>
        <Popup>Road damage report</Popup>
      </Marker>
    </MapContainer>
  );
}

export default MapView;
