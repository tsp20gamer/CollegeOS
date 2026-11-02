import 'package:college_os/core/theme/color_tokens.dart';
import 'package:college_os/features/feedback/domain/feedback_models.dart';
import 'package:college_os/shared/widgets/status_badge.dart';
import 'package:flutter/material.dart';

/// The chip on a report that says where it stands.
class FeedbackStatusBadge extends StatelessWidget {
  const FeedbackStatusBadge.remote(FeedbackStatus this.status, {super.key})
    : local = null;

  const FeedbackStatusBadge.local(QueuedFeedbackState this.local, {super.key})
    : status = null;

  final FeedbackStatus? status;
  final QueuedFeedbackState? local;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final semantic =
        Theme.of(context).extension<AppSemanticColors>() ??
        (Theme.of(context).brightness == Brightness.dark
            ? AppSemanticColors.dark
            : AppSemanticColors.light);
    final (label, icon, color) = switch ((status, local)) {
      (_, QueuedFeedbackState.pending) => (
        'Waiting to send',
        Icons.schedule_send_rounded,
        semantic.warning,
      ),
      (_, QueuedFeedbackState.failed) => (
        'Not sent',
        Icons.error_outline_rounded,
        colors.error,
      ),
      (FeedbackStatus.received, _) => (
        FeedbackStatus.received.label,
        Icons.mark_email_unread_outlined,
        colors.onSurfaceVariant,
      ),
      (FeedbackStatus.seen, _) => (
        FeedbackStatus.seen.label,
        Icons.visibility_outlined,
        semantic.info,
      ),
      (FeedbackStatus.planned, _) => (
        FeedbackStatus.planned.label,
        Icons.event_note_outlined,
        colors.tertiary,
      ),
      (FeedbackStatus.inProgress, _) => (
        FeedbackStatus.inProgress.label,
        Icons.construction_rounded,
        semantic.warning,
      ),
      (FeedbackStatus.done, _) => (
        FeedbackStatus.done.label,
        Icons.check_circle_outline_rounded,
        semantic.success,
      ),
      (FeedbackStatus.wontFix, _) => (
        FeedbackStatus.wontFix.label,
        Icons.do_not_disturb_on_outlined,
        colors.outline,
      ),
      _ => ('Received', Icons.mark_email_unread_outlined, colors.outline),
    };
    return StatusBadge(label: label, icon: icon, foreground: color);
  }
}

IconData feedbackTypeIcon(FeedbackType type) => switch (type) {
  FeedbackType.bug => Icons.bug_report_outlined,
  FeedbackType.idea => Icons.lightbulb_outline_rounded,
  FeedbackType.other => Icons.chat_bubble_outline_rounded,
};
