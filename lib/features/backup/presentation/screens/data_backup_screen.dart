import 'package:college_os/core/routing/route_names.dart';
import 'package:college_os/core/theme/dimensions.dart';
import 'package:college_os/core/theme/radius.dart';
import 'package:college_os/core/theme/spacing.dart';
import 'package:college_os/features/backup/application/backup_providers.dart';
import 'package:college_os/features/backup/data/backup_archive_codec.dart';
import 'package:college_os/features/backup/domain/backup_models.dart';
import 'package:college_os/features/backup/domain/recovery_backup.dart';
import 'package:college_os/features/settings/application/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class DataBackupScreen extends ConsumerStatefulWidget {
  const DataBackupScreen({
    this.restoreOnly = false,
    this.incomingBackupPath,
    super.key,
  });

  final bool restoreOnly;
  final String? incomingBackupPath;

  @override
  ConsumerState<DataBackupScreen> createState() => _DataBackupScreenState();
}

class _DataBackupScreenState extends ConsumerState<DataBackupScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.incomingBackupPath != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _inspectIncomingBackup(widget.incomingBackupPath!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final operation = ref.watch(backupControllerProvider);
    final exportOperation = ref.watch(settingsDataControllerProvider);
    final busy = operation.isLoading || exportOperation.isLoading;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.restoreOnly ? 'Restore Backup' : 'Data & Backup'),
      ),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppLayout.scaffoldBottomPadding(context),
              ),
              children: [
                _HeroCard(restoreOnly: widget.restoreOnly),
                const SizedBox(height: AppSpacing.xl),
                if (!widget.restoreOnly) ...[
                  Text('Export', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.sm),
                  _ActionCard(
                    key: const Key('export_data'),
                    icon: Icons.save_alt_rounded,
                    title: 'Export Data',
                    subtitle:
                        'Choose a complete backup or an attendance report.',
                    enabled: !busy,
                    onTap: () => _chooseExport(context, ref),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _ActionCard(
                    key: const Key('share_backup'),
                    icon: Icons.share_outlined,
                    title: 'Share Backup',
                    subtitle:
                        'Open Android’s share sheet to transfer the file.',
                    enabled: !busy,
                    onTap: () => _share(context, ref),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _AutomaticRecoverySection(
                    busy: busy,
                    onRestore: (backup) => _openRecovery(context, ref, backup),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
                Text('Import', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                _ActionCard(
                  key: const Key('import_backup'),
                  icon: Icons.settings_backup_restore_rounded,
                  title: 'Import Backup',
                  subtitle:
                      'Validate a .collegeos file and review it before restoring.',
                  enabled: !busy,
                  onTap: () => _import(context, ref),
                ),
                const SizedBox(height: AppSpacing.lg),
                const _PrivacyNotice(),
              ],
            ),
            if (busy)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(key: Key('backup_progress')),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _inspectIncomingBackup(String path) async {
    try {
      final backup = await ref
          .read(backupControllerProvider.notifier)
          .inspectIncomingFile(path);
      if (!mounted) return;
      await _showPreview(context, ref, backup);
    } catch (error) {
      if (mounted) _error(context, error);
    }
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    try {
      final saved = await ref
          .read(backupControllerProvider.notifier)
          .exportToFile();
      if (context.mounted && saved) {
        _message(context, 'Backup saved successfully.');
      }
    } catch (error) {
      if (context.mounted) _error(context, error);
    }
  }

  Future<void> _chooseExport(BuildContext context, WidgetRef ref) async {
    final choice = await showModalBottomSheet<_ExportChoice>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) => const _ExportChoiceSheet(),
    );
    if (!context.mounted || choice == null) return;
    switch (choice) {
      case _ExportChoice.fullBackup:
        await _export(context, ref);
      case _ExportChoice.attendanceCsv:
        await _exportAttendance(context, ref);
    }
  }

  Future<void> _exportAttendance(BuildContext context, WidgetRef ref) async {
    try {
      final saved = await ref
          .read(settingsDataControllerProvider.notifier)
          .exportAttendanceCsv();
      if (context.mounted && saved) {
        _message(context, 'Attendance CSV saved successfully.');
      }
    } catch (_) {
      if (context.mounted) {
        _message(context, 'Could not export attendance CSV.');
      }
    }
  }

  Future<void> _share(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(backupControllerProvider.notifier).shareBackup();
    } catch (error) {
      if (context.mounted) _error(context, error);
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    try {
      final backup = await ref
          .read(backupControllerProvider.notifier)
          .pickAndInspect();
      if (backup == null || !context.mounted) return;
      await _showPreview(context, ref, backup);
    } catch (error) {
      if (context.mounted) _error(context, error);
    }
  }

  Future<void> _openRecovery(
    BuildContext context,
    WidgetRef ref,
    RecoveryBackup recovery,
  ) async {
    try {
      final backup = await ref
          .read(backupControllerProvider.notifier)
          .prepareRecovery(recovery.id);
      if (!context.mounted) return;
      await _showPreview(context, ref, backup, recovery: true);
    } catch (error) {
      if (context.mounted) _error(context, error);
    }
  }

  Future<void> _showPreview(
    BuildContext context,
    WidgetRef ref,
    PreparedBackup backup, {
    bool recovery = false,
  }) async {
    final restore = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => _RestorePreview(backup: backup),
    );
    if (restore != true || !context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Theme.of(dialogContext).colorScheme.error,
        ),
        title: const Text('Replace current data?'),
        content: const Text(
          'Existing CollegeOS data on this device will be replaced.\n\n'
          'CollegeOS will first create a private emergency backup. If restore fails, your current data stays unchanged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirm_restore_backup'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Restore Backup'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      final controller = ref.read(backupControllerProvider.notifier);
      if (recovery) {
        await controller.restoreRecovery(backup);
      } else {
        await controller.restore(backup);
      }
    } catch (error) {
      if (context.mounted) _error(context, error);
      return;
    }
    if (!context.mounted) return;
    _message(context, 'Backup restored successfully.');
    context.go(RoutePaths.home);
  }
}

enum _ExportChoice { fullBackup, attendanceCsv }

class _ExportChoiceSheet extends StatelessWidget {
  const _ExportChoiceSheet();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.xs,
      AppSpacing.lg,
      AppSpacing.xl,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Choose export', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'A full backup already includes attendance and every other CollegeOS record.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Column(
            children: [
              ListTile(
                key: const Key('export_full_backup'),
                leading: const Icon(Icons.inventory_2_outlined),
                title: const Text('Full CollegeOS Backup'),
                subtitle: const Text(
                  'Portable .collegeos file for restoring everything.',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.pop(context, _ExportChoice.fullBackup),
              ),
              const Divider(height: 1),
              ListTile(
                key: const Key('export_attendance_report'),
                leading: const Icon(Icons.table_view_outlined),
                title: const Text('Attendance CSV'),
                subtitle: const Text(
                  'Readable class attendance for spreadsheet apps.',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () =>
                    Navigator.pop(context, _ExportChoice.attendanceCsv),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _AutomaticRecoverySection extends ConsumerWidget {
  const _AutomaticRecoverySection({
    required this.busy,
    required this.onRestore,
  });

  final bool busy;
  final ValueChanged<RecoveryBackup> onRestore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(collegeSettingsProvider);
    final backups = ref.watch(recoveryBackupsProvider);
    final toggleOperation = ref.watch(automaticLocalBackupControllerProvider);
    final enabled = settings.value?.automaticLocalBackup ?? true;
    final toggleBusy = toggleOperation.isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Automatic local backup',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Column(
            children: [
              SwitchListTile.adaptive(
                key: const Key('automatic_local_backup_switch'),
                value: enabled,
                onChanged: busy || toggleBusy
                    ? null
                    : (value) => _setEnabled(context, ref, value),
                secondary: const Icon(Icons.history_rounded),
                title: const Text('Automatic Local Backup'),
                subtitle: const Text(
                  'Save recovery snapshots after meaningful changes and when the app pauses.',
                ),
              ),
              const Divider(height: 1),
              const ListTile(
                leading: Icon(Icons.inventory_2_outlined),
                title: Text('Keep Backups'),
                trailing: Text('$automaticRecoveryBackupLimit'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.phone_android_rounded,
                color: Theme.of(context).colorScheme.onTertiaryContainer,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Local backups remain on this phone. Export a backup to protect your data when changing devices.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        backups.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _RecoveryError(
            onRetry: () => ref.invalidate(recoveryBackupsProvider),
          ),
          data: (items) => _RecoveryBackupList(
            backups: items,
            enabled: !busy,
            onRestore: onRestore,
          ),
        ),
      ],
    );
  }

  Future<void> _setEnabled(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    final saved = await ref
        .read(automaticLocalBackupControllerProvider.notifier)
        .setEnabled(enabled);
    if (!saved || !context.mounted) {
      if (context.mounted) {
        _message(context, 'Could not update automatic local backup.');
      }
      return;
    }
    await ref.read(automaticBackupCoordinatorProvider).updateEnabled(enabled);
    ref.invalidate(recoveryBackupsProvider);
  }
}

class _RecoveryBackupList extends StatelessWidget {
  const _RecoveryBackupList({
    required this.backups,
    required this.enabled,
    required this.onRestore,
  });

  final List<RecoveryBackup> backups;
  final bool enabled;
  final ValueChanged<RecoveryBackup> onRestore;

  @override
  Widget build(BuildContext context) {
    if (backups.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Icon(
                Icons.backup_outlined,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.md),
              const Expanded(
                child: Text(
                  'No local recovery backups yet. One will be created after your next meaningful change.',
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Latest Backup', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        _RecoveryBackupCard(
          key: const Key('latest_recovery_backup'),
          backup: backups.first,
          enabled: enabled,
          onTap: () => onRestore(backups.first),
        ),
        if (backups.length > 1) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Previous Backups',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final backup in backups.skip(1)) ...[
            _RecoveryBackupCard(
              backup: backup,
              enabled: enabled,
              onTap: () => onRestore(backup),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
        ],
      ],
    );
  }
}

class _RecoveryBackupCard extends StatelessWidget {
  const _RecoveryBackupCard({
    required this.backup,
    required this.enabled,
    required this.onTap,
    super.key,
  });

  final RecoveryBackup backup;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final created = DateFormat.yMMMd().add_jm().format(
      backup.manifest.createdAt.toLocal(),
    );
    final counts = backup.manifest.recordCounts;
    return Card(
      child: ListTile(
        onTap: enabled ? onTap : null,
        leading: const CircleAvatar(child: Icon(Icons.restore_rounded)),
        title: Text(created),
        subtitle: Text(
          '${backup.manifest.collegeName.isEmpty ? 'CollegeOS' : backup.manifest.collegeName} • '
          '${counts.subjects} subjects • ${counts.attendance} attendance records',
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _RecoveryError extends StatelessWidget {
  const _RecoveryError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const Icon(Icons.error_outline_rounded),
      title: const Text('Local backups are unavailable'),
      subtitle: const Text('Your current CollegeOS data is unaffected.'),
      trailing: TextButton(onPressed: onRetry, child: const Text('Retry')),
    ),
  );
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.restoreOnly});
  final bool restoreOnly;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.shield_outlined,
            size: 36,
            color: colors.onPrimaryContainer,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            restoreOnly
                ? 'Bring CollegeOS with you'
                : 'Your data belongs to you',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: colors.onPrimaryContainer,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            restoreOnly
                ? 'Select the backup from your old phone to restore college settings, semesters, attendance, tasks, exams, and marks.'
                : 'Create a complete offline backup whenever you want. No account, cloud, or internet connection is required.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: colors.onPrimaryContainer),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, color: colors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacyNotice extends StatelessWidget {
  const _PrivacyNotice();

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.surfaceContainerLow,
    child: const Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline_rounded),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Backups are private but not encrypted. Anyone with the file can read its contents, so transfer and store it securely.',
            ),
          ),
        ],
      ),
    ),
  );
}

class _RestorePreview extends StatelessWidget {
  const _RestorePreview({required this.backup});
  final PreparedBackup backup;

  @override
  Widget build(BuildContext context) {
    final manifest = backup.manifest;
    final counts = manifest.recordCounts;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.55,
      maxChildSize: 0.94,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        children: [
          Text(
            'Restore preview',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            backup.sourceName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _PreviewLine(
            label: 'College name',
            value: manifest.collegeName.isEmpty
                ? 'Not set'
                : manifest.collegeName,
          ),
          _PreviewLine(
            label: 'Semester',
            value: manifest.activeSemester ?? 'No active semester',
          ),
          _PreviewLine(
            label: 'Backup date',
            value: DateFormat.yMMMd().add_jm().format(
              manifest.createdAt.toLocal(),
            ),
          ),
          _PreviewLine(label: 'Subjects', value: '${counts.subjects}'),
          _PreviewLine(
            label: 'Daily attendance',
            value:
                '${counts.dailyAttendance > 0 ? counts.dailyAttendance : counts.attendance}',
          ),
          _PreviewLine(label: 'Tasks', value: '${counts.tasks}'),
          _PreviewLine(label: 'Exams', value: '${counts.exams}'),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(
              'Existing CollegeOS data on this device will be replaced.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            key: const Key('restore_backup_from_preview'),
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.settings_backup_restore_rounded),
            label: const Text('Restore Backup'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class _PreviewLine extends StatelessWidget {
  const _PreviewLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

void _message(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

void _error(BuildContext context, Object error) {
  final message = error is BackupException
      ? error.message
      : 'Backup operation failed. Your existing data was not changed.';
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Theme.of(context).colorScheme.error,
    ),
  );
}
