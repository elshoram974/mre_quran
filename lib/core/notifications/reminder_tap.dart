/// A tap on a notification, as an event.
///
/// A provider holding a bare payload would miss the second tap on the same
/// notice (the payload is equal, so nothing "changes"). Each tap is its own
/// object, and objects of this class are never equal to each other.
final class ReminderTap {
  /// Creates the event for [payload].
  ReminderTap(this.payload);

  /// What the notification points at; see `ReminderPayload`.
  final String payload;
}
