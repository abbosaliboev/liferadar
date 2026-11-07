import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

bool get notifySupported => web.window.has('Notification');

/// 'granted' | 'denied' | 'default' | 'unsupported'
String notifyPermission() => notifySupported ? web.Notification.permission : 'unsupported';

/// Brauzer ruxsat oynasi (foydalanuvchi bosgandagina chaqirilishi kerak).
Future<String> requestNotifyPermission() async {
  if (!notifySupported) return 'unsupported';
  final r = await web.Notification.requestPermission().toDart;
  return r.toDart;
}

/// Telegram'dagi kabi tizim xabari: ilova ikonkasi, sarlavha, matn. Bosilsa — ilova oynasi ochiladi.
void showSystemNotification(String title, String body, {String? tag}) {
  if (notifyPermission() != 'granted') return;
  final n = web.Notification(
    title,
    web.NotificationOptions(body: body, icon: 'icons/Icon-192.png', badge: 'icons/Icon-192.png', tag: tag ?? ''),
  );
  n.onclick = ((web.Event _) {
    web.window.focus();
    n.close();
  }).toJS;
}

extension on web.Window {
  bool has(String name) => (this as JSObject).has(name);
}
