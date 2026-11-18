import AppIntents
import SwiftUI
import WidgetKit

private let appGroup = "group.net.mrecode.mreQuran"
private let payloadKey = "prayerWidgetPayload"

private var systemIsArabic: Bool {
  if #available(iOS 16.0, *) {
    return Locale.current.language.languageCode?.identifier == "ar"
  }
  return Locale.current.languageCode == "ar"
}

private func displayDigits(_ value: Int, arabic: Bool) -> String {
  guard arabic else { return String(value) }
  let digits = Array("٠١٢٣٤٥٦٧٨٩")
  return String(String(value).map { $0.wholeNumberValue.map { digits[$0] } ?? $0 })
}

private struct Row: Identifiable {
  let id: String; let name: String; let time: String; let at: Date
}
private struct Day { let start: Date; let end: Date; let date: String; let hijri: String; let rows: [Row] }
private struct Payload {
  let labels: [String: String]; let days: [Day]
  /// Whether the time left counts down to the second (a setting in the app).
  var seconds: Bool = false
  var rtl: Bool = true
  var arabicDigits: Bool = true
  static func read() -> Payload? {
    guard let root = UserDefaults(suiteName: appGroup)?.dictionary(forKey: payloadKey),
      let labels = root["labels"] as? [String: String], let rawDays = root["days"] as? [[String: Any]] else { return nil }
    let days = rawDays.compactMap { raw -> Day? in
      guard let start = raw["start"] as? NSNumber, let end = raw["end"] as? NSNumber,
        let date = raw["dateLabel"] as? String, let hijri = raw["hijriLabel"] as? String,
        let rawRows = raw["rows"] as? [[String: Any]] else { return nil }
      let rows = rawRows.compactMap { raw -> Row? in
        guard let id = raw["id"] as? String, let name = raw["name"] as? String,
          let time = raw["time"] as? String, let at = raw["at"] as? NSNumber else { return nil }
        return Row(id: id, name: name, time: time, at: Date(timeIntervalSince1970: at.doubleValue / 1000))
      }
      return Day(start: Date(timeIntervalSince1970: start.doubleValue / 1000), end: Date(timeIntervalSince1970: end.doubleValue / 1000), date: date, hijri: hijri, rows: rows)
    }
    return Payload(labels: labels, days: days, seconds: (root["seconds"] as? Bool) ?? false, rtl: (root["rtl"] as? Bool) ?? true, arabicDigits: (root["useArabicDigits"] as? Bool) ?? true)
  }

  /// What the widget gallery shows before the app has sent any times: a
  /// sample day with Asr coming, in the system language.
  static func sample(_ now: Date) -> Payload {
    let ar = systemIsArabic
    let names: [(String, String, String, Double)] = ar
      ? [("fajr", "الفجر", "٤:٥٤ ص", -6.0), ("sunrise", "الشروق", "٦:٢٠ ص", -4.5), ("dhuhr", "الظهر", "١١:٤٢ ص", -1.0), ("asr", "العصر", "٢:٣٧ م", 1.4), ("maghrib", "المغرب", "٤:٥٧ م", 3.7), ("isha", "العشاء", "٦:١٨ م", 5.1)]
      : [("fajr", "Fajr", "4:54 AM", -6.0), ("sunrise", "Sunrise", "6:20 AM", -4.5), ("dhuhr", "Dhuhr", "11:42 AM", -1.0), ("asr", "Asr", "2:37 PM", 1.4), ("maghrib", "Maghrib", "4:57 PM", 3.7), ("isha", "Isha", "6:18 PM", 5.1)]
    let rows = names.map { Row(id: $0.0, name: $0.1, time: $0.2, at: now.addingTimeInterval($0.3 * 3600)) }
    let date = DateFormatter(); date.locale = Locale(identifier: ar ? "ar" : "en"); date.setLocalizedDateFormatFromTemplate("EEE d MMM")
    let hijri = DateFormatter(); hijri.locale = date.locale; hijri.calendar = Calendar(identifier: .islamicUmmAlQura); hijri.setLocalizedDateFormatFromTemplate("d MMM y")
    let day = Day(start: now.addingTimeInterval(-12 * 3600), end: now.addingTimeInterval(12 * 3600), date: date.string(from: now), hijri: hijri.string(from: now), rows: rows)
    return Payload(labels: ar ? ["next": "الصلاة القادمة", "remaining": "بعد %1$s", "hours": "%1$s س %2$s د", "minutes": "%1$s د", "empty": ""] : ["next": "Next prayer", "remaining": "%1$s left", "hours": "%1$s h %2$s min", "minutes": "%1$s min", "empty": ""], days: [day], rtl: ar, arabicDigits: ar)
  }
  func day(_ now: Date) -> Day? { days.first { $0.start <= now && now < $0.end } }
  func next(_ now: Date) -> Row? { days.flatMap(\.rows).first { $0.id != "sunrise" && $0.at > now } }
  func remaining(_ at: Date, _ now: Date) -> String {
    let minutes = max(1, Int(at.timeIntervalSince(now) / 60)); let h = minutes / 60
    let duration = h > 0 ? replace(labels["hours"] ?? "%1$s h %2$s min", ["%1$s":displayDigits(h, arabic: arabicDigits), "%2$s":displayDigits(minutes % 60, arabic: arabicDigits)]) : replace(labels["minutes"] ?? "%1$s min", ["%1$s":displayDigits(minutes, arabic: arabicDigits)])
    return replace(labels["remaining"] ?? "%1$s left", ["%1$s":duration])
  }
  private func replace(_ text: String, _ values: [String:String]) -> String { values.reduce(text) { $0.replacingOccurrences(of: $1.key, with: $1.value) } }
}
private struct Entry: TimelineEntry {
  let date: Date
  let payload: Payload?
  var isPreview = false
  var awaitingReload = false
}
private struct AdhkarPayload {
  let label: String; let title: String; let done: Int; let total: Int; let payload: String; let rtl: Bool; let progressLabel: String?; let arabicDigits: Bool
  static func read() -> AdhkarPayload? {
    guard let raw = UserDefaults(suiteName: appGroup)?.dictionary(forKey: "adhkarWidgetPayload"),
      let label = raw["label"] as? String, let title = raw["title"] as? String,
      let done = raw["done"] as? NSNumber, let total = raw["total"] as? NSNumber,
      let payload = raw["payload"] as? String else { return nil }
    return AdhkarPayload(label: label, title: title, done: done.intValue, total: total.intValue, payload: payload, rtl: (raw["rtl"] as? Bool) ?? true, progressLabel: raw["progressLabel"] as? String, arabicDigits: (raw["useArabicDigits"] as? Bool) ?? true)
  }
}
private struct Provider: TimelineProvider {
  func placeholder(in context: Context) -> Entry { Entry(date: .now, payload: nil, isPreview: true) }
  func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) { completion(Entry(date: .now, payload: .read(), isPreview: context.isPreview)) }
  func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
    let now = Date()
    let payload = Payload.read()
    let current = Entry(date: now, payload: payload)
    // If WidgetKit defers our reload, a pre-rendered entry still advances
    // the prayer and date. Its first tap requests a fresh timeline.
    let boundaries = Set((payload?.days ?? []).flatMap { day in
      day.rows.filter { $0.id != "sunrise" }.map(\.at) + [day.end]
    }).filter { $0 > now }.sorted()
    let entries = [current] + boundaries.map { Entry(date: $0, payload: payload, awaitingReload: true) }
    completion(Timeline(entries: entries, policy: .after(boundaries.first ?? now.addingTimeInterval(3600))))
  }
}

@available(iOS 17.0, *)
struct RefreshPrayerWidgetIntent: AppIntent {
  static var title: LocalizedStringResource = "Refresh prayer times"
  func perform() async throws -> some IntentResult {
    for kind in ["NextPrayerWidget", "PrayerScheduleWidget", "PrayerCardWidget"] {
      WidgetCenter.shared.reloadTimelines(ofKind: kind)
    }
    return .result()
  }
}

private struct PrayerWidgetTap: ViewModifier {
  let entry: Entry
  @ViewBuilder func body(content: Content) -> some View {
    if #available(iOS 17.0, *), entry.awaitingReload {
      Button(intent: RefreshPrayerWidgetIntent()) {
        content.contentShape(Rectangle())
      }.buttonStyle(.plain).accessibilityHint(Text("Refresh prayer times"))
    } else {
      content.widgetURL(URL(string: "mrequran://mre-quran/prayer-times"))
    }
  }
}

private struct Empty: View { var body: some View { Text(Payload.read()?.labels["empty"] ?? NSLocalizedString("Open Mushafi to set your location", comment: "")).font(.caption).frame(maxWidth:.infinity,maxHeight:.infinity,alignment:.leading) } }
private struct NextView: View {
  let entry: Entry
  var body: some View {
    let data = entry.payload ?? (entry.isPreview ? Payload.sample(entry.date) : nil)
    Group {
      if let data, let next = data.next(entry.date) {
        HStack(alignment: .center, spacing: 8) {
          VStack(alignment: .leading, spacing: 3) {
            Text(data.labels["next"] ?? "").font(.caption).foregroundStyle(.secondary).lineLimit(1)
            Text(next.name).font(.headline).lineLimit(2)
          }.frame(maxWidth: .infinity, alignment: .leading)
          VStack(alignment: .trailing, spacing: 3) {
            Text(next.time).font(.headline.weight(.semibold)).monospacedDigit().lineLimit(1)
            TimeLeft(data: data, at: next.at, now: entry.date)
              .font(.caption).foregroundStyle(.secondary).lineLimit(2)
          }.frame(maxWidth: .infinity, alignment: .trailing)
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
      } else { Empty() }
    }.environment(\.layoutDirection, (data?.rtl ?? (systemIsArabic)) ? .rightToLeft : .leftToRight)
      .modifier(PrayerWidgetTap(entry: entry))
  }
}
/// The time left until [at]: to the second when the person chose it in the
/// app, or as a relative duration; WidgetKit updates both while visible.
private struct TimeLeft: View {
  let data: Payload; let at: Date; let now: Date
  var body: some View {
    let parts = (data.labels["remaining"] ?? "%1$s left").components(separatedBy: "%1$s")
    HStack(spacing: 0) {
      Text(parts.first ?? "")
      if data.seconds {
        Text(at, style: .timer).monospacedDigit()
      } else {
        Text(at, style: .relative)
      }
      if parts.count > 1 { Text(parts[1]) }
    }.environment(\.locale, Locale(identifier: data.rtl ? "ar" : "en"))

  }
}
private let cardNavy = Color(red: 0x16 / 255, green: 0x1B / 255, blue: 0x26 / 255)
private let cardNavyEnd = Color(red: 0x23 / 255, green: 0x2B / 255, blue: 0x3D / 255)
private let cardGold = Color(red: 0xE3 / 255, green: 0xC2 / 255, blue: 0x7A / 255)
private let cardCream = Color(red: 0xF4 / 255, green: 0xEB / 255, blue: 0xD8 / 255)
/// WidgetKit owns the removable background, including Home Screen clear and tinted modes.
private struct WidgetSurface: ViewModifier {
  var card: Bool = false
  @Environment(\.colorScheme) private var scheme
  private let style = UserDefaults(suiteName: appGroup)?.string(forKey: "widgetAppearance") ?? "automatic"

  @ViewBuilder private var backdrop: some View {
    if style == "green" {
      LinearGradient(colors: [Color(red: 0.09, green: 0.22, blue: 0.18), Color(red: 0.17, green: 0.35, blue: 0.29)],
        startPoint: .topLeading, endPoint: .bottomTrailing)
    } else if style == "navy" || card {
      LinearGradient(colors: [cardNavy, cardNavyEnd], startPoint: .topLeading, endPoint: .bottomTrailing)
    } else {
      Color(uiColor: .secondarySystemBackground)
    }
  }

  @ViewBuilder func body(content: Content) -> some View {
    let ink = content.environment(\.colorScheme, style == "automatic" && !card ? scheme : .dark)
    if #available(iOS 17.0, *) {
      ink.containerBackground(for: .widget) { backdrop }
    } else {
      ink.padding(8).background(backdrop)
    }
  }
}

/// The prayer card: the coming prayer large, its time and the time left, and
/// the day's five prayers along the bottom with the coming one framed in
/// gold; the app icon's navy and gold.
private struct CardView: View {
  let entry: Entry
  var body: some View {
    let data = entry.payload ?? (entry.isPreview ? Payload.sample(entry.date) : nil)
    Group {
      if let data, let next = data.next(entry.date), let day = data.day(entry.date) {
        VStack(alignment: .leading, spacing: 4) {
          HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
              Text(data.labels["next"] ?? "").font(.caption.weight(.bold)).foregroundStyle(cardGold)
              Text(next.name).font(.title.weight(.bold)).foregroundStyle(cardCream).lineLimit(1).minimumScaleFactor(0.6)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
              Text(next.time).font(.headline.weight(.bold)).foregroundStyle(cardCream)
              TimeLeft(data: data, at: next.at, now: entry.date).font(.caption2).foregroundStyle(cardGold)
              Text(day.date).font(.caption2).foregroundStyle(cardCream.opacity(0.6)).lineLimit(1)
              Text(day.hijri).font(.caption2).foregroundStyle(cardCream.opacity(0.6)).lineLimit(1)
            }
          }
          Rectangle().fill(cardGold.opacity(0.25)).frame(height: 1)
          let tomorrow = !day.rows.contains { $0.id != "sunrise" && $0.at > entry.date }
          LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 3), spacing: 2) {
            ForEach(day.rows) { row in
              let coming = row.id != "sunrise" && row.id == next.id && (tomorrow || row.at == next.at)
              VStack(spacing: 1) {
                Text(row.name).font(.caption2).foregroundStyle(cardCream.opacity(0.65)).lineLimit(1).minimumScaleFactor(0.7)
                Text(coming ? next.time : row.time).font(.caption2.weight(.bold)).foregroundStyle(cardCream).monospacedDigit().lineLimit(1).minimumScaleFactor(0.7)
              }
              .frame(maxWidth: .infinity).padding(.vertical, 1)
              .background(RoundedRectangle(cornerRadius: 10).fill(coming ? cardGold.opacity(0.18) : .clear))
              .overlay(RoundedRectangle(cornerRadius: 10).stroke(coming ? cardGold : .clear, lineWidth: 1))
            }
          }
        }
      } else {
        Text(Payload.read()?.labels["empty"] ?? NSLocalizedString("Open Mushafi to set your location", comment: "")).font(.caption).foregroundStyle(cardCream)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
      }
    }
    .padding(10)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .environment(\.layoutDirection, (data?.rtl ?? (systemIsArabic)) ? .rightToLeft : .leftToRight)
    .modifier(PrayerWidgetTap(entry: entry))
  }
}
private struct ScheduleView: View {
  @ScaledMetric(relativeTo: .caption2) private var countdownHeight: CGFloat = 14
  @Environment(\.widgetFamily) private var family
  let entry: Entry
  var body: some View {
    let data = entry.payload ?? (entry.isPreview ? Payload.sample(entry.date) : nil)
    Group {
      if let data, let day = data.day(entry.date) {
        let options = UserDefaults(suiteName: appGroup)?.dictionary(forKey: "prayerScheduleOptions") ?? [:]
        let largeText = options["largeText"] as? Bool ?? false
        let showSunrise = options["showSunrise"] as? Bool ?? true
        let showDate = options["showDate"] as? Bool ?? true
        let showCountdown = options["showCountdown"] as? Bool ?? true
        let next = data.next(entry.date)
        let today = day.rows.filter { $0.id != "sunrise" || showSunrise }
        let upcoming = Array(data.days.flatMap(\.rows)
          .filter { $0.id != "sunrise" && $0.at > entry.date }
          .sorted { $0.at < $1.at }.prefix(3))
        let afterLastPrayer = !day.rows.contains { $0.id != "sunrise" && $0.at > entry.date }
        VStack(alignment: .leading, spacing: family == .systemLarge ? 6 : 1) {
          if showDate {
            let date = Text(day.date).bold()
            let hijri = Text(day.hijri).foregroundStyle(.secondary)
            let stacked = VStack(alignment: .leading, spacing: 0) { date; hijri }
            Group {
              if #available(iOS 16.0, *) {
                ViewThatFits(in: .horizontal) {
                  HStack(spacing: 4) { date; hijri }
                  stacked
                }
              } else { stacked }
            }.font(.caption2).lineLimit(1)
          }
          GeometryReader { space in
            let spacing: CGFloat = family == .systemLarge ? 6 : 1
            let rowHeight: CGFloat = family == .systemLarge ? 22 : (largeText ? 19 : 15)
            let dayHeight = CGFloat(today.count) * rowHeight + CGFloat(max(0, today.count - 1)) * spacing
              + (showCountdown && next != nil ? countdownHeight : 0)
            let useUpcoming = options["upcomingOnly"] as? Bool == true || space.size.height < dayHeight
            scheduleRows(useUpcoming ? upcoming : today, data: data, next: next,
                         afterLastPrayer: !useUpcoming && afterLastPrayer,
                         largeText: largeText, showCountdown: showCountdown)
          }
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
      } else { Empty() }
    }.environment(\.layoutDirection, (data?.rtl ?? (systemIsArabic)) ? .rightToLeft : .leftToRight)
      .modifier(PrayerWidgetTap(entry: entry))
  }

  private func scheduleRows(_ rows: [Row], data: Payload, next: Row?, afterLastPrayer: Bool,
                            largeText: Bool, showCountdown: Bool) -> some View {
    VStack(spacing: family == .systemLarge ? 6 : 1) {
      ForEach(rows) { row in
        let coming = row.id == next?.id && (row.at == next?.at || afterLastPrayer)
        VStack(spacing: -2) {
          if coming, showCountdown, let next {
            TimeLeft(data: data, at: next.at, now: entry.date)
              .font(.caption2).foregroundStyle(.secondary)
              .fixedSize(horizontal: true, vertical: false)
          }
          HStack(spacing: 4) {
            Text(row.name)
            Spacer(minLength: 0)
            Text(coming ? (next?.time ?? row.time) : row.time).monospacedDigit().bold()
          }.font(family == .systemLarge ? .body : .system(size: largeText ? 15 : 12))
        }
        .lineLimit(1)
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(RoundedRectangle(cornerRadius: 6).fill(coming ? Color.primary.opacity(0.1) : .clear))
        .accessibilityElement(children: .combine)
      }
    }
  }
}
private struct AdhkarEntry: TimelineEntry { let date: Date; let payload: AdhkarPayload? }
private struct AdhkarProvider: TimelineProvider {
  func placeholder(in context: Context) -> AdhkarEntry { AdhkarEntry(date: .now, payload: nil) }
  func getSnapshot(in context: Context, completion: @escaping (AdhkarEntry) -> Void) { completion(AdhkarEntry(date: .now, payload: .read())) }
  func getTimeline(in context: Context, completion: @escaping (Timeline<AdhkarEntry>) -> Void) { completion(Timeline(entries: [AdhkarEntry(date: .now, payload: .read())], policy: .atEnd)) }
}
private struct SuggestedDhikrView: View {
  @Environment(\.widgetFamily) private var family
  let entry: AdhkarEntry
  var body: some View {
    Group { if let data = entry.payload {
      VStack(alignment:.leading,spacing:6) {
        Text(data.label).font(.caption).foregroundStyle(.secondary)
        Text(data.title).font(.headline).lineLimit(family == .systemSmall ? 2 : 3)
        ProgressView(value: Double(data.done), total: Double(max(data.total, 1)))
        if family != .systemSmall { Text(data.progressLabel ?? "\(data.done) / \(data.total)").font(.caption2).foregroundStyle(.secondary) }
      }.frame(maxWidth:.infinity,maxHeight:.infinity,alignment:.leading)
    } else {
      Text("Open Mushafi to load your adhkar.").font(.caption).frame(maxWidth:.infinity,maxHeight:.infinity,alignment:.leading)
    } }.environment(\.layoutDirection, (entry.payload?.rtl ?? (systemIsArabic)) ? .rightToLeft : .leftToRight)
      .widgetURL(URL(string: entry.payload.map { "mrequran://mre-quran/adhkar/\($0.payload.replacingOccurrences(of: "adhkar:", with: ""))" } ?? "mrequran://mre-quran/duas"))
  }
}
private let tasbihKey = "tasbihWidgetCount"
@available(iOS 17.0, *)
struct TasbihCountIntent: AppIntent {
  static var title: LocalizedStringResource = "Count"
  @MainActor func perform() async throws -> some IntentResult {
    let defaults = UserDefaults(suiteName: appGroup)
    defaults?.set((defaults?.integer(forKey: tasbihKey) ?? 0) + 1, forKey: tasbihKey)
    return .result()
  }
}
@available(iOS 17.0, *)
struct TasbihResetIntent: AppIntent {
  static var title: LocalizedStringResource = "Reset"
  @MainActor func perform() async throws -> some IntentResult {
    UserDefaults(suiteName: appGroup)?.set(0, forKey: tasbihKey)
    return .result()
  }
}
private struct TasbihEntry: TimelineEntry { let date: Date; let count: Int; var haptics = true }
private struct TasbihProvider: TimelineProvider {
  private func entry() -> TasbihEntry {
    let defaults = UserDefaults(suiteName: appGroup)
    return TasbihEntry(date: .now, count: defaults?.integer(forKey: tasbihKey) ?? 0,
                       haptics: defaults?.object(forKey: "tasbihHaptics") as? Bool ?? true)
  }
  func placeholder(in context: Context) -> TasbihEntry { TasbihEntry(date: .now, count: 0) }
  func getSnapshot(in context: Context, completion: @escaping (TasbihEntry) -> Void) { completion(entry()) }
  func getTimeline(in context: Context, completion: @escaping (Timeline<TasbihEntry>) -> Void) { completion(Timeline(entries: [entry()], policy: .never)) }
}
private struct TasbihView: View {
  let entry: TasbihEntry
  var body: some View {
    let rtl = AdhkarPayload.read()?.rtl ?? Payload.read()?.rtl ?? systemIsArabic
    return content
      .environment(\.layoutDirection, rtl ? .rightToLeft : .leftToRight)
      .environment(\.locale, Locale(identifier: rtl ? "ar" : "en"))
  }
  private var content: AnyView {
    if #available(iOS 17.0, *) {
      return AnyView(InteractiveTasbihView(entry: entry))
    }
    return AnyView(LegacyTasbihView(entry: entry))
  }
}
@available(iOS 17.0, *)
private struct InteractiveTasbihView: View {
  let entry: TasbihEntry
  var body: some View {
    let count = displayDigits(entry.count, arabic: AdhkarPayload.read()?.arabicDigits ?? systemIsArabic)
    VStack(spacing: 6) {
      Text("Tasbih").font(.caption).foregroundStyle(.secondary)
      Button(intent: TasbihCountIntent()) {
        Text(verbatim: count).widgetAccentable().font(.system(size: 44, weight: .bold))
          .monospacedDigit().lineLimit(1).minimumScaleFactor(0.5)
          .frame(maxWidth: .infinity, maxHeight: .infinity).contentShape(Rectangle())
      }.buttonStyle(.plain)
        .accessibilityLabel(Text("Count")).accessibilityValue(Text(verbatim: count))
        .sensoryFeedback(.impact(weight: .medium), trigger: entry.count) { old, new in
          new > old && entry.haptics
        }
      Button(intent: TasbihResetIntent()) { Text("Reset").font(.caption) }.buttonStyle(.bordered).disabled(entry.count == 0)
    }.frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
private struct LegacyTasbihView: View {
  let entry: TasbihEntry
  var body: some View {
    let count = displayDigits(entry.count, arabic: AdhkarPayload.read()?.arabicDigits ?? systemIsArabic)
    VStack(spacing: 6) {
      Text("Tasbih").font(.caption).foregroundStyle(.secondary)
      Text(verbatim: count).font(.system(size: 44, weight: .bold))
      Text("Update iOS to use the tasbih").font(.caption2).foregroundStyle(.secondary)
    }.frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
struct TasbihWidget: Widget { let kind="TasbihWidget"; var body: some WidgetConfiguration { StaticConfiguration(kind:kind,provider:TasbihProvider()){TasbihView(entry:$0).modifier(WidgetSurface())}.configurationDisplayName("Tasbih").description("Count your tasbih from the home screen").supportedFamilies([.systemSmall,.systemMedium]) } }
struct PrayerCardWidget: Widget { let kind="PrayerCardWidget"; var body: some WidgetConfiguration { StaticConfiguration(kind:kind,provider:Provider()){CardView(entry:$0).modifier(WidgetSurface(card: true))}.configurationDisplayName("Prayer card").description("The next prayer, countdown, prayers, sunrise and date").supportedFamilies([.systemMedium]) } }
struct PrayerWidget: Widget { let kind="NextPrayerWidget"; var body: some WidgetConfiguration { StaticConfiguration(kind:kind,provider:Provider()){NextView(entry:$0).modifier(WidgetSurface())}.configurationDisplayName("Prayer times").description("The next prayer and countdown").supportedFamilies([.systemSmall,.systemMedium]) } }
struct PrayerScheduleWidget: Widget { let kind="PrayerScheduleWidget"; var body: some WidgetConfiguration { StaticConfiguration(kind:kind,provider:Provider()){ScheduleView(entry:$0).modifier(WidgetSurface())}.configurationDisplayName("Today’s prayer times").description("Today’s prayers, sunrise and date").supportedFamilies([.systemSmall,.systemMedium,.systemLarge]) } }
struct SuggestedDhikrWidget: Widget { let kind="SuggestedDhikrWidget"; var body: some WidgetConfiguration { StaticConfiguration(kind:kind,provider:AdhkarProvider()){SuggestedDhikrView(entry:$0).modifier(WidgetSurface())}.configurationDisplayName("Suggested dhikr").description("A suggested dhikr and your saved progress").supportedFamilies([.systemSmall,.systemMedium]) } }
@main struct PrayerWidgetBundle: WidgetBundle { var body: some Widget { PrayerWidget(); PrayerCardWidget(); PrayerScheduleWidget(); SuggestedDhikrWidget(); TasbihWidget() } }
