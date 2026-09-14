import 'package:flutter/material.dart';

class SafetyColors {
  static const safe = Color(0xFF39715B);
  static const caution = Color(0xFFA06A2C);
  static const danger = Color(0xFFB54747);

  static const safeLight = Color(0xFFE7EFEB);
  static const cautionLight = Color(0xFFF4ECE1);
  static const dangerLight = Color(0xFFF4E7E7);

  static Color safeFor(BuildContext context) =>
      Theme.of(context).colorScheme.brightness == Brightness.dark
      ? const Color(0xFF7BC89F)
      : safe;

  static Color cautionFor(BuildContext context) =>
      Theme.of(context).colorScheme.brightness == Brightness.dark
      ? const Color(0xFFE4B66F)
      : caution;

  static Color dangerFor(BuildContext context) =>
      Theme.of(context).colorScheme.brightness == Brightness.dark
      ? const Color(0xFFF08D8D)
      : danger;

  static Color safeSurfaceFor(BuildContext context) =>
      Theme.of(context).colorScheme.brightness == Brightness.dark
      ? const Color(0xFF173B2B)
      : safeLight;

  static Color cautionSurfaceFor(BuildContext context) =>
      Theme.of(context).colorScheme.brightness == Brightness.dark
      ? const Color(0xFF40321D)
      : cautionLight;

  static Color dangerSurfaceFor(BuildContext context) =>
      Theme.of(context).colorScheme.brightness == Brightness.dark
      ? const Color(0xFF4A2427)
      : dangerLight;
}
