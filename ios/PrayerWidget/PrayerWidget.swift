import AppIntents
import SwiftUI
import WidgetKit

private let appGroup = "group.net.mrecode.mreQuran"
private let payloadKey = "prayerWidgetPayload"

private struct Row: Identifiable {
  let id: String; let name: String; let time: String; let at: Date
}
private struct Day { let start: Date; let end: Date; let date: String; let hijri: String; let rows: [Row] }
private struct Payload {
  let labels: [String: String]; let days: [Day]
  /// Whether the time left counts down to the second (a setting in the app).
  var seconds: Bool = false
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
    return Payload(labels: labels, days: days, seconds: (root["seconds"] as? Bool) ?? false)
  }

  /// What the widget gallery shows before the app has sent any times: a
  /// sample day with Asr coming, in Arabic.
  static func sample(_ now: Date) -> Payload {
    let names = [("fajr", "الفجر", "٤:٥٤ ص", -6.0), ("dhuhr", "الظهر", "١١:٤٢ ص", -1.0), ("asr", "العصر", "٢:٣٧ م", 1.4), ("maghrib", "المغرب", "٤:٥٧ م", 3.7), ("isha", "العشاء", "٦:١٨ م", 5.1)]
    let rows = names.map { Row(id: $0.0, name: $0.1, time: $0.2, at: now.addingTimeInterval($0.3 * 3600)) }
    let day = Day(start: now.addingTimeInterval(-12 * 3600), end: now.addingTimeInterval(12 * 3600), date: "الثلاثاء ١٧ نوفمبر", hijri: "٢٦ جمادى الأولى ١٤٤٨", rows: rows)
    return Payload(labels: ["next": "الصلاة القادمة", "remaining": "بعد %1$s", "hours": "%1$s س %2$s د", "minutes": "%1$s د", "empty": ""], days: [day])
  }
  func day(_ now: Date) -> Day? { days.first { $0.start <= now && now < $0.end } }
  func next(_ now: Date) -> Row? { days.flatMap(\.rows).first { $0.id != "sunrise" && $0.at > now } }
  func remaining(_ at: Date, _ now: Date) -> String {
    let minutes = max(1, Int(at.timeIntervalSince(now) / 60)); let h = minutes / 60
    let duration = h > 0 ? replace(labels["hours"] ?? "%1$s h %2$s min", ["%1$s":"\(h)", "%2$s":"\(minutes % 60)"]) : replace(labels["minutes"] ?? "%1$s min", ["%1$s":"\(minutes)"])
    return replace(labels["remaining"] ?? "%1$s left", ["%1$s":duration])
  }
  private func replace(_ text: String, _ values: [String:String]) -> String { values.reduce(text) { $0.replacingOccurrences(of: $1.key, with: $1.value) } }
}
private struct Entry: TimelineEntry { let date: Date; let payload: Payload?; var isPreview: Bool = false }
private struct AdhkarPayload {
  let label: String; let title: String; let done: Int; let total: Int; let payload: String
  static func read() -> AdhkarPayload? {
    guard let raw = UserDefaults(suiteName: appGroup)?.dictionary(forKey: "adhkarWidgetPayload"),
      let label = raw["label"] as? String, let title = raw["title"] as? String,
      let done = raw["done"] as? NSNumber, let total = raw["total"] as? NSNumber,
      let payload = raw["payload"] as? String else { return nil }
    return AdhkarPayload(label: label, title: title, done: done.intValue, total: total.intValue, payload: payload)
  }
}
private struct Provider: TimelineProvider {
  func placeholder(in context: Context) -> Entry { Entry(date: .now, payload: nil, isPreview: true) }
  func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) { completion(Entry(date: .now, payload: .read(), isPreview: context.isPreview)) }
  func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
    let entry = Entry(date: .now, payload: .read()); let refresh = entry.payload?.next(.now)?.at.addingTimeInterval(1) ?? .now.addingTimeInterval(3600)
    completion(Timeline(entries: [entry], policy: .after(refresh)))
  }
}
private struct Empty: View { var body: some View { Text(Payload.read()?.labels["empty"] ?? "Open Mushafi to set your location").font(.caption).frame(maxWidth:.infinity,maxHeight:.infinity,alignment:.leading).background(Color(uiColor:.secondarySystemBackground)) } }
private struct NextView: View {
  let entry: Entry
  var body: some View {
    if let data = entry.payload, let next = data.next(entry.date) {
      VStack(alignment:.leading,spacing:5) { Text(data.labels["next"] ?? "Next prayer").font(.caption).foregroundStyle(.secondary); Text(next.name).font(.headline); Text(next.time).font(.title3.weight(.semibold)); TimeLeft(data: data, at: next.at, now: entry.date).font(.caption).foregroundStyle(.secondary) }.frame(maxWidth:.infinity,maxHeight:.infinity,alignment:.leading).background(Color(uiColor:.secondarySystemBackground)).widgetURL(URL(string:"mrequran://prayer-times"))
    } else { Empty() }
  }
}
/// The time left until [at]: to the second when the person chose it in the
/// app (the system counts it down on its own), else in hours and minutes,
/// redrawn at each new timeline entry.
private struct TimeLeft: View {
  let data: Payload; let at: Date; let now: Date
  var body: some View {
    if data.seconds { Text(at, style: .timer).monospacedDigit() } else { Text(data.remaining(at, now)) }
  }
}
private let cardNavy = Color(red: 0x16 / 255, green: 0x1B / 255, blue: 0x26 / 255)
private let cardNavyEnd = Color(red: 0x23 / 255, green: 0x2B / 255, blue: 0x3D / 255)
private let cardGold = Color(red: 0xE3 / 255, green: 0xC2 / 255, blue: 0x7A / 255)
private let cardCream = Color(red: 0xF4 / 255, green: 0xEB / 255, blue: 0xD8 / 255)
/// The prayer card: the coming prayer large, its time and the time left, and
/// the day's five prayers along the bottom with the coming one framed in
/// gold; the app icon's navy and gold.
private struct CardView: View {
  let entry: Entry
  var body: some View {
    let data = entry.payload ?? (entry.isPreview ? Payload.sample(entry.date) : nil)
    Group {
      if let data, let next = data.next(entry.date), let day = data.day(entry.date) {
        VStack(alignment: .leading, spacing: 8) {
          HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
              Text(data.labels["next"] ?? "").font(.caption.weight(.bold)).foregroundStyle(cardGold)
              Text(next.name).font(.title.weight(.bold)).foregroundStyle(cardCream).lineLimit(1).minimumScaleFactor(0.6)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
              Text(next.time).font(.title3.weight(.bold)).foregroundStyle(cardCream)
              TimeLeft(data: data, at: next.at, now: entry.date).font(.footnote).foregroundStyle(cardGold)
              Text(day.hijri).font(.caption2).foregroundStyle(cardCream.opacity(0.6))
            }
          }
          Rectangle().fill(cardGold.opacity(0.25)).frame(height: 1)
          let prayers = day.rows.filter { $0.id != "sunrise" }
          let tomorrow = !prayers.contains { $0.at > entry.date }
          HStack(spacing: 4) {
            ForEach(prayers) { row in
              let coming = row.id == next.id && (tomorrow || row.at == next.at)
              VStack(spacing: 1) {
                Text(row.name).font(.caption2).foregroundStyle(cardCream.opacity(0.65))
                Text(coming ? next.time : row.time).font(.caption.weight(.bold)).foregroundStyle(cardCream).monospacedDigit()
              }
              .frame(maxWidth: .infinity).padding(.vertical, 5)
              .background(RoundedRectangle(cornerRadius: 10).fill(coming ? cardGold.opacity(0.18) : .clear))
              .overlay(RoundedRectangle(cornerRadius: 10).stroke(coming ? cardGold : .clear, lineWidth: 1))
            }
          }
        }
      } else {
        Text(Payload.read()?.labels["empty"] ?? "Open Mushafi to set your location").font(.caption).foregroundStyle(cardCream)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
      }
    }
    .padding(14)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(LinearGradient(colors: [cardNavy, cardNavyEnd], startPoint: .topLeading, endPoint: .bottomTrailing))
    .environment(\.layoutDirection, .rightToLeft)
    .widgetURL(URL(string: "mrequran://prayer-times"))
  }
}
private struct ScheduleView: View {
  let entry: Entry
  var body: some View {
    if let data = entry.payload, let day = data.day(entry.date) {
      VStack(alignment:.leading,spacing:4) { Text(day.date).font(.caption).foregroundStyle(.secondary); Text(day.hijri).font(.caption2).foregroundStyle(.secondary); ForEach(day.rows.filter{$0.id != "sunrise"}) { row in HStack { VStack(alignment:.leading,spacing:1) { Text(row.name); if row.at > entry.date { Text(data.remaining(row.at,entry.date)).font(.caption2).foregroundStyle(.secondary) } }; Spacer(); Text(row.time).monospacedDigit() }.font(.caption) } }.frame(maxWidth:.infinity,maxHeight:.infinity,alignment:.leading).background(Color(uiColor:.secondarySystemBackground)).widgetURL(URL(string:"mrequran://prayer-times"))
    } else { Empty() }
  }
}
private struct AdhkarEntry: TimelineEntry { let date: Date; let payload: AdhkarPayload? }
private struct AdhkarProvider: TimelineProvider {
  func placeholder(in context: Context) -> AdhkarEntry { AdhkarEntry(date: .now, payload: nil) }
  func getSnapshot(in context: Context, completion: @escaping (AdhkarEntry) -> Void) { completion(AdhkarEntry(date: .now, payload: .read())) }
  func getTimeline(in context: Context, completion: @escaping (Timeline<AdhkarEntry>) -> Void) { completion(Timeline(entries: [AdhkarEntry(date: .now, payload: .read())], policy: .atEnd)) }
}
private struct SuggestedDhikrView: View {
  let entry: AdhkarEntry
  var body: some View {
    if let data = entry.payload {
      VStack(alignment:.leading,spacing:6) {
        Text(data.label).font(.caption).foregroundStyle(.secondary)
        Text(data.title).font(.headline).lineLimit(2)
        ProgressView(value: Double(data.done), total: Double(max(data.total, 1)))
        Text("\(data.done) / \(data.total)").font(.caption2).foregroundStyle(.secondary)
      }.frame(maxWidth:.infinity,maxHeight:.infinity,alignment:.leading).background(Color(uiColor:.secondarySystemBackground)).widgetURL(URL(string:"mrequran://mre-quran/adhkar/\(data.payload.replacingOccurrences(of: "adhkar:", with: ""))"))
    } else {
      Text("Open Mushafi to load your adhkar.").font(.caption).frame(maxWidth:.infinity,maxHeight:.infinity,alignment:.leading).background(Color(uiColor:.secondarySystemBackground))
    }
  }
}
private let tasbihKey = "tasbihWidgetCount"
@available(iOS 17.0, *)
struct TasbihCountIntent: AppIntent {
  static var title: LocalizedStringResource = "Count"
  func perform() async throws -> some IntentResult {
    let defaults = UserDefaults(suiteName: appGroup)
    defaults?.set((defaults?.integer(forKey: tasbihKey) ?? 0) + 1, forKey: tasbihKey)
    return .result()
  }
}
@available(iOS 17.0, *)
struct TasbihResetIntent: AppIntent {
  static var title: LocalizedStringResource = "Reset"
  func perform() async throws -> some IntentResult {
    UserDefaults(suiteName: appGroup)?.set(0, forKey: tasbihKey)
    return .result()
  }
}
private struct TasbihEntry: TimelineEntry { let date: Date; let count: Int }
private struct TasbihProvider: TimelineProvider {
  private func entry() -> TasbihEntry { TasbihEntry(date: .now, count: UserDefaults(suiteName: appGroup)?.integer(forKey: tasbihKey) ?? 0) }
  func placeholder(in context: Context) -> TasbihEntry { TasbihEntry(date: .now, count: 0) }
  func getSnapshot(in context: Context, completion: @escaping (TasbihEntry) -> Void) { completion(entry()) }
  func getTimeline(in context: Context, completion: @escaping (Timeline<TasbihEntry>) -> Void) { completion(Timeline(entries: [entry()], policy: .never)) }
}
private struct TasbihView: View {
  let entry: TasbihEntry
  var body: some View {
    VStack(spacing: 6) {
      Text("مسبحة").font(.caption).foregroundStyle(.secondary)
      if #available(iOS 17.0, *) {
        Button(intent: TasbihCountIntent()) { Text("\(entry.count)").font(.system(size: 44, weight: .bold)).minimumScaleFactor(0.5).frame(maxWidth: .infinity, maxHeight: .infinity) }.buttonStyle(.plain)
        Button(intent: TasbihResetIntent()) { Text("تصفير").font(.caption2) }.buttonStyle(.bordered)
      } else {
        Text("\(entry.count)").font(.system(size: 44, weight: .bold))
        Text("حدّث iOS لاستخدام المسبحة").font(.caption2).foregroundStyle(.secondary)
      }
    }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Color(uiColor: .secondarySystemBackground))
  }
}
struct TasbihWidget: Widget { let kind="TasbihWidget"; var body: some WidgetConfiguration { StaticConfiguration(kind:kind,provider:TasbihProvider()){TasbihView(entry:$0)}.configurationDisplayName("مسبحة").description("سبّح وعُدّ تسبيحك من الشاشة الرئيسية").supportedFamilies([.systemSmall,.systemMedium]) } }
struct PrayerCardWidget: Widget { let kind="PrayerCardWidget"; var body: some WidgetConfiguration { StaticConfiguration(kind:kind,provider:Provider()){CardView(entry:$0)}.configurationDisplayName("بطاقة الصلاة").description("الصلاة القادمة والوقت المتبقي لها، وصلوات اليوم الخمس").supportedFamilies([.systemMedium]) } }
struct PrayerWidget: Widget { let kind="NextPrayerWidget"; var body: some WidgetConfiguration { StaticConfiguration(kind:kind,provider:Provider()){NextView(entry:$0)}.configurationDisplayName("مواقيت الصلاة").description("الصلاة القادمة والوقت المتبقي").supportedFamilies([.systemSmall,.systemMedium]) } }
struct PrayerScheduleWidget: Widget { let kind="PrayerScheduleWidget"; var body: some WidgetConfiguration { StaticConfiguration(kind:kind,provider:Provider()){ScheduleView(entry:$0)}.configurationDisplayName("مواقيت اليوم").description("مواقيت الصلوات الخمس").supportedFamilies([.systemMedium,.systemLarge]) } }
struct SuggestedDhikrWidget: Widget { let kind="SuggestedDhikrWidget"; var body: some WidgetConfiguration { StaticConfiguration(kind:kind,provider:AdhkarProvider()){SuggestedDhikrView(entry:$0)}.configurationDisplayName("ذكر مقترح").description("ذكر مقترح مع تقدمك المحفوظ").supportedFamilies([.systemSmall,.systemMedium]) } }
@main struct PrayerWidgetBundle: WidgetBundle { var body: some Widget { PrayerWidget(); PrayerCardWidget(); PrayerScheduleWidget(); SuggestedDhikrWidget(); TasbihWidget() } }
