import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Android: flutter_local_notifications. Ruxsat holati keshlanadi, chunki API sinxron
/// (`notifyPermission()`), Android esa faqat asinxron javob beradi.
final _plugin = FlutterLocalNotificationsPlugin();
var _ready = false;
var _permission = 'default';

bool get _android => defaultTargetPlatform == TargetPlatform.android;

bool get notifySupported => _android;

/// main() da bir marta: plaginni ishga tushiradi va joriy ruxsatni o'qiydi.
Future<void> initNotify() async {
  if (!_android) return;
  try {
    await _plugin.initialize(
      settings: const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
    );
    _ready = true;
    await _refreshPermission();
  } catch (e) {
    debugPrint('notify init: $e');
  }
}

AndroidFlutterLocalNotificationsPlugin? get _androidImpl =>
    _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

Future<void> _refreshPermission() async {
  final enabled = await _androidImpl?.areNotificationsEnabled();
  _permission = enabled == true ? 'granted' : (_permission == 'denied' ? 'denied' : 'default');
}

/// 'granted' | 'denied' | 'default' | 'unsupported'
String notifyPermission() => !_android ? 'unsupported' : _permission;

/// Android 13+ da tizim ruxsat oynasi; eskilarida ruxsat sozlamalardan keladi.
Future<String> requestNotifyPermission() async {
  if (!_android) return 'unsupported';
  if (!_ready) await initNotify();
  try {
    final granted = await _androidImpl?.requestNotificationsPermission();
    await _refreshPermission();
    if (_permission != 'granted' && granted == false) _permission = 'denied';
  } catch (e) {
    debugPrint('notify permission: $e');
  }
  return _permission;
}

/// Ruxsat butunlay rad etilgan bo'lsa, Android tizim oynasi qayta chiqmaydi — LifeRadar'ning
/// bildirishnoma sozlamalarini ochamiz.
Future<bool> openNotifySettings() async {
  if (!_android) return false;
  try {
    await const AndroidIntent(
      action: 'android.settings.APP_NOTIFICATION_SETTINGS',
      arguments: {'android.provider.extra.APP_PACKAGE': 'com.liferadar.liferadar'},
    ).launch();
    return true;
  } catch (e) {
    debugPrint('notify settings: $e');
    return false;
  }
}

const _details = NotificationDetails(
  android: AndroidNotificationDetails(
    'signals',
    'LifeRadar signals',
    channelDescription: 'Deadlines and alerts for your plans',
    importance: Importance.high,
    priority: Priority.high,
  ),
);

/// Bir xil [tag] — bitta bildirishnoma (yangilanadi, takrorlanmaydi).
void showSystemNotification(String title, String body, {String? tag}) {
  if (!_ready || _permission != 'granted') return;
  final id = (tag ?? '$title$body').hashCode & 0x7fffffff;
  _plugin.show(id: id, title: title, body: body, notificationDetails: _details).catchError(
    (Object e) => debugPrint('notify show: $e'),
  );
}
