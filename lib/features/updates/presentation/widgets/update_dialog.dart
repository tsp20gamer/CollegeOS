import 'dart:io';

import 'package:college_os/core/theme/dimensions.dart';
import 'package:college_os/core/theme/radius.dart';
import 'package:college_os/core/theme/spacing.dart';
import 'package:college_os/features/updates/domain/update_info.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Android's package-archive type, as the system installer expects it.
const String _apkMimeType = 'application/vnd.android.package-archive';

/// How long the download may stall before it is treated as failed.
const Duration _receiveTimeout = Duration(minutes: 2);
const Duration _connectTimeout = Duration(seconds: 20);

/// One megabyte, for the progress line.
const int _megabyte = 1024 * 1024;

/// Where the offer is in its short life cycle.
enum _UpdateStage {
  /// The release is described and nothing has been downloaded yet.
  offer,

  /// The APK is downloading, with progress on screen.
  downloading,

  /// The APK is complete and Android's installer is being opened.
  install,

  /// The download or the hand-off failed, and the offer can be retried.
  failed,
}

/// Offers a published release and hands its APK to Android's installer.
///
/// Downloading is the only step that touches the network, and it happens only
/// after the student taps Update. Nothing about the device or the account is
/// sent, and a failed download leaves the installed app exactly as it was.
class UpdateDialog extends StatefulWidget {
  const UpdateDialog({required this.info, super.key});

  final UpdateInfo info;

  /// Shows the offer above whatever the student is looking at.
  ///
  /// A forced release cannot be dismissed by tapping outside it, so the student
  /// has to make an explicit choice about it.
  static Future<void> show(BuildContext context, {required UpdateInfo info}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: !info.forceUpdate,
      builder: (context) => UpdateDialog(info: info),
    );
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  final CancelToken _cancelToken = CancelToken();

  _UpdateStage _stage = _UpdateStage.offer;
  double _progress = 0;
  String _detail = '';
  String? _failure;

  /// True while the dialog is working and must not be dismissed underneath it.
  bool get _busy =>
      _stage == _UpdateStage.downloading || _stage == _UpdateStage.install;

  @override
  void dispose() {
    // Leaving the dialog must not leave a download running in the background.
    if (!_cancelToken.isCancelled) _cancelToken.cancel();
    super.dispose();
  }

  Future<void> _startDownload() async {
    setState(() {
      _stage = _UpdateStage.downloading;
      _failure = null;
      _progress = 0;
      _detail = 'Starting download…';
    });

    final dio = Dio(
      BaseOptions(
        connectTimeout: _connectTimeout,
        receiveTimeout: _receiveTimeout,
      ),
    );
    File? apk;
    try {
      final directory = await getTemporaryDirectory();
      apk = File(
        p.join(directory.path, 'CollegeOS-${widget.info.latestVersion}.apk'),
      );

      // Best source first: the release worker redirects straight to the newest
      // published APK, while the manifest's pinned URL is the version-accurate
      // fallback for when the worker itself cannot be reached.
      final sources = widget.info.downloadSources;
      for (var index = 0; index < sources.length; index++) {
        try {
          await dio.download(
            sources[index].toString(),
            apk.path,
            cancelToken: _cancelToken,
            onReceiveProgress: _onProgress,
          );
          break;
        } on DioException catch (error) {
          // A cancelled download is the student's choice; nothing retries.
          // The last source has nowhere left to fall back to.
          if (error.type == DioExceptionType.cancel ||
              index == sources.length - 1) {
            rethrow;
          }
          // A partial file from one source must never become the next attempt.
          await _discard(apk);
          if (!mounted) return;
          setState(() {
            _progress = 0;
            _detail = 'Trying the pinned release link…';
          });
        }
      }

      if (!mounted) return;
      setState(() {
        _stage = _UpdateStage.install;
        _detail = 'Opening the installer…';
      });

      final result = await OpenFilex.open(apk.path, type: _apkMimeType);
      if (!mounted) return;

      if (result.type == ResultType.done) {
        // Android's installer is in front now; the offer has done its job.
        Navigator.of(context).pop();
        return;
      }

      await _discard(apk);
      if (!mounted) return;
      setState(() {
        _stage = _UpdateStage.failed;
        _failure =
            'Android did not open the installer. Allow CollegeOS to install '
            'unknown apps in Android settings, then try again.';
      });
    } on DioException catch (error) {
      await _discard(apk);
      if (!mounted) return;
      setState(() {
        _stage = _UpdateStage.failed;
        _failure = _describe(error);
      });
    } catch (error) {
      await _discard(apk);
      if (!mounted) return;
      setState(() {
        _stage = _UpdateStage.failed;
        _failure =
            'The update could not be installed on this device. Your CollegeOS '
            'data is untouched.';
      });
    }
  }

  void _onProgress(int received, int total) {
    if (!mounted) return;
    setState(() {
      if (total > 0) {
        _progress = received / total;
        _detail = '${_size(received)} of ${_size(total)}';
      } else {
        _detail = '${_size(received)} downloaded';
      }
    });
  }

  void _cancel() {
    if (!_cancelToken.isCancelled) _cancelToken.cancel();
    Navigator.of(context).pop();
  }

  Future<void> _discard(File? apk) async {
    if (apk == null) return;
    try {
      if (await apk.exists()) await apk.delete();
    } catch (_) {
      // A leftover temporary file is not worth failing the dialog over.
    }
  }

  String _describe(DioException error) {
    if (error.type == DioExceptionType.cancel) {
      return 'The download was cancelled.';
    }
    if (error.response?.statusCode == 404) {
      return 'That release has no APK attached to it yet. Try again after the '
          'release finishes publishing.';
    }
    return 'The download failed, so nothing was changed. Check your connection '
        'and try again.';
  }

  String _size(int bytes) => '${(bytes / _megabyte).toStringAsFixed(1)} MB';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final canDismiss = !widget.info.forceUpdate && !_busy;

    return PopScope(
      canPop: canDismiss,
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        title: Row(
          children: [
            Icon(Icons.system_update_alt_rounded, color: colors.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text('CollegeOS ${widget.info.versionLabel}')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: switch (_stage) {
            _UpdateStage.offer ||
            _UpdateStage.failed => _releaseNotes(theme, colors),
            _UpdateStage.downloading ||
            _UpdateStage.install => _progressPanel(theme, colors),
          },
        ),
        actions: _actions(context),
      ),
    );
  }

  List<Widget> _releaseNotes(ThemeData theme, ColorScheme colors) => [
    Text(
      'What\'s new',
      style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
    ),
    const SizedBox(height: AppSpacing.xs),
    Text(widget.info.changelog, style: theme.textTheme.bodyMedium),
    const SizedBox(height: AppSpacing.sm),
    Text(
      'Android will ask you to allow installs from CollegeOS the first time.',
      style: theme.textTheme.bodySmall?.copyWith(
        color: colors.onSurfaceVariant,
      ),
    ),
    if (_failure != null) ...[
      const SizedBox(height: AppSpacing.sm),
      Semantics(
        liveRegion: true,
        child: Text(
          _failure!,
          key: const Key('update_dialog_failure'),
          style: theme.textTheme.bodySmall?.copyWith(color: colors.error),
        ),
      ),
    ],
  ];

  List<Widget> _progressPanel(ThemeData theme, ColorScheme colors) => [
    Semantics(
      liveRegion: true,
      label: 'Downloading update',
      value: _progress > 0 ? '${(_progress * 100).round()}%' : _detail,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Downloading the update…', style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xs),
              child: LinearProgressIndicator(
                key: const Key('update_dialog_progress'),
                value: _progress > 0 ? _progress : null,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    _detail,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                Text(
                  '${(_progress * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  ];

  List<Widget> _actions(BuildContext context) {
    final info = widget.info;
    if (_busy) {
      return [
        if (!info.forceUpdate)
          TextButton(
            key: const Key('update_dialog_cancel'),
            onPressed: _cancel,
            child: const Text('Cancel'),
          ),
      ];
    }
    return [
      if (!info.forceUpdate)
        TextButton(
          key: const Key('update_dialog_later'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Later'),
        ),
      FilledButton.icon(
        key: const Key('update_dialog_install'),
        onPressed: _startDownload,
        icon: const Icon(Icons.download_rounded, size: AppIconSize.sm),
        label: Text(_failure == null ? 'Update now' : 'Retry'),
      ),
    ];
  }
}
