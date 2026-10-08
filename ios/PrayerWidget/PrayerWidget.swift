import SwiftUI
import WidgetKit

private let appGroup = "group.net.mrecode.mreQuran"
private let widgetKind = "NextPrayerWidget"

private struct PrayerEntry: TimelineEntry {
  let date: Date
  let label: String?
  let title: String?
  let time: String?
  let at: Date?
}

private struct PrayerProvider: TimelineProvider {
  func placeholder(in context: Context) -> PrayerEntry {
    PrayerEntry(date: .now, label: "الصلاة القادمة", title: "الفجر", time: "٠٥:٠٠", at: .now.addingTimeInterval(3600))
  }

  func getSnapshot(in context: Context, completion: @escaping (PrayerEntry) -> Void) {
    completion(entry())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerEntry>) -> Void) {
    let current = entry()
    let refresh = current.at?.addingTimeInterval(1) ?? .now.addingTimeInterval(3600)
    completion(Timeline(entries: [current], policy: .after(refresh)))
  }

  private func entry() -> PrayerEntry {
    let defaults = UserDefaults(suiteName: appGroup)
    let timestamp = defaults?.double(forKey: "at") ?? 0
    return PrayerEntry(
      date: .now,
      label: defaults?.string(forKey: "label"),
      title: defaults?.string(forKey: "title"),
      time: defaults?.string(forKey: "time"),
      at: timestamp > 0 ? Date(timeIntervalSince1970: timestamp / 1000) : nil,
    )
  }
}

private struct PrayerWidgetView: View {
  let entry: PrayerEntry

  var body: some View {
    if let label = entry.label, let title = entry.title, let time = entry.time, let at = entry.at {
      VStack(alignment: .leading, spacing: 5) {
        Text(label)
          .font(.caption)
          .foregroundStyle(.secondary)
        Text(title).font(.headline)
        Text(time).font(.title3.weight(.semibold))
        Text(at, style: .timer)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
      .background(Color(uiColor: .secondarySystemBackground))
      .widgetURL(URL(string: "mrequran://prayer-times"))
    } else {
      VStack(alignment: .leading, spacing: 8) {
        Text("مواقيت الصلاة").font(.headline)
        Text("افتح مصحف MRE لتحديد موقعك")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
      .background(Color(uiColor: .secondarySystemBackground))
    }
  }
}

struct PrayerWidget: Widget {
  let kind = widgetKind

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: PrayerProvider()) { entry in
      PrayerWidgetView(entry: entry)
    }
    .configurationDisplayName("مواقيت الصلاة")
    .description("الصلاة القادمة والوقت المتبقي")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

@main
struct PrayerWidgetBundle: WidgetBundle {
  var body: some Widget {
    PrayerWidget()
  }
}
