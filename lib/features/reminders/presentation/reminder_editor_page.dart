import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';
import 'package:mre_fields/mre_fields.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/layout/adaptive_layout.dart';
import '../../../core/time/ticking_clock.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_confirm_sheet.dart';
import '../../../core/widgets/app_notice.dart';
import '../../../core/widgets/app_page_scaffold.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_segmented_control.dart';
import '../../../core/widgets/app_select_field.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/widgets/app_time_picker.dart';
import '../../settings/application/digits_provider.dart';
import '../application/custom_reminders_provider.dart';
import '../domain/custom_reminder.dart';
import 'reminder_labels.dart';

/// The form to make a reminder or change one: its words, how often it comes,
/// the days, and one or more times, with when it will first come.
class ReminderEditorPage extends ConsumerWidget {
  /// Creates the form for the reminder [reminderId], or a new one when null.
  const ReminderEditorPage({super.key, this.reminderId});

  /// The reminder to change; null makes a new one.
  final String? reminderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final reminders = ref.watch(customRemindersProvider).value;
    final existing = reminders
        ?.where((reminder) => reminder.id == reminderId)
        .firstOrNull;
    return AppPageScaffold(
      title: reminderId == null
          ? l10n.reminderNewTitle
          : l10n.reminderEditTitle,
      body: reminders == null
          ? Padding(
              padding: pagePadding(context),
              child: const AppShimmer(
                child: Column(
                  children: [SkeletonBox(height: 200), SizedBox(height: 12)],
                ),
              ),
            )
          : ContentContainer(
              // The same form while the list under it changes.
              child: _EditorForm(
                key: ValueKey(reminderId),
                initial: existing,
                canAdd: reminders.length < CustomReminder.maxReminders,
              ),
            ),
    );
  }
}

class _EditorForm extends ConsumerStatefulWidget {
  const _EditorForm({super.key, required this.initial, required this.canAdd});

  final CustomReminder? initial;
  final bool canAdd;

  @override
  ConsumerState<_EditorForm> createState() => _EditorFormState();
}

class _EditorFormState extends ConsumerState<_EditorForm> {
  late final TextEditingController _title;
  late final TextEditingController _note;
  late ReminderRepeat _repeat;
  late Set<int> _weekdays;
  late int _dayOfMonth;
  late List<int> _times;
  late final String _id;
  bool _tried = false;
  bool _saving = false;

  /// The time a new reminder starts with: nine in the morning.
  static const int _defaultTime = 9 * 60;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _id = initial?.id ?? DateTime.now().microsecondsSinceEpoch.toString();
    _title = TextEditingController(text: initial?.title ?? '');
    _note = TextEditingController(text: initial?.note ?? '');
    _repeat = initial?.repeat ?? ReminderRepeat.daily;
    _weekdays = {...?initial?.weekdays};
    _dayOfMonth = initial?.dayOfMonth ?? 1;
    _times = [...?initial?.times];
    if (initial == null) _times = [_defaultTime];
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  CustomReminder get _draft => CustomReminder(
    id: _id,
    title: _title.text,
    note: _note.text,
    repeat: _repeat,
    weekdays: _weekdays,
    dayOfMonth: _dayOfMonth,
    times: _times,
    enabled: widget.initial?.enabled ?? true,
  ).normalized();

  Future<void> _addTime() async {
    final picked = await AppTimePicker.show(
      context: context,
      initialMinutes: _times.isEmpty ? _defaultTime : _times.last,
    );
    if (picked == null || !mounted) return;
    setState(() => _times = ({..._times, picked}.toList()..sort()));
  }

  Future<void> _changeTime(int index) async {
    final picked = await AppTimePicker.show(
      context: context,
      initialMinutes: _times[index],
    );
    if (picked == null || !mounted) return;
    setState(() {
      _times = ({
        for (var i = 0; i < _times.length; i++)
          if (i != index) _times[i],
        picked,
      }.toList()..sort());
    });
  }

  Future<void> _save() async {
    final draft = _draft;
    if (draft.problem != null) {
      setState(() => _tried = true);
      return;
    }
    setState(() => _saving = true);
    final result = await ref.read(customRemindersProvider.notifier).save(draft);
    if (!mounted) return;
    if (result == ReminderSaveResult.refused) {
      setState(() {
        _saving = false;
        _tried = true;
      });
      return;
    }
    context.pop(result);
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final sure = await AppConfirmSheet.show(
      context: context,
      title: l10n.reminderDelete,
      message: l10n.reminderDeleteConfirm(widget.initial!.title),
      confirmLabel: l10n.reminderDeleteYes,
      cancelLabel: l10n.reminderKeep,
    );
    if (!sure || !mounted) return;
    await ref.read(customRemindersProvider.notifier).remove(_id);
    if (mounted) context.pop();
  }

  String? _problemText(CustomReminder draft) {
    final l10n = context.l10n;
    final digits = ref.read(digitsFormatterProvider);
    return switch (draft.problem) {
      null => null,
      ReminderProblem.noTitle => l10n.reminderProblemTitle,
      ReminderProblem.noTime => l10n.reminderProblemTime,
      ReminderProblem.noDay => l10n.reminderProblemDay,
      ReminderProblem.tooManyTimes => l10n.reminderTimesLimit(
        digits(CustomReminder.maxTimes),
      ),
      ReminderProblem.tooManyMoments => l10n.reminderProblemMoments(
        digits(CustomReminder.maxSlots),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final digits = ref.watch(digitsFormatterProvider);
    final displayDigits = ref.watch(displayDigitsFormatterProvider);
    final draft = _draft;
    final problem = _problemText(draft);
    final next = draft.problem == null
        ? draft.nextAfter(ref.watch(clockProvider)())
        : null;
    return ListView(
      padding: pagePadding(context),
      children: [
        MRETextField(
          controller: _title,
          labelText: l10n.reminderTitleField,
          hintText: l10n.reminderTitleHint,
          maxLength: CustomReminder.maxTitle,
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        MRETextField(
          controller: _note,
          labelText: l10n.reminderNoteField,
          maxLength: CustomReminder.maxNote,
          maxLines: 2,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 24),
        AppSectionHeader(title: l10n.reminderRepeatLabel),
        AppSegmentedControl<ReminderRepeat>(
          segments: {
            ReminderRepeat.daily: l10n.reminderRepeatDaily,
            ReminderRepeat.weekly: l10n.reminderRepeatWeekly,
            ReminderRepeat.monthly: l10n.reminderRepeatMonthly,
          },
          value: _repeat,
          onChanged: (value) => setState(() => _repeat = value),
        ),
        if (_repeat == ReminderRepeat.weekly) ...[
          const SizedBox(height: 16),
          AppSectionHeader(title: l10n.reminderDaysLabel),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (var day = DateTime.monday; day <= DateTime.sunday; day++)
                FilterChip(
                  label: Text(weekdayName(locale, day)),
                  selected: _weekdays.contains(day),
                  onSelected: (on) => setState(
                    () => on ? _weekdays.add(day) : _weekdays.remove(day),
                  ),
                ),
            ],
          ),
        ],
        if (_repeat == ReminderRepeat.monthly) ...[
          const SizedBox(height: 16),
          AppSelectField<int>(
            label: l10n.reminderMonthDayLabel,
            value: _dayOfMonth,
            options: [
              for (var day = 1; day <= CustomReminder.maxDayOfMonth; day++)
                AppSelectOption(value: day, label: digits(day)),
            ],
            onChanged: (value) => setState(() => _dayOfMonth = value),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.reminderMonthDayHint(digits(CustomReminder.maxDayOfMonth)),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 24),
        AppSectionHeader(
          title: l10n.reminderTimesLabel,
          subtitle: l10n.reminderTimesHint,
        ),
        for (var index = 0; index < _times.length; index++) ...[
          AppCard(
            padding: const EdgeInsetsDirectional.only(start: 16, end: 4),
            onTap: () => _changeTime(index),
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    formatReminderTime(context, _times[index], displayDigits),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: l10n.reminderRemoveTime,
                  onPressed: _times.length > 1
                      ? () => setState(() => _times.removeAt(index))
                      : null,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (_times.length < CustomReminder.maxTimes)
          OutlinedButton.icon(
            onPressed: _addTime,
            icon: const Icon(Icons.add),
            label: Text(l10n.reminderAddTime),
          )
        else
          AppNotice(
            l10n.reminderTimesLimit(digits(CustomReminder.maxTimes)),
            icon: Icons.info_outline,
          ),
        const SizedBox(height: 24),
        if (next != null)
          AppNotice(
            l10n.reminderFirstAt(
              '${displayDigits(DateFormat.MMMEd(locale).format(next))} · '
              '${formatReminderTime(context, next.hour * 60 + next.minute, displayDigits)}',
            ),
            icon: Icons.event_available_outlined,
          ),
        if (_tried && problem != null) ...[
          const SizedBox(height: 8),
          AppNotice(problem, error: true),
        ],
        if (_tried && widget.initial == null && !widget.canAdd) ...[
          const SizedBox(height: 8),
          AppNotice(
            l10n.reminderLimit(digits(CustomReminder.maxReminders)),
            error: true,
          ),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(l10n.reminderSave),
        ),
        if (widget.initial != null) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: _saving ? null : _delete,
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: Text(l10n.reminderDelete),
          ),
        ],
      ],
    );
  }
}
