import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'tapped_native_screenshot_platform_interface.dart';

/// An implementation of [TappedNativeScreenshotPlatform] that uses method channels.
class MethodChannelTappedNativeScreenshot
    extends TappedNativeScreenshotPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('tapped_native_screenshot');

  @override
  Future<Uint8List> captureScreenshot({
    required double x,
    required double y,
    required double width,
    required double height,
  }) async {
    final bytes =
        await methodChannel.invokeMethod<Uint8List>('captureScreenshot', {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
    });
    return bytes!;
  }
}
