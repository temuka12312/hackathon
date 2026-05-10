import 'package:flutter/material.dart';
import 'pages/points_store.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PointsStore().init(); // ← нэмэх
  runApp(const App());
}