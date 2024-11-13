import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'tapped_native_screenshot_platform_interface.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

class TappedNativeScreenshot {
  TappedNativeScreenshot._();

  static Future<Uint8List> captureScreenshot({
    required RenderObject renderObject,
  }) async {
    if (!kIsWeb && Platform.isAndroid) {
      final boundary = renderObject as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      return byteData!.buffer.asUint8List();
    } else {
      // Step 1: Get the transformation matrix for the widget
      final renderBox = renderObject as RenderBox;
      final transform = renderBox.getTransformTo(null);

      // Step 2: Define the four corners of the widget in its local coordinate space
      final originalSize = renderBox.size;
      final corners = [
        Offset.zero, // top-left
        Offset(originalSize.width, 0), // top-right
        Offset(0, originalSize.height), // bottom-left
        Offset(originalSize.width, originalSize.height), // bottom-right
      ];

      // Step 3: Apply the transformation matrix to each corner
      final List<Offset> transformedCorners = corners.map((corner) {
        final transformed =
        transform.transform3(Vector3(corner.dx, corner.dy, 0));
        return Offset(transformed.x, transformed.y);
      }).toList();

      // Step 4: Calculate the bounding box of the transformed corners
      final minX = transformedCorners.map((c) => c.dx).reduce(min);
      final maxX = transformedCorners.map((c) => c.dx).reduce(max);
      final minY = transformedCorners.map((c) => c.dy).reduce(min);
      final maxY = transformedCorners.map((c) => c.dy).reduce(max);

      // Step 5: Calculate the final width and height based on the transformed coordinates
      final size = Size(maxX - minX, maxY - minY);
      final position = renderBox.localToGlobal(Offset.zero);
      return captureScreenshotInNative(
        x: position.dx,
        y: position.dy,
        width: size.width,
        height: size.height,
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
  State<TappedScreenshotBoundary> createState() =>
      TappedScreenshotBoundaryState();
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
