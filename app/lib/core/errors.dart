import 'package:flutter/foundation.dart';

import '../l10n/app_localizations.dart';

/// Foydalanuvchiga ko'rsatiladigan xato turlari. Xom `e.toString()` ekranga chiqmasin:
/// unda URL, server JSON javobi va texnik nomlar bo'ladi.
enum ErrorKind { offline, busy, service, noRoute, generic }

/// Xatoni turiga ajratadi. [error] — exception yoki uning matni (state'da saqlangan bo'lsa).
ErrorKind classifyError(Object? error) {
  final s = error?.toString() ?? '';
  bool has(String p) => s.contains(p);
  if (_offline.any(has)) return ErrorKind.offline;
  if (has('HTTP 429') || has('RESOURCE_EXHAUSTED') || has('quota')) return ErrorKind.busy;
  if (has('HTTP 401') || has('HTTP 403') || has('missing') || has('not-configured')) return ErrorKind.service;
  if (has('No transit route') || has('No route:')) return ErrorKind.noRoute;
  if (has('HTTP 5')) return ErrorKind.service;
  return ErrorKind.generic;
}

const _offline = [
  'SocketException',
  'ClientException',
  'Failed host lookup',
  'Failed to fetch',
  'XMLHttpRequest',
  'TimeoutException',
  'Connection refused',
  'Connection reset',
  'Connection closed',
  'Network is unreachable',
  'ERR_INTERNET_DISCONNECTED',
  'NETWORK_ERROR',
  'network_error',
];

/// Tushunarli, lokalizatsiya qilingan xabar. Asl xato debug log'ga yoziladi.
String friendlyError(AppLocalizations l10n, Object? error) {
  if (error != null) debugPrint('error: $error');
  return switch (classifyError(error)) {
    ErrorKind.offline => l10n.errOffline,
    ErrorKind.busy => l10n.errBusy,
    ErrorKind.service => l10n.errService,
    ErrorKind.noRoute => l10n.errNoRoute,
    ErrorKind.generic => l10n.errGeneric,
  };
}
