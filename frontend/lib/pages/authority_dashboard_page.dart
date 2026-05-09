import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_colors.dart';

class AuthorityDashboardPage extends StatefulWidget {
  const AuthorityDashboardPage({super.key});

  @override
  State<AuthorityDashboardPage> createState() =>
      _AuthorityDashboardPageState();
}

class _AuthorityDashboardPageState extends State<AuthorityDashboardPage> {
  int _filterIndex = 0;
  static const _filters = ['Бүгд', 'Өнөөдөр', 'Энэ долоо хоног'];

  static const _stats = [
    _Stat('Нийт', '1,248', Icons.summarize_rounded, AppColors.primary),
    _Stat('Баталгаажсан', '876', Icons.verified_rounded, AppColors.success),
    _Stat('Шийдвэрлэсэн', '634', Icons.check_circle_rounded, AppColors.routeBlue),
    _Stat('Идэвхтэй', '124', Icons.radio_button_on_rounded, AppColors.warning),
  ];

  static const _reports = [
    _Report('Мөс / цас', 'Сүхбаатар дүүрэг', '10:24', _ReportStatus.newReport),
    _Report('Замын засвар', 'Хан-Уул дүүрэг', '09:15', _ReportStatus.verified),
    _Report('Замын осол', 'Баянзүрх дүүрэг', '08:52', _ReportStatus.resolved),
    _Report('Үерт зам', 'Чингэлтэй дүүрэг', '08:30', _ReportStatus.newReport),
    _Report('Хаагдсан зам', 'Баянгол дүүрэг', '07:44', _ReportStatus.verified),
    _Report('Нарийн зам', 'Налайх дүүрэг', '07:10', _ReportStatus.resolved),
  ];

  // Heatspot locations
  static const _hotspots = [
    (LatLng(47.9220, 106.9190), 60.0, AppColors.danger),
    (LatLng(47.9150, 106.9250), 45.0, AppColors.warning),
    (LatLng(47.9270, 106.9130), 35.0, AppColors.warning),
    (LatLng(47.9180, 106.9310), 25.0, AppColors.success),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg1,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.bg2,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 16),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Эрх мэдлийн самбар',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stats row
            SizedBox(
              height: 88,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _stats.length,
                separatorBuilder: (_, index) => const SizedBox(width: 10),
                itemBuilder: (_, i) => _statCard(_stats[i]),
              ),
            ),
            const SizedBox(height: 16),

            // Mini heatmap
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 160,
                  child: FlutterMap(
                    options: const MapOptions(
                      initialCenter: LatLng(47.9184, 106.9177),
                      initialZoom: 13,
                      interactionOptions:
                          InteractionOptions(flags: InteractiveFlag.none),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.ubcab.app',
                      ),
                      CircleLayer(
                        circles: _hotspots
                            .map(
                              (h) => CircleMarker(
                                point: h.$1,
                                radius: h.$2,
                                color: h.$3.withValues(alpha: 0.3),
                                borderColor: h.$3,
                                borderStrokeWidth: 1.5,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Filter chips
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filters.length,
                separatorBuilder: (_, index) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final active = _filterIndex == i;
                  return GestureDetector(
                    onTap: () => setState(() => _filterIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? AppColors.primary : AppColors.bg2,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: active
                              ? AppColors.primary
                              : AppColors.bg3,
                        ),
                      ),
                      child: Text(
                        _filters[i],
                        style: TextStyle(
                          color:
                              active ? Colors.white : AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Reports list
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _reports.length,
                separatorBuilder: (_, index) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _reportRow(_reports[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(_Stat s) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(s.icon, color: s.color, size: 20),
          const Spacer(),
          Text(
            s.value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(s.label,
              style: const TextStyle(
                  color: AppColors.muted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _reportRow(_Report r) {
    final (label, color) = switch (r.status) {
      _ReportStatus.newReport => ('Шинэ', AppColors.warning),
      _ReportStatus.verified => ('Баталгаажсан', AppColors.routeBlue),
      _ReportStatus.resolved => ('Шийдвэрлэсэн', AppColors.success),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.type,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(r.location,
                    style: const TextStyle(
                        color: AppColors.muted, fontSize: 11)),
              ],
            ),
          ),
          Text(r.time,
              style: const TextStyle(
                  color: AppColors.muted, fontSize: 11)),
          const SizedBox(width: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

enum _ReportStatus { newReport, verified, resolved }

class _Stat {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _Stat(this.label, this.value, this.icon, this.color);
}

class _Report {
  final String type;
  final String location;
  final String time;
  final _ReportStatus status;
  const _Report(this.type, this.location, this.time, this.status);
}
