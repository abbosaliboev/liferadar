/// Bildirishnoma qo'llanmaydigan platformalar uchun.
bool get notifySupported => false;

Future<void> initNotify() async {}

/// Tizimdagi bildirishnoma sozlamalari (bo'lsa).
Future<bool> openNotifySettings() async => false;

/// 'granted' | 'denied' | 'default' | 'unsupported'
String notifyPermission() => 'unsupported';

Future<String> requestNotifyPermission() async => 'unsupported';

void showSystemNotification(String title, String body, {String? tag}) {}
