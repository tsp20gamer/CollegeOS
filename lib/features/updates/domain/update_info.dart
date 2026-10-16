/// The release worker's direct download endpoint.
///
/// `GET` with `?download=1` answers with a redirect to the APK of the newest
/// published GitHub release, so an installed build fetches the latest
/// published binary even before `version.json` on `main` has been rewritten.
const String directApkDownloadUrl =
    'https://apicollegeos.steja3471.workers.dev/?download=1';

/// Release metadata published by the release workflow in `version.json`.
///
/// The manifest is the *only* thing the updater trusts, so it is read strictly:
/// a release that does not name a version and a download location cannot become
/// an update offer, because offering one would leave the student with an Update
/// button that cannot work.
class UpdateInfo {
  const UpdateInfo({
    required this.latestVersion,
    required this.apkUrl,
    required this.changelog,
    required this.forceUpdate,
  });

  /// Parses the published manifest.
  ///
  /// Throws [UpdateManifestFailure] with the reason the manifest cannot be used.
  factory UpdateInfo.fromJson(Map<String, Object?> json) {
    final version = _text(json['latest_version']);
    if (version == null || parseVersion(version) == null) {
      throw const UpdateManifestFailure(
        'latest_version is missing or unreadable',
      );
    }

    final url = Uri.tryParse(_text(json['apk_url']) ?? '');
    if (url == null || url.scheme != 'https' || url.host.isEmpty) {
      throw const UpdateManifestFailure(
        'apk_url is missing or is not an https URL',
      );
    }

    return UpdateInfo(
      latestVersion: version,
      apkUrl: url,
      changelog: _text(json['changelog']) ?? 'Bug fixes and improvements.',
      forceUpdate: json['force_update'] == true,
    );
  }

  /// The newest published version name, without the tag's `v` prefix.
  final String latestVersion;

  /// Where the release APK is published.
  final Uri apkUrl;

  /// What changed in the release, as the release process wrote it.
  final String changelog;

  /// When true the release is not optional: the offer cannot be dismissed until
  /// the student has been taken to the installer.
  final bool forceUpdate;

  /// True when this release is ahead of [currentVersion].
  ///
  /// Anything either side cannot be read as a version compares as "not newer",
  /// so a malformed manifest can never talk a student into a downgrade.
  bool isNewerThan(String currentVersion) {
    final current = parseVersion(currentVersion);
    final latest = parseVersion(latestVersion);
    if (current == null || latest == null) return false;
    return compareVersions(latest, current) > 0;
  }

  /// The release as the UI names it.
  String get versionLabel => 'v$latestVersion';

  /// Where the APK may be downloaded from, best source first.
  ///
  /// The release worker at [directApkDownloadUrl] redirects straight to the
  /// newest published APK, so it is tried first; the manifest's pinned [apkUrl]
  /// is the version-accurate fallback for when the worker itself cannot be
  /// reached. Equal sources are listed once.
  List<Uri> get downloadSources {
    final direct = Uri.parse(directApkDownloadUrl);
    if (apkUrl == direct) return [direct];
    return [direct, apkUrl];
  }

  @override
  String toString() =>
      'UpdateInfo(latestVersion: $latestVersion, apkUrl: $apkUrl, '
      'forceUpdate: $forceUpdate)';
}

/// A published release that cannot be read as an update offer.
///
/// [reason] names the offending field for a log line; it is not shown to the
/// student, who sees the friendly [UpdateCheckFailure] wrapping it.
class UpdateManifestFailure implements Exception {
  const UpdateManifestFailure(this.reason);

  final String reason;

  @override
  String toString() => 'UpdateManifestFailure: $reason';
}

/// A check that could not be completed, with a message fit for the UI.
///
/// The update check is a convenience, never a requirement: callers treat this
/// as "try again later", and the app keeps working offline exactly as before.
class UpdateCheckFailure implements Exception {
  const UpdateCheckFailure(this.message);

  final String message;

  @override
  String toString() => 'UpdateCheckFailure: $message';
}

/// Splits a version into its numeric segments.
///
/// It accepts what tags, pubspecs and manifests realistically carry: an optional
/// `v` prefix, plus build metadata or a pre-release suffix to ignore
/// (`1.11.0+32`, `v1.11.0-beta.2`). Returns null when a segment is not numeric,
/// because an unreadable version must never be read as an upgrade.
List<int>? parseVersion(String raw) {
  var text = raw.trim();
  if (text.isEmpty) return null;
  if (text.startsWith('v') || text.startsWith('V')) text = text.substring(1);

  final cut = text.indexOf(_metadataSeparator);
  if (cut >= 0) text = text.substring(0, cut);
  if (text.isEmpty) return null;

  final segments = <int>[];
  for (final segment in text.split('.')) {
    final digits = _leadingDigits.firstMatch(segment.trim());
    if (digits == null) return null;
    segments.add(int.parse(digits.group(0)!));
  }
  return segments;
}

/// Orders two parsed versions: greater than zero when [a] is newer than [b].
///
/// Missing segments count as zero, so `1.11` and `1.11.0` are the same release.
int compareVersions(List<int> a, List<int> b) {
  final length = a.length > b.length ? a.length : b.length;
  for (var index = 0; index < length; index++) {
    final left = index < a.length ? a[index] : 0;
    final right = index < b.length ? b[index] : 0;
    if (left != right) return left.compareTo(right);
  }
  return 0;
}

final RegExp _metadataSeparator = RegExp(r'[+\-]');
final RegExp _leadingDigits = RegExp(r'^\d+');

String? _text(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
