/// Android/iOS uchun keyin flutter_local_notifications + FCM qo'shiladi.
bool get notifySupported => false;

/// 'granted' | 'denied' | 'default' | 'unsupported'
String notifyPermission() => 'unsupported';

Future<String> requestNotifyPermission() async => 'unsupported';

void showSystemNotification(String title, String body, {String? tag}) {}
