import 'dart:ui';

/// prysm palette. Color is computed from state, never assigned by hand:
/// see prysm/system/specs/principles.md and emotion.md. Black is the
/// default surface (zero OLED power); the seven spectrum values encode
/// emotion; white is neutral, gray is inactive.
abstract final class Prysm {
  static const black = Color(0xFF000000);
  static const panel = Color(0xFF101010);
  static const line = Color(0xFF2C2C2E);
  static const white = Color(0xFFFFFFFF); // neutral
  static const inactive = Color(0xFF4B4B4D);

  static const anger = Color(0xFFFF0000); // danger, critical failure
  static const disgust = Color(0xFFFF5B00); // invalid data, rejection
  static const surprise = Color(0xFFFCF000); // attention, caution
  static const joy = Color(0xFF00FE00); // success, confirm, growth
  static const interest = Color(0xFF00ACFF); // focus, exploration
  static const sadness = Color(0xFF304FFE); // withdrawal, inactivity
  static const fear = Color(0xFFD500F9); // unknown threat, boundary
}
