class ReportItem {
  const ReportItem({
    required this.type,
    required this.description,
    required this.latitude,
    required this.longitude,
  });

  final String type;
  final String description;
  final double latitude;
  final double longitude;

  factory ReportItem.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>? ?? const {};
    return ReportItem(
      type: json['type'] as String? ?? 'traffic',
      description: json['description'] as String? ?? '',
      latitude: (location['lat'] as num?)?.toDouble() ?? 0,
      longitude: (location['lng'] as num?)?.toDouble() ?? 0,
    );
  }
}
