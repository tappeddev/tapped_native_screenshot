import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'dart:html' as html;
import 'dart:js' as js;
import 'package:js/js.dart';
import 'package:js/js_util.dart';

import 'tapped_native_screenshot_platform_interface.dart';

@JS()
external html2canvas(html.Element element);

/// A web implementation of the TappedNativeScreenshotPlatform of the TappedNativeScreenshot plugin.
class TappedNativeScreenshotWeb extends TappedNativeScreenshotPlatform {
  /// Constructs a TappedNativeScreenshotWeb
  TappedNativeScreenshotWeb();

  static void registerWith(Registrar registrar) {
    TappedNativeScreenshotPlatform.instance = TappedNativeScreenshotWeb();
  }

  /// Web screenshot capture using html2canvas
  @override
  Future<Uint8List> captureScreenshot({
    required double x,
    required double y,
    required double width,
    required double height,
  }) async {
    // Load html2canvas script
    await _loadHtml2Canvas();

    // Capture the full area first, then crop
    final promise = html2canvas(html.document.body!);
    final canvas = await promiseToFuture(promise);

    // Create a new canvas element for the cropped area with adjusted size
    final croppedCanvas =
        html.CanvasElement(width: width.ceil(), height: height.ceil());
    final croppedContext =
        croppedCanvas.getContext('2d') as html.CanvasRenderingContext2D;

    final devicePixelRatio = html.window.devicePixelRatio;
    // Scale the context to the pixel ratio to get a 1:1 match for display
    croppedContext.scale(1 / devicePixelRatio, 1 / devicePixelRatio);
    croppedContext.drawImageScaledFromSource(
        canvas,
        // Source rectangle
        x * devicePixelRatio,
        y * devicePixelRatio,
        width * devicePixelRatio,
        height * devicePixelRatio,
        // Destination rectangle on croppedCanvas
        0,
        0,
        width * devicePixelRatio,
        height * devicePixelRatio
        );

    final dataUrl = callMethod(croppedCanvas, 'toDataURL', ['image/png']);
    final String base64String = dataUrl.toString().split(',')[1];
    final Uint8List bytes = const Base64Decoder().convert(base64String);

    return bytes;
  }

  /// Loads the html2canvas library if not already loaded
  Future<void> _loadHtml2Canvas() async {
    if (!js.context.hasProperty('html2canvas')) {
      final completer = Completer<void>();

      final script = html.ScriptElement()
        ..src =
            'https://cdnjs.cloudflare.com/ajax/libs/html2canvas/1.4.1/html2canvas.min.js'
        ..type = 'text/javascript';
      late final StreamSubscription onLoadListener;
      late final StreamSubscription onErrorListener;
      onLoadListener = script.onLoad.listen((_) {
        onLoadListener.cancel();
        onErrorListener.cancel();
        return completer.complete();
      });
      onErrorListener = script.onError.listen((event) {
        onLoadListener.cancel();
        onErrorListener.cancel();
        completer.completeError('Failed to load html2canvas');
      });

      html.document.head!.append(script);
      return completer.future;
    }
  }
}
