import Flutter
import UIKit

public class TappedNativeScreenshotPlugin: NSObject, FlutterPlugin {
    private enum ScreenshotError: String {
        case invalidArguments = "INVALID_ARGUMENTS"
        case captureFailed = "CAPTURE_FAILED"
        
        var message: String {
            switch self {
            case .invalidArguments:
                return "One or more arguments are missing or incorrect"
            case .captureFailed:
                return "Failed to capture screenshot"
            }
        }
        
        func asFlutterError() -> FlutterError {
            return FlutterError(code: self.rawValue, message: self.message, details: nil)
        }
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "tapped_native_screenshot", binaryMessenger: registrar.messenger())
        let instance = TappedNativeScreenshotPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "captureScreenshot":
            guard let args = call.arguments as? [String: Any],
                  let x = args["x"] as? CGFloat,
                  let y = args["y"] as? CGFloat,
                  let width = args["width"] as? CGFloat,
                  let height = args["height"] as? CGFloat else {
                result(ScreenshotError.invalidArguments.asFlutterError())
                return
            }
            let rect = CGRect(x: x,y: y,width: width,height: height)
            guard let screenshot = captureArea(rect: rect) else {
                result(ScreenshotError.captureFailed.asFlutterError())
                return
            }
            result(screenshot)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    func getWindow() -> UIWindow? {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.windows.first { $0.isKeyWindow }
        } else {
            return UIApplication.shared.keyWindow
        }
    }
    
    private func captureArea(rect: CGRect) -> FlutterStandardTypedData? {
        let renderer = UIGraphicsImageRenderer(size: rect.size)
        let image = renderer.image { (context) in
            if let window = UIApplication.shared.windows.first {
                // Draw the specific area into the context
                context.cgContext.translateBy(x: -rect.origin.x, y: -rect.origin.y)
                window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
            }
        }

        // Scale down the image to 1x scale
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        
        let scaledRenderer = UIGraphicsImageRenderer(size: rect.size, format: format)
        let scaledImage = scaledRenderer.image { context in
            image.draw(in: CGRect(origin: .zero, size:  rect.size))
        }
        
        // Convert the UIImage to PNG data
        if let pngData = scaledImage.pngData() {
            return FlutterStandardTypedData(bytes: pngData)
        }
        return nil
    }
}
