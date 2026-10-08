import Flutter
import UIKit
import UserNotifications
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Download progress and adhkar reminder notifications. The permission is
    // asked for when a download starts or a reminder is turned on, not here.
    UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    return result
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "net.mrecode.mre_quran/prayer_widget",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, callback in
      guard call.method == "update" else {
        callback(FlutterMethodNotImplemented)
        return
      }
      let values = call.arguments as? [String: Any]
      let defaults = UserDefaults(suiteName: "group.net.mrecode.mreQuran")
      if let values {
        defaults?.set(values["title"] as? String, forKey: "title")
        defaults?.set(values["label"] as? String, forKey: "label")
        defaults?.set(values["time"] as? String, forKey: "time")
        defaults?.set(values["at"] as? NSNumber, forKey: "at")
      } else {
        defaults?.removeObject(forKey: "title")
        defaults?.removeObject(forKey: "label")
        defaults?.removeObject(forKey: "time")
        defaults?.removeObject(forKey: "at")
      }
      WidgetCenter.shared.reloadTimelines(ofKind: "NextPrayerWidget")
      callback(nil)
    }
  }
}
