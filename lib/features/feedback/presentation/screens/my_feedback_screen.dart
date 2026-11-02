import 'package:college_os/core/theme/dimensions.dart';
import 'package:college_os/core/theme/radius.dart';
import 'package:college_os/core/theme/spacing.dart';
import 'package:college_os/features/feedback/application/feedback_providers.dart';
import 'package:college_os/features/feedback/domain/feedback_models.dart';
import 'package:college_os/features/feedback/presentation/widgets/feedback_status_badge.dart';
import 'package:college_os/shared/widgets/empty_state.dart';
import 'package:college_os/shared/widgets/premium_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Settings → Feedback & ideas → My feedback.
///
/// Reports still on the phone come first, then everything the service holds
/// for this install with its status and the developer's reply.
class MyFeedbackScreen extends ConsumerWidget {
  const MyFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remote = ref.watch(myFeedbackProvider);
    final local = ref.watch(queuedFeedbackProvider).value ?? const [];
    final state = remote.value;
    final items = state?.items ?? const <FeedbackItem>[];

    return Scaffold(
      appBar: AppBar(title: const Text('My feedback')),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () => ref.read(myFeedbackProvider.notifier).refresh(),
          child: remote.isLoading && state == null && local.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : local.isEmpty && items.isEmpty
              ? ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    if (state?.message case final message?) ...[
                      _Notice(message: message),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    EmptyState(
                      icon: Icons.forum_outlined,
                      title: 'No feedback yet',
                      message: 'Reports you send show up here with their status and any reply from the developer.',
                      action: FilledButton(
                        onPressed: () => context.pop(),
                        child: const Text('Send feedback'),
                      ),
                    ),
                  ],
                )
              : ListView(
                  key: const Key('my_feedback_list'),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xl,
                  ),
                  children: [
                    if (state?.message case final message?) ...[
                      _Notice(message: message),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    for (final item in local) ...[
                      _QueuedCard(
                        item: item,
                        onDiscard: () => ref
                            .read(feedbackQueueProvider)
                            .discard(item.clientId),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    for (final item in items) ...[
                      _FeedbackCard(item: item),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

String _when(DateTime time) =>
    DateFormat('d MMM y, h:mm a').format(time.toLocal());

class _Notice extends StatelessWidget {
  const _Notice({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(
          Icons.cloud_off_rounded,
          size: AppIconSize.xs,
          color: colors.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.type, required this.time, required this.badge});

  final FeedbackType type;
  final DateTime time;
  final Widget badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Row(
      children: [
        Icon(
          feedbackTypeIcon(type),
          size: AppIconSize.sm,
          color: colors.primary,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                type.label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                _when(time),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Flexible(child: badge),
      ],
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.item});
  final FeedbackItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return PremiumSurface(
      key: Key('feedback_item_${item.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(
            type: item.type,
            time: item.createdAt,
            badge: FeedbackStatusBadge.remote(item.status),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(item.message, maxLines: 8, overflow: TextOverflow.ellipsis),
          _Sender(
            key: Key('feedback_sender_${item.id}'),
            name: item.displayName,
            anonymous: item.anonymous,
          ),
          if (item.rating != null || item.attachments > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            _Extras(rating: item.rating, screenshots: item.attachments),
          ],
          if (item.adminReply case final reply?) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: .45),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.reply_rounded,
                        size: AppIconSize.xs,
                        color: colors.primary,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Expanded(
                        child: Text(
                          'Reply from the developer',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (item.repliedAt case final at?)
                        Text(
                          DateFormat('d MMM').format(at.toLocal()),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(reply, key: Key('feedback_reply_${item.id}')),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QueuedCard extends StatelessWidget {
  const _QueuedCard({required this.item, required this.onDiscard});
  final QueuedFeedback item;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final failed = item.state == QueuedFeedbackState.failed;
    return PremiumSurface(
      key: Key('queued_feedback_${item.clientId}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(
            type: item.type,
            time: item.createdAt,
            badge: FeedbackStatusBadge.local(item.state),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(item.message, maxLines: 8, overflow: TextOverflow.ellipsis),
          _Sender(
            key: Key('queued_sender_${item.clientId}'),
            name: item.name,
            anonymous: item.anonymous,
          ),
          if (item.rating != null || item.screenshots.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            _Extras(rating: item.rating, screenshots: item.screenshots.length),
          ],
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: Text(
                  failed
                      ? (item.lastError ??
                            'The service did not accept this report.')
                      : 'Saved on this phone. It sends automatically when you are online.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: failed ? colors.error : colors.onSurfaceVariant,
                  ),
                ),
              ),
              if (failed)
                TextButton(onPressed: onDiscard, child: const Text('Dismiss')),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Sent as Asha" or "Anonymous"; nothing for reports sent without a name.
class _Sender extends StatelessWidget {
  const _Sender({super.key, required this.name, required this.anonymous});

  final String? name;
  final bool anonymous;

  @override
  Widget build(BuildContext context) {
    final label = anonymous
        ? 'Anonymous'
        : name == null
        ? null
        : 'Sent as $name';
    if (label == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: [
          Icon(
            anonymous
                ? Icons.visibility_off_outlined
                : Icons.person_outline_rounded,
            size: 16,
            color: muted,
          ),
          const SizedBox(width: AppSpacing.xxs),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _Extras extends StatelessWidget {
  const _Extras({required this.rating, required this.screenshots});
  final int? rating;
  final int screenshots;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    return Row(
      children: [
        if (rating case final stars?) ...[
          for (var i = 1; i <= 5; i++)
            Icon(
              i <= stars ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 16,
              color: i <= stars
                  ? const Color(0xFFF5B301)
                  : Theme.of(context).colorScheme.outline,
            ),
          const SizedBox(width: AppSpacing.sm),
        ],
        if (screenshots > 0) ...[
          Icon(Icons.image_outlined, size: 16, color: muted?.color),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            '$screenshots screenshot${screenshots == 1 ? '' : 's'}',
            style: muted,
          ),
        ],
      ],
    );
  }
}
