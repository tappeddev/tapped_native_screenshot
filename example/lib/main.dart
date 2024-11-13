import 'dart:async';

import 'package:feedback/feedback.dart';

// ignore: implementation_imports
import 'package:feedback/src/screenshot.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:tapped_native_screenshot/tapped_native_screenshot.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Uint8List? _screenshot;
  Uint8List? _feedbackScreenshot;

  bool _isNativeScreenshotFeedback = true;

  final _widgetKey = GlobalKey<TappedScreenshotBoundaryState>();

  void showFeedbackForm(
    BuildContext context, {
    required OnFeedbackCallback onFeedback,
    bool isNativeScreenshot = false,
  }) {
    setState(() {
      _isNativeScreenshotFeedback = isNativeScreenshot;
    });
    BetterFeedback.of(context).show((userFeedback) {
      setState(() {
        _isNativeScreenshotFeedback = false;
      });
      onFeedback(userFeedback);
    });
  }

  Future<void> _captureScreenshot(BuildContext context) async {
    final bytes = await _widgetKey.currentState!.captureScreenshot();
    setState(() {
      _screenshot = bytes;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BetterFeedback(
      screenshotController:
          _isNativeScreenshotFeedback ? NativeScreenshotController() : null,
      child: Builder(builder: (context) {
        return MaterialApp(
          home: Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                showFeedbackForm(
                  context,
                  onFeedback: (UserFeedback feedback) {
                    setState(() {
                      _feedbackScreenshot = feedback.screenshot;
                    });
                  },
                  isNativeScreenshot: true,
                );
              },
              child: const Icon(Icons.bug_report),
            ),
            appBar: AppBar(
              title: const Text('Plugin example app'),
            ),
            body: SingleChildScrollView(
              child: Center(
                child: Column(
                  children: [
                    SizedBox(
                      width: 300.0,
                      height: 200.0,
                      child: TappedScreenshotBoundary(
                        key: _widgetKey,
                        child: MapLibreMap(
                          initialCameraPosition:
                              const CameraPosition(target: LatLng(0.0, 0.0)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        _captureScreenshot(context);
                      },
                      child: const Text('Capture Screenshot'),
                    ),
                    const SizedBox(height: 24),
                    if (_screenshot != null) ...[
                      const Text('  Captured Screenshot:'),
                      const SizedBox(height: 12),
                      // Display the captured screenshot
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(border: Border.all(width: 2)),
                        child: Image.memory(
                          _screenshot!,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (_feedbackScreenshot != null) ...[
                      const Text('  Feedback Screenshot:'),
                      const SizedBox(height: 12),
                      // Display the captured screenshot
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(border: Border.all(width: 2)),
                        child: Image.memory(
                          _feedbackScreenshot!,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class NativeScreenshotController implements ScreenshotController {
  @override
  final GlobalKey containerKey = GlobalKey();

  @override
  Future<Uint8List> capture(
      {double pixelRatio = 1,
      Duration delay = const Duration(milliseconds: 20)}) async {
    await Future.delayed(delay);
    final renderObject = containerKey.currentContext!.findRenderObject()!;
    return TappedNativeScreenshot.captureScreenshot(renderObject: renderObject);
  }
}
