import 'package:flutter/material.dart';

abstract final class AppColors {
  // A violet-blue accent gives CollegeOS a distinct academic/productivity
  // identity while remaining calm enough for information-dense screens.
  static const violet = Color(0xFF7367F0);
  static const blue = Color(0xFF4F8CFF);
  static const seed = violet;

  static const lightSurface = Color(0xFFF6F7FB);
  static const lightSurfaceLowest = Color(0xFFFFFFFF);
  static const lightSurfaceLow = Color(0xFFF0F2F8);
  static const lightSurfaceHigh = Color(0xFFE7EAF3);

  // Purpose-built dark surfaces, rather than inverted light colors. The small
  // luminance steps keep cards legible without making the screen look grey.
  static const darkSurface = Color(0xFF101116);
  static const darkSurfaceLowest = Color(0xFF0B0C10);
  static const darkSurfaceLow = Color(0xFF17181E);
  static const darkSurfaceHigh = Color(0xFF22242C);

  static const success = Color(0xFF208A5D);
  static const successDark = Color(0xFF79D9AE);
  static const warning = Color(0xFFA56008);
  static const warningDark = Color(0xFFF2BE6B);
  static const info = Color(0xFF3867C8);
  static const infoDark = Color(0xFF9DBAFF);
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
    successContainer: Color(0xFFDDF5E9),
    onSuccessContainer: Color(0xFF0B4D32),
    warning: AppColors.warning,
    warningContainer: Color(0xFFFFEBCB),
    onWarningContainer: Color(0xFF603900),
    info: AppColors.info,
    infoContainer: Color(0xFFE0E9FF),
    onInfoContainer: Color(0xFF173B84),
  );

  static const dark = AppSemanticColors(
    success: AppColors.successDark,
    successContainer: Color(0xFF153D2D),
    onSuccessContainer: Color(0xFF9BE7C2),
    warning: AppColors.warningDark,
    warningContainer: Color(0xFF4A3515),
    onWarningContainer: Color(0xFFFFD79A),
    info: AppColors.infoDark,
    infoContainer: Color(0xFF25375F),
    onInfoContainer: Color(0xFFC6D5FF),
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
