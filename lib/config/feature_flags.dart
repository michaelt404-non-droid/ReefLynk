// lib/config/feature_flags.dart

class FeatureFlags {
  // This flag controls all features related to the physical reef controller.
  // Off by default for the App Store (manual-only) release. Turn on for local
  // builds with: --dart-define=CONTROLLER=true
  static const bool isControllerEnabled =
      bool.fromEnvironment('CONTROLLER', defaultValue: false);

  // This flag controls all features related to the lighting system.
  // Off by default for the App Store (manual-only) release. Turn on for local
  // builds with: --dart-define=LIGHTING=true
  static const bool isLightingEnabled =
      bool.fromEnvironment('LIGHTING', defaultValue: false);
}
