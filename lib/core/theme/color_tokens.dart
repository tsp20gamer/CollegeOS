import 'package:flutter/material.dart';

abstract final class AppColors {
  // Electric Cobalt — the single primary accent for CollegeOS.
  // Calm, professional, high-contrast. Used for interactive elements,
  // selected states, progress indicators, and key iconography.
  static const cobalt = Color(0xFF2563EB);
  static const seed = cobalt;

  /// The same cobalt hue lifted one lightness step, used only on the dark
  /// #0F1115 background where raw [#2563EB] would sit below 4.5:1 against it.
  /// This is a readability step of the single accent, not a second accent.
  static const cobaltLifted = Color(0xFF60A5FA);

  // ── Dark mode surfaces ────────────────────────────────────────────────────
  // Small luminance steps keep cards legible without making the screen grey.
  static const darkBackground = Color(0xFF0F1115);
  static const darkSurface = Color(0xFF0F1115); // main scaffold bg
  static const darkSurfaceLowest = Color(0xFF0A0C0F);
  static const darkSurfaceLow = Color(0xFF161920); // cards / sections
  static const darkSurfaceHigh = Color(0xFF1E2128);

  // ── Light mode surfaces ───────────────────────────────────────────────────
  static const lightBackground = Color(0xFFF8F9FA);
  static const lightSurface = Color(0xFFF8F9FA); // main scaffold bg
  static const lightSurfaceLowest = Color(0xFFFFFFFF); // cards / sheets
  static const lightSurfaceLow = Color(0xFFFFFFFF); // cards / sections
  static const lightSurfaceHigh = Color(0xFFEEF0F4);

  // ── Dividers ──────────────────────────────────────────────────────────────
  // Row separators stay barely visible: white/5 on dark, a whisper of neutral
  // black on light. Hierarchy comes from surface contrast, not from lines.
  static const darkDivider = Color(0x0DFFFFFF);
  static const lightDivider = Color(0x0F000000);

  // ── Semantic states ───────────────────────────────────────────────────────
  static const success = Color(0xFF208A5D);
  static const successDark = Color(0xFF4ADE80);
  static const warning = Color(0xFFA56008);
  static const warningDark = Color(0xFFFBBF24);
  static const info = Color(0xFF2563EB);
  static const infoDark = Color(0xFF93C5FD);
}

@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.success,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.info,
    required this.infoContainer,
    required this.onInfoContainer,
  });

  final Color success;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color info;
  final Color infoContainer;
  final Color onInfoContainer;

  static const light = AppSemanticColors(
    success: AppColors.success,
    successContainer: Color(0xFFDCFCE7),
    onSuccessContainer: Color(0xFF0B4D32),
    warning: AppColors.warning,
    warningContainer: Color(0xFFFEF9C3),
    onWarningContainer: Color(0xFF603900),
    info: AppColors.info,
    infoContainer: Color(0xFFDBEAFE),
    onInfoContainer: Color(0xFF1E3A5F),
  );

  static const dark = AppSemanticColors(
    success: AppColors.successDark,
    successContainer: Color(0xFF14532D),
    onSuccessContainer: Color(0xFFBBF7D0),
    warning: AppColors.warningDark,
    warningContainer: Color(0xFF451A03),
    onWarningContainer: Color(0xFFFDE68A),
    info: AppColors.infoDark,
    infoContainer: Color(0xFF1E3A5F),
    onInfoContainer: Color(0xFFBFDBFE),
  );

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? info,
    Color? infoContainer,
    Color? onInfoContainer,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      info: info ?? this.info,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
    );
  }

  @override
  AppSemanticColors lerp(covariant AppSemanticColors? other, double t) {
    if (other == null) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t) ?? success,
      successContainer:
          Color.lerp(successContainer, other.successContainer, t) ??
          successContainer,
      onSuccessContainer:
          Color.lerp(onSuccessContainer, other.onSuccessContainer, t) ??
          onSuccessContainer,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      warningContainer:
          Color.lerp(warningContainer, other.warningContainer, t) ??
          warningContainer,
      onWarningContainer:
          Color.lerp(onWarningContainer, other.onWarningContainer, t) ??
          onWarningContainer,
      info: Color.lerp(info, other.info, t) ?? info,
      infoContainer:
          Color.lerp(infoContainer, other.infoContainer, t) ?? infoContainer,
      onInfoContainer:
          Color.lerp(onInfoContainer, other.onInfoContainer, t) ??
          onInfoContainer,
    );
  }
}

/// The app's top-level areas, in navigation order.
enum AppFeature { home, attendance, timetable, tasks, notes }

/// The accent pair one feature owns: an accent for strokes, icons and text,
/// plus a container pair for tinted surfaces.
///
/// All features share the Electric Cobalt anchor in light mode; dark mode
/// lifts slightly for readability. Semantic distinctions (success/warning)
/// are expressed through [AppSemanticColors], not per-feature hues.
@immutable
class FeaturePalette {
  const FeaturePalette({
    required this.accent,
    required this.container,
    required this.onContainer,
  });

  final Color accent;
  final Color container;
  final Color onContainer;

  FeaturePalette lerp(FeaturePalette other, double t) => FeaturePalette(
    accent: Color.lerp(accent, other.accent, t) ?? accent,
    container: Color.lerp(container, other.container, t) ?? container,
    onContainer: Color.lerp(onContainer, other.onContainer, t) ?? onContainer,
  );
}

/// The single accent every feature shares.
///
/// Features do not own colours: Home, Attendance, Timetable, Tasks and Notes
/// all resolve to Electric Cobalt, in light mode exactly `#2563EB` and in dark
/// mode the same hue lifted for contrast. Semantic meaning (present, absent,
/// on-target, below-target) is expressed through [AppSemanticColors], never
/// through a feature hue.
@immutable
class FeatureColors extends ThemeExtension<FeatureColors> {
  const FeatureColors({
    required this.home,
    required this.attendance,
    required this.timetable,
    required this.tasks,
    required this.notes,
  });

  final FeaturePalette home;
  final FeaturePalette attendance;
  final FeaturePalette timetable;
  final FeaturePalette tasks;
  final FeaturePalette notes;

  static const _light = FeaturePalette(
    accent: AppColors.cobalt,
    container: Color(0xFFDBEAFE),
    onContainer: Color(0xFF1E3A5F),
  );

  static const _dark = FeaturePalette(
    accent: AppColors.cobaltLifted,
    container: Color(0xFF1E3A5F),
    onContainer: Color(0xFFBFDBFE),
  );

  static const light = FeatureColors(
    home: _light,
    attendance: _light,
    timetable: _light,
    tasks: _light,
    notes: _light,
  );

  static const dark = FeatureColors(
    home: _dark,
    attendance: _dark,
    timetable: _dark,
    tasks: _dark,
    notes: _dark,
  );

  FeaturePalette of(AppFeature feature) => switch (feature) {
    AppFeature.home => home,
    AppFeature.attendance => attendance,
    AppFeature.timetable => timetable,
    AppFeature.tasks => tasks,
    AppFeature.notes => notes,
  };

  @override
  FeatureColors copyWith({
    FeaturePalette? home,
    FeaturePalette? attendance,
    FeaturePalette? timetable,
    FeaturePalette? tasks,
    FeaturePalette? notes,
  }) {
    return FeatureColors(
      home: home ?? this.home,
      attendance: attendance ?? this.attendance,
      timetable: timetable ?? this.timetable,
      tasks: tasks ?? this.tasks,
      notes: notes ?? this.notes,
    );
  }

  @override
  FeatureColors lerp(covariant FeatureColors? other, double t) {
    if (other == null) return this;
    return FeatureColors(
      home: home.lerp(other.home, t),
      attendance: attendance.lerp(other.attendance, t),
      timetable: timetable.lerp(other.timetable, t),
      tasks: tasks.lerp(other.tasks, t),
      notes: notes.lerp(other.notes, t),
    );
  }
}
