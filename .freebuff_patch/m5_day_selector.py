from pathlib import Path

p = Path('lib/features/timetable/presentation/screens/timetable_screen.dart')
s = p.read_text(encoding='utf-8')
before = len(s)

# ---------------------------------------------------------------- imports ----
old_import = (
    "import 'package:college_os/features/notes/presentation/widgets/note_editor_sheet.dart';\n"
)
new_import = (
    "import 'package:college_os/features/notes/presentation/widgets/note_editor_sheet.dart';\n"
    "import 'package:college_os/features/notifications/domain/class_reminder_preset.dart';\n"
)
assert s.count(old_import) == 1
s = s.replace(old_import, new_import)

# ------------------------------------------------------- selection state -----
old_state = (
    "class _TimetableScreenState extends ConsumerState<TimetableScreen> {\n"
    "  late int _selectedWeekday;\n"
    "\n"
    "  @override\n"
    "  void initState() {\n"
    "    super.initState();\n"
    "    final today = DateTime.now().weekday;\n"
    "    _selectedWeekday = timetableWeekdays.contains(today)\n"
    "        ? today\n"
    "        : DateTime.monday;\n"
    "  }\n"
)
new_state = (
    "class _TimetableScreenState extends ConsumerState<TimetableScreen> {\n"
    "  late int _selectedWeekday;\n"
    "\n"
    "  /// 1 when the student moved to a later day, -1 when they moved back.\n"
    "  ///\n"
    "  /// The pill glides in that direction, and the day's content enters from\n"
    "  /// the same side, so the two movements read as one gesture.\n"
    "  int _daySlideDirection = 1;\n"
    "\n"
    "  @override\n"
    "  void initState() {\n"
    "    super.initState();\n"
    "    final today = DateTime.now().weekday;\n"
    "    _selectedWeekday = timetableWeekdays.contains(today)\n"
    "        ? today\n"
    "        : DateTime.monday;\n"
    "  }\n"
    "\n"
    "  void _selectWeekday(int day) {\n"
    "    if (day == _selectedWeekday) return;\n"
    "    setState(() {\n"
    "      _daySlideDirection = day > _selectedWeekday ? 1 : -1;\n"
    "      _selectedWeekday = day;\n"
    "    });\n"
    "  }\n"
    "\n"
    "  Widget _dayContentTransition(Widget child, Animation<double> animation) {\n"
    "    final offset = Tween<Offset>(\n"
    "      begin: Offset(AppMotion.dayContentSlide * _daySlideDirection, 0),\n"
    "      end: Offset.zero,\n"
    "    ).animate(CurvedAnimation(parent: animation, curve: AppCurves.standard));\n"
    "    return FadeTransition(\n"
    "      opacity: animation,\n"
    "      child: SlideTransition(position: offset, child: child),\n"
    "    );\n"
    "  }\n"
)
assert s.count(old_state) == 1
s = s.replace(old_state, new_state)

# -------------------------------------------------------- schedule layout ----
start = s.index(
    "    return Column(\n"
    "      crossAxisAlignment: CrossAxisAlignment.stretch,\n"
    "      children: [\n"
    "        _DaySelector(\n"
    "          selected: _selectedWeekday,\n"
    "          onSelected: (day) => setState(() => _selectedWeekday = day),\n"
    "        ),\n"
)
end = s.index("  Future<void> _showEntryForm({")
tail = "  Future<void> _showEntryForm({"
new_schedule = (
    "    final reduceMotion =\n"
    "        MediaQuery.maybeOf(context)?.disableAnimations ?? false;\n"
    "    return Column(\n"
    "      crossAxisAlignment: CrossAxisAlignment.stretch,\n"
    "      children: [\n"
    "        _DaySelector(selected: _selectedWeekday, onSelected: _selectWeekday),\n"
    "        if (schedule.isNotEmpty) ...[\n"
    "          const SizedBox(height: AppSpacing.md),\n"
    "          _NextClassCard(result: next),\n"
    "        ],\n"
    "        const SizedBox(height: AppSpacing.lg),\n"
    "        // The heading and the day's classes travel together, so choosing a\n"
    "        // day reads as one content change rather than a text swap.\n"
    "        AnimatedSwitcher(\n"
    "          duration: reduceMotion ? Duration.zero : AppDurations.dayContent,\n"
    "          switchInCurve: AppCurves.standard,\n"
    "          switchOutCurve: AppCurves.standard,\n"
    "          layoutBuilder: (currentChild, previousChildren) => Stack(\n"
    "            alignment: Alignment.topCenter,\n"
    "            children: [\n"
    "              ...previousChildren,\n"
    "              if (currentChild != null) currentChild,\n"
    "            ],\n"
    "          ),\n"
    "          transitionBuilder: _dayContentTransition,\n"
    "          child: KeyedSubtree(\n"
    "            key: ValueKey<int>(_selectedWeekday),\n"
    "            child: Column(\n"
    "              crossAxisAlignment: CrossAxisAlignment.stretch,\n"
    "              children: [\n"
    "                Row(\n"
    "                  children: [\n"
    "                    Expanded(\n"
    "                      child: Text(\n"
    "                        timetableDayNames[_selectedWeekday]!,\n"
    "                        style: Theme.of(context).textTheme.titleLarge,\n"
    "                      ),\n"
    "                    ),\n"
    "                    Text(\n"
    "                      '${selected.length} ${selected.length == 1 ? 'class' : 'classes'}',\n"
    "                      style: Theme.of(context).textTheme.labelLarge?.copyWith(\n"
    "                        color: Theme.of(context).colorScheme.onSurfaceVariant,\n"
    "                      ),\n"
    "                    ),\n"
    "                  ],\n"
    "                ),\n"
    "                const SizedBox(height: AppSpacing.sm),\n"
    "                if (selected.isEmpty)\n"
    "                  EmptyState(\n"
    "                    icon: Icons.event_available_rounded,\n"
    "                    title:\n"
    "                        'No classes on ${timetableDayNames[_selectedWeekday]}',\n"
    "                    message:\n"
    "                        'This day is clear. Add a class whenever your schedule changes.',\n"
    "                    action: FilledButton.icon(\n"
    "                      onPressed: () => _showEntryForm(\n"
    "                        semesterId: semesterId,\n"
    "                        semesterStart: semester.startDate,\n"
    "                        semesterEnd: semester.endDate,\n"
    "                        subjects: subjects,\n"
    "                        entries: entries,\n"
    "                        initialWeekday: _selectedWeekday,\n"
    "                      ),\n"
    "                      icon: const Icon(Icons.add_rounded),\n"
    "                      label: const Text('Add class'),\n"
    "                    ),\n"
    "                  )\n"
    "                else\n"
    "                  Column(\n"
    "                    children: [\n"
    "                      for (var index = 0; index < selected.length; index++) ...[\n"
    "                        _ClassCard(\n"
    "                          scheduledClass: selected[index],\n"
    "                          isCurrent: next.currentClasses.any(\n"
    "                            (item) =>\n"
    "                                item.entry.id == selected[index].entry.id,\n"
    "                          ),\n"
    "                          onEdit: () => _showEntryForm(\n"
    "                            semesterId: semesterId,\n"
    "                            semesterStart: semester.startDate,\n"
    "                            semesterEnd: semester.endDate,\n"
    "                            subjects: subjects,\n"
    "                            entries: entries,\n"
    "                            initialWeekday: selected[index].entry.weekday,\n"
    "                            entry: selected[index].entry,\n"
    "                          ),\n"
    "                          onDuplicate: () => _duplicateEntry(\n"
    "                            semesterId: semesterId,\n"
    "                            semesterStart: semester.startDate,\n"
    "                            semesterEnd: semester.endDate,\n"
    "                            subjects: subjects,\n"
    "                            entries: entries,\n"
    "                            source: selected[index].entry,\n"
    "                          ),\n"
    "                          onDelete: () =>\n"
    "                              _deleteEntry(selected[index], semester),\n"
    "                        ),\n"
    "                        if (index != selected.length - 1)\n"
    "                          const SizedBox(height: AppSpacing.sm),\n"
    "                      ],\n"
    "                    ],\n"
    "                  ),\n"
    "              ],\n"
    "            ),\n"
    "          ),\n"
    "        ),\n"
    "      ],\n"
    "    );\n"
    "  }\n"
    "\n"
)
s = s[:start] + new_schedule + tail + s[end + len(tail) :]

# --------------------------------------------------------- day selector ------
selector_start = s.index("class _DaySelector extends StatelessWidget {")
selector_end = s.index("class _NextClassCard extends StatelessWidget {")
new_selector = '''class _DaySelector extends StatelessWidget {
  const _DaySelector({required this.selected, required this.onSelected});

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final days = timetableWeekdays;
    final slot = 1 / days.length;
    final index = days.indexOf(selected).clamp(0, days.length - 1);
    // One pill for the whole strip. It glides between equal-width day slots
    // instead of every day painting its own background, so a day change reads
    // as a single movement and no label ever shifts.
    final alignment = days.length == 1 ? 0.0 : -1 + 2 * index / (days.length - 1);
    final pillDuration = reduceMotion ? Duration.zero : AppDurations.dayPillGlide;
    final labelStyle = theme.textTheme.labelLarge ?? const TextStyle();
    return Semantics(
      label: 'Timetable days',
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xxs),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedAlign(
                key: const Key('timetable_day_pill'),
                duration: pillDuration,
                curve: AppCurves.emphasized,
                alignment: Alignment(alignment, 0),
                child: FractionallySizedBox(
                  widthFactor: slot,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxxs,
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                for (final day in days)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xxxs,
                      ),
                      child: InkWell(
                        key: Key('timetable_day_$day'),
                        onTap: () => onSelected(day),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xs,
                          ),
                          child: AnimatedDefaultTextStyle(
                            duration: pillDuration,
                            curve: AppCurves.standard,
                            style: selected == day
                                ? labelStyle.copyWith(
                                    color: colors.onPrimary,
                                    fontWeight: FontWeight.w800,
                                  )
                                : labelStyle.copyWith(
                                    color: colors.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                timetableDayShortNames[day]!,
                                maxLines: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

'''
s = s[:selector_start] + new_selector + s[selector_end:]

# ------------------------------------------------------ reminder indicator ---
old_details = (
    "                    const SizedBox(height: AppSpacing.xxs),\n"
    "                    Text(\n"
    "                      [\n"
    "                        if (item.subject.shortCode.isNotEmpty)\n"
    "                          item.subject.shortCode,\n"
    "                        if (room.isNotEmpty) room,\n"
    "                        if (item.subject.professor.isNotEmpty)\n"
    "                          item.subject.professor,\n"
    "                      ].join('  \u2022  '),\n"
    "                      maxLines: 2,\n"
    "                      overflow: TextOverflow.ellipsis,\n"
    "                      style: Theme.of(context).textTheme.bodySmall?.copyWith(\n"
    "                        color: colors.onSurfaceVariant,\n"
    "                      ),\n"
    "                    ),\n"
)
new_details = (
    "                    const SizedBox(height: AppSpacing.xxs),\n"
    "                    Text(\n"
    "                      [\n"
    "                        if (item.subject.shortCode.isNotEmpty)\n"
    "                          item.subject.shortCode,\n"
    "                        if (room.isNotEmpty) room,\n"
    "                        if (item.subject.professor.isNotEmpty)\n"
    "                          item.subject.professor,\n"
    "                      ].join('  \u2022  '),\n"
    "                      maxLines: 2,\n"
    "                      overflow: TextOverflow.ellipsis,\n"
    "                      style: Theme.of(context).textTheme.bodySmall?.copyWith(\n"
    "                        color: colors.onSurfaceVariant,\n"
    "                      ),\n"
    "                    ),\n"
    "                    if (item.entry.reminderMinutesBefore case final lead?) ...[\n"
    "                      const SizedBox(height: AppSpacing.xxs),\n"
    "                      Row(\n"
    "                        key: Key('timetable_class_reminder_${item.entry.id}'),\n"
    "                        mainAxisSize: MainAxisSize.min,\n"
    "                        children: [\n"
    "                          Icon(\n"
    "                            Icons.notifications_active_rounded,\n"
    "                            size: 14,\n"
    "                            color: colors.primary,\n"
    "                          ),\n"
    "                          const SizedBox(width: AppSpacing.xxxs),\n"
    "                          Flexible(\n"
    "                            child: Text(\n"
    "                              formatClassReminderLead(lead),\n"
    "                              maxLines: 1,\n"
    "                              overflow: TextOverflow.ellipsis,\n"
    "                              style: Theme.of(context).textTheme.labelSmall\n"
    "                                  ?.copyWith(\n"
    "                                    color: colors.primary,\n"
    "                                    fontWeight: FontWeight.w700,\n"
    "                                  ),\n"
    "                            ),\n"
    "                          ),\n"
    "                        ],\n"
    "                      ),\n"
    "                    ],\n"
)
assert s.count(old_details) == 1
s = s.replace(old_details, new_details)

p.write_text(s, encoding='utf-8')
print('timetable_screen.dart', before, '->', len(s))
