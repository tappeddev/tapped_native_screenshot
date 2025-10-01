import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:web/web.dart';

import 'tapped_native_screenshot_platform_interface.dart';

@JS('html2canvas')
external JSPromise _html2canvas(HTMLElement element);

@JS('html2canvas')
external JSAny? _html2canvasGlobal;

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
    final canvas =
        (await _html2canvas(document.body!).toDart) as HTMLCanvasElement;

    // Create a new canvas element for the cropped area
    final croppedCanvas = HTMLCanvasElement();
    croppedCanvas.width = width.ceil();
    croppedCanvas.height = height.ceil();

    final croppedContext =
        croppedCanvas.getContext('2d') as CanvasRenderingContext2D;

    final devicePixelRatio = window.devicePixelRatio;
    // Scale the context to the pixel ratio to get a 1:1 match for display
    croppedContext.scale(1 / devicePixelRatio, 1 / devicePixelRatio);

    // Use drawImage with full rect arguments
    croppedContext.drawImage(
      canvas,
      // Source rect
      x * devicePixelRatio,
      y * devicePixelRatio,
      width * devicePixelRatio,
      height * devicePixelRatio,
      // Destination rect
      0,
      0,
      width * devicePixelRatio,
      height * devicePixelRatio,
    );

    final dataUrl = croppedCanvas.toDataURL('image/png');
    final String base64String = dataUrl.split(',')[1];
    final Uint8List bytes = const Base64Decoder().convert(base64String);

    return bytes;
  }

  /// Loads the html2canvas library if not already loaded
  Future<void> _loadHtml2Canvas() async {
    if (_html2canvasGlobal != null) return;
    final completer = Completer<void>();

    final script = HTMLScriptElement()
      ..src =
          'https://cdnjs.cloudflare.com/ajax/libs/html2canvas/1.4.1/html2canvas.min.js'
      ..type = 'text/javascript';

    late final EventListener onLoadListener;
    late final EventListener onErrorListener;

    onLoadListener = ((Event event) {
      script.removeEventListener('load', onLoadListener);
      script.removeEventListener('error', onErrorListener);
      completer.complete();
    }).toJS;

    onErrorListener = ((Event event) {
      script.removeEventListener('load', onLoadListener);
      script.removeEventListener('error', onErrorListener);
      completer.completeError('Failed to load html2canvas');
    }).toJS;

    script.addEventListener('load', onLoadListener);
    script.addEventListener('error', onErrorListener);

    document.head!.append(script);
    return completer.future;
  }
}
