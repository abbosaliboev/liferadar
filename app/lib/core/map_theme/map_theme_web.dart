import 'package:web/web.dart' as web;

/// `<html class="lr-dark-map">` — web/index.html dagi CSS faqat Kakao plitkalarini qorong'ilashtiradi.
void setMapDarkMode(bool dark) => web.document.documentElement?.classList.toggle('lr-dark-map', dark);
