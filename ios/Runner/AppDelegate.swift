import Flutter
import GoogleMaps
import UIKit
import UserNotifications
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let key = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String,
       !key.isEmpty,
       !key.hasPrefix("$(") {
      GMSServices.provideAPIKey(key)
    }
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
        defaults?.set(values, forKey: "prayerWidgetPayload")
      } else {
        defaults?.removeObject(forKey: "prayerWidgetPayload")
      }
      WidgetCenter.shared.reloadTimelines(ofKind: "NextPrayerWidget")
      WidgetCenter.shared.reloadTimelines(ofKind: "PrayerScheduleWidget")
      callback(nil)
    }
    let adhkarWidgetChannel = FlutterMethodChannel(
      name: "net.mrecode.mre_quran/adhkar_widget",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    adhkarWidgetChannel.setMethodCallHandler { call, callback in
      guard call.method == "update" else {
        callback(FlutterMethodNotImplemented)
        return
      }
      let values = call.arguments as? [String: Any]
      let defaults = UserDefaults(suiteName: "group.net.mrecode.mreQuran")
      if let values {
        defaults?.set(values, forKey: "adhkarWidgetPayload")
      } else {
        defaults?.removeObject(forKey: "adhkarWidgetPayload")
      }
      WidgetCenter.shared.reloadTimelines(ofKind: "SuggestedDhikrWidget")
      callback(nil)
    }
  }
}
