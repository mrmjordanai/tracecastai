import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Register reference detection platform channel
    if let controller = window?.rootViewController as? FlutterViewController {
      let messenger = controller.binaryMessenger
      ReferenceDetectionPlugin.register(
        with: self.registrar(forPlugin: "ReferenceDetectionPlugin")!
      )
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
