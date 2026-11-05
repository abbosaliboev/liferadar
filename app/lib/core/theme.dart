import 'package:flutter/material.dart';

import '../models/models.dart';

abstract final class AppColors {
  static const brand = Color(0xFF3D5AFE);
  static const plan = Color(0xFF2962FF);
  static const recommended = Color(0xFFFF6D00);
  static const route = Color(0xFF00A86B);
}

ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.brand, brightness: brightness);
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    visualDensity: VisualDensity.compact,
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
    ),
  );
}

IconData categoryIcon(EventCategory c) => switch (c) {
      EventCategory.conference => Icons.mic_external_on,
      EventCategory.hackathon => Icons.code,
      EventCategory.concert => Icons.music_note,
      EventCategory.festival => Icons.celebration,
      EventCategory.meetup => Icons.groups,
      EventCategory.job => Icons.work_outline,
      EventCategory.scholarship => Icons.school_outlined,
    };

IconData signalIcon(SignalType t) => switch (t) {
      SignalType.event => Icons.event,
      SignalType.weather => Icons.wb_sunny_outlined,
      SignalType.traffic => Icons.train_outlined,
      SignalType.deadline => Icons.timer_outlined,
    };
