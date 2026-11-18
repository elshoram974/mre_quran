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
      WidgetCenter.shared.reloadTimelines(ofKind: "PrayerCardWidget")
      callback(nil)
    }
    // iOS lets no app add a widget (the widgets page says how); it can only
    // tell whether one of the app's widgets is on the home screen.
    let hapticsChannel = FlutterMethodChannel(
      name: "net.mrecode.mre_quran/widget_haptics",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    hapticsChannel.setMethodCallHandler { call, callback in
      guard call.method == "setEnabled", let enabled = call.arguments as? Bool else {
        callback(FlutterMethodNotImplemented)
        return
      }
      UserDefaults(suiteName: "group.net.mrecode.mreQuran")?.set(enabled, forKey: "tasbihHaptics")
      callback(nil)
    }
    let homeWidgetsChannel = FlutterMethodChannel(
      name: "net.mrecode.mre_quran/home_widgets",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    homeWidgetsChannel.setMethodCallHandler { call, callback in
      switch call.method {
      case "canPin", "pin":
        callback(false)
      case "appearance":
        callback(UserDefaults(suiteName: "group.net.mrecode.mreQuran")?.string(forKey: "widgetAppearance") ?? "automatic")
      case "setAppearance":
        guard let style = call.arguments as? String, ["automatic", "navy", "green"].contains(style),
          let defaults = UserDefaults(suiteName: "group.net.mrecode.mreQuran") else {
          callback(false)
          return
        }
        defaults.set(style, forKey: "widgetAppearance")
        WidgetCenter.shared.reloadAllTimelines()
        callback(true)
      case "prayerScheduleOptions":
        let defaults = UserDefaults(suiteName: "group.net.mrecode.mreQuran")
        callback(defaults?.dictionary(forKey: "prayerScheduleOptions") ?? [
          "upcomingOnly": false, "showSunrise": true, "showDate": true,
          "showCountdown": true, "largeText": false,
        ])
      case "setPrayerScheduleOptions":
        let keys = ["upcomingOnly", "showSunrise", "showDate", "showCountdown", "largeText"]
        guard let options = call.arguments as? [String: Any],
          keys.allSatisfy({ options[$0] is Bool }),
          let defaults = UserDefaults(suiteName: "group.net.mrecode.mreQuran") else {
          callback(false)
          return
        }
        defaults.set(options, forKey: "prayerScheduleOptions")
        WidgetCenter.shared.reloadTimelines(ofKind: "PrayerScheduleWidget")
        callback(true)
      case "placed":
        WidgetCenter.shared.getCurrentConfigurations { result in
          let placed = (try? result.get())?.isEmpty == false
          DispatchQueue.main.async { callback(placed) }
        }
      default:
        callback(FlutterMethodNotImplemented)
      }
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
      let previous = defaults?.dictionary(forKey: "adhkarWidgetPayload")
      if let values {
        defaults?.set(values, forKey: "adhkarWidgetPayload")
      } else {
        defaults?.removeObject(forKey: "adhkarWidgetPayload")
      }
      WidgetCenter.shared.reloadTimelines(ofKind: "SuggestedDhikrWidget")
      if (previous?["rtl"] as? Bool) != (values?["rtl"] as? Bool) ||
         (previous?["useArabicDigits"] as? Bool) != (values?["useArabicDigits"] as? Bool) {
        WidgetCenter.shared.reloadTimelines(ofKind: "TasbihWidget")
      }
      callback(nil)
    }
  }
}
