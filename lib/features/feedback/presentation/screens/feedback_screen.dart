import 'dart:typed_data';

import 'package:college_os/core/routing/route_names.dart';
import 'package:college_os/core/theme/dimensions.dart';
import 'package:college_os/core/theme/radius.dart';
import 'package:college_os/core/theme/spacing.dart';
import 'package:college_os/features/feedback/application/feedback_providers.dart';
import 'package:college_os/features/feedback/application/feedback_queue.dart';
import 'package:college_os/features/feedback/data/feedback_api_client.dart';
import 'package:college_os/features/feedback/data/screenshot_compressor.dart';
import 'package:college_os/features/feedback/domain/feedback_models.dart';
import 'package:college_os/features/feedback/presentation/widgets/feedback_status_badge.dart';
import 'package:college_os/shared/widgets/premium_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

/// Picks up to [max] images. Overridden in tests.
typedef FeedbackImagePicker = Future<List<XFile>> Function(int max);

final feedbackImagePickerProvider = Provider<FeedbackImagePicker>((ref) {
  final picker = ImagePicker();
  // The picker scales and re-encodes natively, so most photos arrive small;
  // the system photo picker needs no storage permission.
  return (max) async {
    if (max <= 0) return const [];
    if (max == 1) {
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: feedbackScreenshotMaxSide.toDouble(),
        maxHeight: feedbackScreenshotMaxSide.toDouble(),
        imageQuality: 80,
      );
      return image == null ? const [] : [image];
    }
    final images = await picker.pickMultiImage(
      maxWidth: feedbackScreenshotMaxSide.toDouble(),
      maxHeight: feedbackScreenshotMaxSide.toDouble(),
      imageQuality: 80,
      limit: max,
    );
    return images.take(max).toList();
  };
});

/// Settings → Feedback & ideas.
class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _message = TextEditingController();
  final _contact = TextEditingController();
  final _name = TextEditingController();
  FeedbackType _type = FeedbackType.bug;
  int? _rating;
  bool _includeDevice = true;
  bool _anonymous = false;

  /// The name remembered from the last report, restored when the student
  /// switches anonymous off again.
  String? _rememberedName;
  bool _attaching = false;
  final List<FeedbackUpload> _screenshots = [];

  @override
  void initState() {
    super.initState();
    _message.addListener(_changed);
    // Anything left from an earlier offline session goes out now.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(feedbackQueueProvider).flush();
    });
    _prefillName();
  }

  Future<void> _prefillName() async {
    try {
      final name = await ref.read(feedbackLocalStoreProvider).readLastName();
      if (!mounted || name == null) return;
      _rememberedName = name;
      if (!_anonymous && _name.text.isEmpty) {
        setState(() => _name.text = name);
      }
    } catch (_) {
      // A remembered name is a convenience; the form works without it.
    }
  }

  void _setAnonymous(bool value) {
    setState(() {
      _anonymous = value;
      if (value) {
        if (cleanFeedbackName(_name.text) case final name?) {
          _rememberedName = name;
        }
        _name.clear();
        _contact.clear();
      } else if (_name.text.isEmpty && _rememberedName != null) {
        _name.text = _rememberedName!;
      }
    });
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    _message.dispose();
    _contact.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _addScreenshots() async {
    final remaining = feedbackMaxScreenshots - _screenshots.length;
    if (remaining <= 0) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _attaching = true);
    try {
      final picked = await ref.read(feedbackImagePickerProvider)(remaining);
      for (final file in picked.take(remaining)) {
        final Uint8List bytes = await file.readAsBytes();
        final upload = await compressScreenshot(bytes, name: file.name);
        if (!mounted) return;
        setState(() => _screenshots.add(upload));
      }
    } on ScreenshotUnsupported catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not attach that picture.')),
      );
    } finally {
      if (mounted) setState(() => _attaching = false);
    }
  }

  Future<void> _send(FeedbackDeviceInfo device) async {
    FocusScope.of(context).unfocus();
    final outcome = await ref
        .read(feedbackSubmitControllerProvider.notifier)
        .submit(
          FeedbackDraft(
            type: _type,
            message: _message.text,
            rating: _rating,
            contact: _anonymous ? null : _contact.text,
            name: _anonymous ? null : _name.text,
            anonymous: _anonymous,
            device: device,
            includeDeviceInfo: _includeDevice,
            screenshots: List.of(_screenshots),
          ),
        );
    if (!mounted) return;
    if (outcome != FeedbackSendOutcome.rejected) {
      if (!_anonymous) _rememberedName = cleanFeedbackName(_name.text);
      _clear();
    }
  }

  void _clear() {
    _message.clear();
    _contact.clear();
    setState(() {
      _rating = null;
      _screenshots.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(feedbackSubmitControllerProvider);
    final device = ref.watch(feedbackDeviceInfoProvider);
    final sending = form.phase == FeedbackFormPhase.sending;
    final done =
        form.phase == FeedbackFormPhase.sent ||
        form.phase == FeedbackFormPhase.queued;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback & ideas'),
        actions: [
          TextButton.icon(
            key: const Key('my_feedback_button'),
            onPressed: () => context.push(RoutePaths.myFeedback),
            icon: const Icon(Icons.forum_outlined),
            label: const Text('My feedback'),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: SafeArea(
        top: false,
        child: done
            ? _SentView(
                queued: form.phase == FeedbackFormPhase.queued,
                onAnother: () =>
                    ref.read(feedbackSubmitControllerProvider.notifier).reset(),
              )
            : _buildForm(context, form, device, sending),
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    FeedbackFormState form,
    AsyncValue<FeedbackDeviceInfo> device,
    bool sending,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final info = device.value;
    final canSend =
        !sending &&
        !_attaching &&
        info != null &&
        _message.text.trim().isNotEmpty;

    return ListView(
      key: const Key('feedback_form'),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        Row(
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: AppIconSize.xs,
              color: colors.primary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                'Goes privately to the developer. No account needed, and nothing else from your app is sent.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        const _Label('What is it about?'),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          children: [
            for (final type in FeedbackType.values)
              ChoiceChip(
                key: Key('feedback_type_${type.wire}'),
                avatar: Icon(feedbackTypeIcon(type), size: AppIconSize.xs),
                label: Text(type.label),
                selected: _type == type,
                showCheckmark: false,
                onSelected: sending
                    ? null
                    : (_) => setState(() => _type = type),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          key: const Key('feedback_message'),
          controller: _message,
          enabled: !sending,
          minLines: 5,
          maxLines: 10,
          maxLength: feedbackMessageMaxLength,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: switch (_type) {
              FeedbackType.bug => 'What happened? What did you expect instead?',
              FeedbackType.idea => 'What would make CollegeOS better for you?',
              FeedbackType.other => 'Tell the developer anything.',
            },
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const _Label('How do you like CollegeOS? (optional)'),
        Row(
          children: [
            for (var star = 1; star <= 5; star++)
              IconButton(
                key: Key('feedback_star_$star'),
                tooltip: '$star star${star == 1 ? '' : 's'}',
                onPressed: sending
                    ? null
                    : () => setState(
                        () => _rating = _rating == star ? null : star,
                      ),
                icon: Icon(
                  (_rating ?? 0) >= star
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: (_rating ?? 0) >= star
                      ? const Color(0xFFF5B301)
                      : colors.onSurfaceVariant,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            const Expanded(child: _Label('Screenshots (optional)')),
            Text(
              '${_screenshots.length}/$feedbackMaxScreenshots',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          height: 112,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final (index, shot) in _screenshots.indexed)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: _Thumbnail(
                    bytes: shot.bytes,
                    onRemove: sending
                        ? null
                        : () => setState(() => _screenshots.removeAt(index)),
                  ),
                ),
              if (_screenshots.length < feedbackMaxScreenshots)
                _AddTile(
                  busy: _attaching,
                  onTap: sending || _attaching ? null : _addScreenshots,
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          key: const Key('feedback_name'),
          controller: _name,
          enabled: !sending && !_anonymous,
          maxLength: feedbackNameMaxLength,
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.name],
          decoration: const InputDecoration(
            labelText: 'Name (optional)',
            counterText: '',
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          key: const Key('feedback_contact'),
          controller: _contact,
          enabled: !sending && !_anonymous,
          maxLength: feedbackContactMaxLength,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email or phone (optional)',
            helperText: 'Only if you want a direct answer. Replies also show in My feedback.',
            helperMaxLines: 2,
            counterText: '',
          ),
        ),
        SwitchListTile(
          key: const Key('feedback_anonymous'),
          contentPadding: EdgeInsets.zero,
          secondary: Icon(
            Icons.visibility_off_outlined,
            color: _anonymous ? colors.primary : colors.onSurfaceVariant,
          ),
          title: const Text('Send anonymously'),
          subtitle: const Text(
            'Device info is still included unless you turn it off below.',
          ),
          value: _anonymous,
          onChanged: sending ? null : _setAnonymous,
        ),
        if (_anonymous)
          Semantics(
            liveRegion: true,
            child: Row(
              key: const Key('feedback_anonymous_note'),
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: AppIconSize.xs,
                  color: colors.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    "Your name and contact won't be sent.",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        _IncludedBox(
          device: info,
          includeDevice: _includeDevice,
          onChanged: sending
              ? null
              : (value) => setState(() => _includeDevice = value),
        ),
        if (form.error case final error?) ...[
          const SizedBox(height: AppSpacing.md),
          Semantics(
            liveRegion: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: colors.error,
                  size: AppIconSize.sm,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    error,
                    key: const Key('feedback_error'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          height: AppLayout.minimumTouchTarget + 4,
          child: FilledButton.icon(
            key: const Key('feedback_send'),
            onPressed: canSend ? () => _send(info) : null,
            icon: sending
                ? SizedBox.square(
                    dimension: AppIconSize.sm,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: colors.onPrimary,
                    ),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(sending ? 'Sending…' : 'Send'),
          ),
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.labelLarge
        ?.copyWith(fontWeight: FontWeight.w700),
  );
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.bytes, this.onRemove});

  final List<int> bytes;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Image.memory(
          // The compressor hands over a Uint8List; reusing it keeps the
          // decoded image cached across rebuilds.
          bytes is Uint8List ? bytes as Uint8List : Uint8List.fromList(bytes),
          width: 76,
          height: 112,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          semanticLabel: 'Attached screenshot',
        ),
      ),
      Positioned(
        top: 2,
        right: 2,
        child: Material(
          color: Colors.black54,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onRemove,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close_rounded, size: 16, color: Colors.white),
            ),
          ),
        ),
      ),
    ],
  );
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.busy, this.onTap});

  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'Add screenshot',
      child: InkWell(
        key: const Key('feedback_add_screenshot'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Ink(
          width: 76,
          height: 112,
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Center(
            child: busy
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        color: colors.primary,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Add',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: colors.primary),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _IncludedBox extends StatelessWidget {
  const _IncludedBox({
    required this.device,
    required this.includeDevice,
    required this.onChanged,
  });

  final FeedbackDeviceInfo? device;
  final bool includeDevice;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: colors.onSurfaceVariant,
    );
    Widget row(String label, String? value, {bool optional = false}) {
      final excluded = optional && !includeDevice;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(width: 92, child: Text(label, style: muted)),
            Expanded(
              child: Text(
                excluded ? 'Not included' : (value ?? 'Unknown'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: excluded ? colors.outline : null,
                  decoration: excluded ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return PremiumSurface(
      key: const Key('feedback_included_box'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: AppIconSize.xs,
                color: colors.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Included with your report',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          row('App version', device?.appVersion),
          row('Device', device?.deviceModel, optional: true),
          row('Android', device?.androidVersion, optional: true),
          SwitchListTile(
            key: const Key('feedback_include_device'),
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('Include device details'),
            subtitle: const Text('Helps the developer reproduce bugs'),
            value: includeDevice,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SentView extends StatelessWidget {
  const _SentView({required this.queued, required this.onAnother});

  final bool queued;
  final VoidCallback onAnother;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          key: Key(queued ? 'feedback_queued' : 'feedback_sent'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              queued ? Icons.schedule_send_rounded : Icons.check_circle_rounded,
              size: 64,
              color: queued ? colors.tertiary : colors.primary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              queued
                  ? 'Saved — it will send when you are online'
                  : 'Thanks! Sent privately',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              queued
                  ? 'Your report is kept on this phone and goes out automatically the next time CollegeOS has a connection.'
                  : 'You can follow its status and any reply from the developer in My feedback.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () => context.push(RoutePaths.myFeedback),
              child: const Text('View my feedback'),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextButton(onPressed: onAnother, child: const Text('Send another')),
          ],
        ),
      ),
    );
  }
}
