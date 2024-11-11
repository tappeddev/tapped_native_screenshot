import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'tapped_native_screenshot_method_channel.dart';

abstract class TappedNativeScreenshotPlatform extends PlatformInterface {
  /// Constructs a TappedNativeScreenshotPlatform.
  TappedNativeScreenshotPlatform() : super(token: _token);

  static final Object _token = Object();

  static TappedNativeScreenshotPlatform _instance =
      MethodChannelTappedNativeScreenshot();

  /// The default instance of [TappedNativeScreenshotPlatform] to use.
  ///
  /// Defaults to [MethodChannelTappedNativeScreenshot].
  static TappedNativeScreenshotPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [TappedNativeScreenshotPlatform] when
  /// they register themselves.
  static set instance(TappedNativeScreenshotPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<Uint8List> captureScreenshot({
    required double x,
    required double y,
    required double width,
    required double height,
  }) {
    throw UnimplementedError('captureScreenshot() has not been implemented.');
  }
}
