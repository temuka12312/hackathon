import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui;

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'report_success_page.dart';

class CameraPage extends StatefulWidget {
  final String obstacleType;
  const CameraPage({super.key, required this.obstacleType});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  html.VideoElement? _video;
  html.MediaStream? _stream;
  html.CanvasElement? _canvas;
  String? _capturedDataUrl;
  bool _cameraReady = false;
  final String _viewId = 'camera-view-${DateTime.now().millisecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    _startCamera();
  }

  Future<void> _startCamera() async {
    _video = html.VideoElement()
      ..autoplay = true
      ..setAttribute('playsinline', 'true')
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover';

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      _viewId,
      (int id) => _video!,
    );

    try {
      _stream = await html.window.navigator.mediaDevices!.getUserMedia({
        'video': {'facingMode': 'environment'},
        'audio': false,
      });
      _video!.srcObject = _stream;
      await _video!.play();
      if (mounted) setState(() => _cameraReady = true);
    } catch (e) {
      debugPrint('Camera error: $e');
    }
  }

  void _capture() {
    if (_video == null) return;

    final w = _video!.videoWidth;
    final h = _video!.videoHeight;

    _canvas = html.CanvasElement(width: w, height: h);
    _canvas!.context2D.drawImage(_video!, 0, 0);
    final dataUrl = _canvas!.toDataUrl('image/jpeg', 0.85);

    _stopCamera();
    setState(() => _capturedDataUrl = dataUrl);
  }

  void _retake() {
    setState(() {
      _capturedDataUrl = null;
      _cameraReady = false;
    });
    _startCamera();
  }

  void _stopCamera() {
    _stream?.getTracks().forEach((t) => t.stop());
  }

  void _submit() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ReportSuccessPage(obstacleType: widget.obstacleType),
      ),
    );
  }

  @override
  void dispose() {
    _stopCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Камер preview эсвэл авсан зураг
          if (_capturedDataUrl != null)
            Image.network(_capturedDataUrl!, fit: BoxFit.cover)
          else if (_cameraReady)
            HtmlElementView(viewType: _viewId)
          else
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white38),
                  SizedBox(height: 16),
                  Text('Камер нээгдэж байна...',
                      style: TextStyle(color: Colors.white54, fontSize: 14)),
                ],
              ),
            ),

          // Top bar
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        _stopCamera();
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                    const Expanded(
                      child: Text('Нотлох зураг авах',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
            ),
          ),

          // Камер горим — шутер товч
          if (_capturedDataUrl == null && _cameraReady)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 16, 32, 40),
                  child: Column(
                    children: [
                      const Text('Саадыг тодорхой харагдуулна уу',
                          style: TextStyle(color: Colors.white60, fontSize: 13)),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: _capture,
                        child: Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Preview горим — дахин / илгээх
          if (_capturedDataUrl != null)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withValues(alpha: 0.85), Colors.transparent],
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _retake,
                          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                          label: const Text('Дахин авах', style: TextStyle(color: Colors.white)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white38),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _submit,
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('Илгээх'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}