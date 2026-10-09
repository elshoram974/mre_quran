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
    return Payload(labels: labels, days: days)
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
private struct Entry: TimelineEntry { let date: Date; let payload: Payload? }
private struct Provider: TimelineProvider {
  func placeholder(in context: Context) -> Entry { Entry(date: .now, payload: nil) }
  func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) { completion(Entry(date: .now, payload: .read())) }
  func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
    let entry = Entry(date: .now, payload: .read()); let refresh = entry.payload?.next(.now)?.at.addingTimeInterval(1) ?? .now.addingTimeInterval(3600)
    completion(Timeline(entries: [entry], policy: .after(refresh)))
  }
}
private struct Empty: View { var body: some View { Text(Payload.read()?.labels["empty"] ?? "Open MRE Quran to set your location").font(.caption).frame(maxWidth:.infinity,maxHeight:.infinity,alignment:.leading).background(Color(uiColor:.secondarySystemBackground)) } }
private struct NextView: View {
  let entry: Entry
  var body: some View {
    if let data = entry.payload, let next = data.next(entry.date) {
      VStack(alignment:.leading,spacing:5) { Text(data.labels["next"] ?? "Next prayer").font(.caption).foregroundStyle(.secondary); Text(next.name).font(.headline); Text(next.time).font(.title3.weight(.semibold)); Text(next.at,style:.timer).font(.caption).foregroundStyle(.secondary) }.frame(maxWidth:.infinity,maxHeight:.infinity,alignment:.leading).background(Color(uiColor:.secondarySystemBackground)).widgetURL(URL(string:"mrequran://prayer-times"))
    } else { Empty() }
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
struct PrayerWidget: Widget { let kind="NextPrayerWidget"; var body: some WidgetConfiguration { StaticConfiguration(kind:kind,provider:Provider()){NextView(entry:$0)}.configurationDisplayName("مواقيت الصلاة").description("الصلاة القادمة والوقت المتبقي").supportedFamilies([.systemSmall,.systemMedium]) } }
struct PrayerScheduleWidget: Widget { let kind="PrayerScheduleWidget"; var body: some WidgetConfiguration { StaticConfiguration(kind:kind,provider:Provider()){ScheduleView(entry:$0)}.configurationDisplayName("مواقيت اليوم").description("مواقيت الصلوات الخمس").supportedFamilies([.systemMedium,.systemLarge]) } }
@main struct PrayerWidgetBundle: WidgetBundle { var body: some Widget { PrayerWidget(); PrayerScheduleWidget() } }
