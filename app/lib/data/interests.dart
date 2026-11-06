import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

/// Tanlash mumkin bo'lgan qiziqishlar. [tag] — eventlardagi `tags` bilan bir xil kalit.
class InterestOption {
  const InterestOption(this.tag, this.label, this.icon);
  final String tag;
  final LocalizedText label;
  final IconData icon;
}

const interestOptions = <InterestOption>[
  InterestOption('ai', LocalizedText(ko: 'AI', en: 'AI'), Icons.auto_awesome),
  InterestOption('startup', LocalizedText(ko: '스타트업', en: 'Startups'), Icons.rocket_launch_outlined),
  InterestOption('developer', LocalizedText(ko: '개발', en: 'Development'), Icons.code),
  InterestOption('data', LocalizedText(ko: '데이터', en: 'Data'), Icons.insights),
  InterestOption('design', LocalizedText(ko: '디자인', en: 'Design'), Icons.palette_outlined),
  InterestOption('career', LocalizedText(ko: '채용·커리어', en: 'Careers & jobs'), Icons.work_outline),
  InterestOption('student', LocalizedText(ko: '학생 프로그램', en: 'Student programs'), Icons.school_outlined),
  InterestOption('networking', LocalizedText(ko: '네트워킹', en: 'Networking'), Icons.groups_outlined),
  InterestOption('music', LocalizedText(ko: '음악·공연', en: 'Music & shows'), Icons.music_note),
  InterestOption('culture', LocalizedText(ko: '문화·축제', en: 'Culture & festivals'), Icons.celebration_outlined),
];

/// main()'da yuklanib override qilinadi (ProviderScope).
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPrefsProvider must be overridden in main()'),
);

final interestsProvider = NotifierProvider<InterestsController, Set<String>>(InterestsController.new);

/// Foydalanuvchi qiziqishlari — qurilmada saqlanadi (web: localStorage).
/// Bo'sh to'plam = onboarding hali o'tilmagan.
class InterestsController extends Notifier<Set<String>> {
  static const _key = 'interests';

  @override
  Set<String> build() => (ref.read(sharedPrefsProvider).getStringList(_key) ?? const []).toSet();

  bool get hasCompletedOnboarding => state.isNotEmpty;

  Future<void> save(Set<String> tags) async {
    state = {...tags};
    await ref.read(sharedPrefsProvider).setStringList(_key, tags.toList());
  }
}
