import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_map_sdk/kakao_map_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/env.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'data/calendar_controller.dart';
import 'data/providers.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Web: SDK web/index.html da yuklanadi (initialize kerak emas).
  if (!kIsWeb && Env.hasKakaoMapKey) {
    await KakaoMapSdk.instance.initialize(Env.kakaoNativeAppKey);
    // Kakao Developers'ga ro'yxatdan o'tkazish uchun key hash'ni konsolga chiqaramiz.
    debugPrint('Kakao key hash: ${await KakaoMapSdk.instance.hashKey()}');
  }
  // GIS SDK'ni fonda yuklaymiz — ilova ochilishini kutdirmaymiz.
  initGoogleSignIn().catchError((Object e) => debugPrint('Google Sign-In init failed: $e'));
  final prefs = await SharedPreferences.getInstance();
  runApp(ProviderScope(
    overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
    child: const LifeRadarApp(),
  ));
}

class LifeRadarApp extends ConsumerWidget {
  const LifeRadarApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      locale: ref.watch(localeProvider),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: ref.watch(routerProvider),
    );
  }
}
