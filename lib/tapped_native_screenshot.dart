import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'tapped_native_screenshot_platform_interface.dart';

class TappedNativeScreenshot {
  TappedNativeScreenshot._();

  static Future<Uint8List> captureScreenshot({
    required RenderObject renderObject,
    double? nativeScreenshotWidth,
    double? nativeScreenshotHeight,
  }) async {
    if (!kIsWeb && Platform.isAndroid) {
      final boundary = renderObject as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      return byteData!.buffer.asUint8List();
    } else {
      final box = renderObject as RenderBox;
      final position = box.localToGlobal(Offset.zero);
      return captureScreenshotInNative(
        x: position.dx,
        y: position.dy,
        width: nativeScreenshotWidth ?? box.size.width,
        height: nativeScreenshotHeight ?? box.size.height,
      );
    }
  }

  /// Capture Screenshot in native for the given coordinates.
  /// Android is not implemented since RepaintBoundary works with platform-views on Android.
  static Future<Uint8List> captureScreenshotInNative({
    required double x,
    required double y,
    required double width,
    required double height,
  }) {
    return TappedNativeScreenshotPlatform.instance.captureScreenshot(
      x: x,
      y: y,
      width: width,
      height: height,
    );
  }
}

class TappedScreenshotBoundary extends StatefulWidget {
  final Widget child;

  const TappedScreenshotBoundary({super.key, required this.child});

  @override
  State<TappedScreenshotBoundary> createState() => TappedScreenshotBoundaryState();
}

class TappedScreenshotBoundaryState extends State<TappedScreenshotBoundary> {
  final _key = GlobalKey();

  Future<Uint8List> captureScreenshot() async {
    final renderObject = _key.currentContext!.findRenderObject()!;
    return TappedNativeScreenshot.captureScreenshot(renderObject: renderObject);
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb && Platform.isAndroid) {
      return RepaintBoundary(key: _key, child: widget.child);
    } else {
      return SizedBox(key: _key, child: widget.child);
    }
  }
}
