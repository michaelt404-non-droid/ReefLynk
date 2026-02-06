// lib/config/feature_flags.dart

class FeatureFlags {
  // This flag controls all features related to the physical reef controller.
  // Set to `false` for the manual-only release.
  static const bool isControllerEnabled = false;

  // This flag controls all features related to the lighting system.
  // Set to `false` for the manual-only release.
  static const bool isLightingEnabled = false;
}
