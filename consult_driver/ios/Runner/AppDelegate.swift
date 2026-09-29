import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Set in ios/Flutter/Secrets.xcconfig, which is gitignored. The SDK must be
    // initialised even without a key, or opening any map aborts the app; with a
    // missing key maps render blank and log an authorisation error instead.
    let key = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String ?? ""
    if key.isEmpty {
      NSLog("GOOGLE_MAPS_API_KEY is not set; copy ios/Flutter/Secrets.xcconfig.example to Secrets.xcconfig")
    }
    GMSServices.provideAPIKey(key.isEmpty ? "MISSING_GOOGLE_MAPS_API_KEY" : key)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
