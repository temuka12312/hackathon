import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ActivityEntry {
  final String title;
  final String location;
  final int points;
  final String time;

  ActivityEntry({
    required this.title,
    required this.location,
    required this.points,
    required this.time,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'location': location,
        'points': points,
        'time': time,
      };

  factory ActivityEntry.fromJson(Map<String, dynamic> j) => ActivityEntry(
        title: j['title'],
        location: j['location'],
        points: j['points'],
        time: j['time'],
      );
}

class PointsStore extends ChangeNotifier {
  static const _pointsKey = 'user_total_points';
  static const _activitiesKey = 'user_activities';

  static final PointsStore _instance = PointsStore._();
  factory PointsStore() => _instance;
  PointsStore._();

  int _total = 0;
  int get total => _total;

  List<ActivityEntry> _activities = [];
  List<ActivityEntry> get activities => List.unmodifiable(_activities);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _total = prefs.getInt(_pointsKey) ?? 0;

    final raw = prefs.getString(_activitiesKey);
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      _activities = list.map((e) => ActivityEntry.fromJson(e)).toList();
    }
    notifyListeners();
  }

  Future<void> addPoints(int amount, {required String title, required String location}) async {
    final prefs = await SharedPreferences.getInstance();

    _total += amount;
    await prefs.setInt(_pointsKey, _total);

    // Цаг авах
    final now = TimeOfDay.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');

    _activities.insert(
      0,
      ActivityEntry(
        title: title,
        location: location,
        points: amount,
        time: '$h:$m',
      ),
    );

    await prefs.setString(_activitiesKey, jsonEncode(_activities.map((e) => e.toJson()).toList()));
    notifyListeners();
  }
}