# LifeRadar AI — MVP Plan (O'zbekcha) · [한국어](PLAN.ko.md)

> Topshirish muddati: **2026-11-14** · Jamoa: 2 kishi · Platforma: **Flutter (Android)** · UI: **Koreys + Ingliz**

---

## 1. MVP g'oyasi (bitta jumlada)

Foydalanuvchining **Google Calendar rejalari** va **qiziqishlari**ni real **eventlar + ob-havo** bilan bog'lab,
AI "nima uchun bu sizga muhim"ligini tushuntiradi va **xaritada** (shu jumladan A→B yo'nalishi bo'ylab) ko'rsatadi.

**Demo hikoyasi (pitch uchun):**
1. Foydalanuvchi Google bilan kiradi, qiziqishlarini tanlaydi (AI, Startup, Music...).
2. Kalendarda "20-noyabr — Busan" rejasi bor → Home'da AI kartasi: *"Shu kuni Busanda katta konsert bor, transport band bo'ladi, ob-havo +14°C"* + manbalar.
3. Map → Route: Seoul → Busan. Yo'l bo'ylab Daejeondagi AI seminar ko'rinadi: *"+12 km, +18 daq"*.
4. Event → "Ro'yxatdan o'tish" (rasmiy sahifa) + "Kalendarga qo'shish" → u yangi rejaga aylanadi, AI uni ham kuzata boshlaydi.
5. Ertasi kuni push: *"Siz qo'shgan seminar uchun ro'yxatdan o'tish 2 kunda tugaydi"*.

---

## 2. Scope

### ✅ MVP'da bor (Must)
| # | Funksiya | Izoh |
|---|---|---|
| M1 | Google Sign-In + Calendar ulash | Calendar **read + event qo'shish** |
| M2 | Onboarding | Qiziqishlar, maqsadlar, til (ko/en) |
| M3 | **Home — AI Insights** | Reja + event + ob-havo bog'lanishi, "why", manba, ishonch darajasi |
| M4 | **Map** | Layerlar: My Plans / Recommended / Route Opportunities |
| M5 | **Route mode** | A→B polyline, koridordagi eventlar, qo'shimcha masofa/vaqt |
| M6 | **Discover** | Qiziqish bo'yicha eventlar ro'yxati + filtr |
| M7 | Event detail | Tavsif, sana, joy, "why for you", registratsiya linki, Kalendarga qo'shish |
| M8 | Feedback | 👍 / 👎 / yashirish → keyingi tavsiyalarga ta'sir |
| M9 | Proaktiv push (FCM) | Kunlik skan → yangi muhim insight bo'lsa push |
| M10 | i18n | ko / en |

### 🟡 Vaqt qolsa (Should)
- Gemini **Google Search grounding** bilan "yangi eventlarni internetdan topish"
- Ish/stipendiya (Scenario 5) — event bazasiga `type: job|scholarship` sifatida qo'shiladi
- Ob-havo ogohlantirishlari (yomg'ir → reja kuniga)

### ❌ MVP'da yo'q (Won't)
- Ilova ichida registratsiya formasi (tashqi linkka o'tamiz)
- iOS, real-time transport ma'lumoti, kompaniya/industriya tahlili (Scenario 4)

---

## 3. Arxitektura

```
┌──────────────── Flutter App (Android) ────────────────┐
│ Home · Map · Plans · Discover · Settings              │
│ google_sign_in → Calendar API (read/insert)           │
│ Calendar → plans sinxron (app ochilganda)             │
└───────┬───────────────────────┬───────────────────────┘
        │ Firestore              │ Callable Functions
        ▼                        ▼
┌──────────────── Firebase ─────────────────────────────┐
│ Auth · Firestore · FCM                                │
│ Cloud Functions (TypeScript):                         │
│  • ingestEvents   (cron, kuniga 1)  TourAPI, KOPIS,   │
│                    curated seed JSON                  │
│  • geocodePlan    (trigger) joy matni → lat/lng       │
│  • buildInsights  (cron + trigger) matching → Gemini  │
│  • routeDiscover  (callable) Kakao directions + koridor│
│  • sendPush       (insight yaratilganda) FCM          │
└───────┬───────────────────────────────────────────────┘
        ▼
 Gemini API · Kakao Mobility/Local · TourAPI · KOPIS · OpenWeather
```

### Asosiy texnik qarorlar
| Mavzu | Qaror | Sabab |
|---|---|---|
| Backend | Firebase + Cloud Functions (TS) | Auth/DB/push/cron bitta joyda, 2 kishiga eng tez |
| AI | Gemini Flash | Koreys tili, JSON output, Search grounding, bepul tier |
| Xarita ko'rinishi | `google_maps_flutter` | Android'da bepul, barqaror |
| Yo'nalish (route) | **Kakao Mobility Directions** | Google Maps Koreyada avtomobil yo'nalishini bermaydi |
| Geocoding | Kakao Local API | Koreys manzillarni yaxshi tushunadi |
| Eventlar | TourAPI (festival), KOPIS (konsert), curated JSON (IT/hackathon) | Real + demo ishonchli |
| Ob-havo | OpenWeather (5 kunlik) | Oddiy, bepul. (KMA — keyinroq) |
| State | Riverpod + go_router | Standart, testlash oson |
| i18n | Flutter `gen_l10n` (ARB) | Rasmiy usul |

### "AI xato qilmasligi" uchun yondashuv (Reliability)
AI **o'zi event o'ylab topmaydi**. Ikki bosqich:
1. **Deterministik matching** (kod): sana kesishuvi, masofa (km), qiziqish teglari → nomzodlar + ball.
2. **Gemini** faqat shu nomzodlarni oladi → `why`, `impact`, `confidence` ni JSON'da qaytaradi; manbalar har doim real URL.

Bu pitch'da kuchli argument: "hallucination'ga qarshi grounding".

### Route algoritmi
1. Kakao: A→B polyline + umumiy vaqt.
2. Polyline'ni ~2 km'da sample → har event uchun polyline'gacha eng yaqin masofa (haversine).
3. Filtr: koridor ≤ 15 km, sana safar oralig'ida, qiziqishga mos.
4. Top 5 uchun: Kakao A→Event→B − A→B = **qo'shimcha km / daqiqa**.
5. Ball = qiziqish mosligi × yaqinlik × vaqt mosligi → Gemini qisqa tushuntirish.

---

## 4. Ma'lumotlar modeli (Firestore)

```
users/{uid}
  displayName, locale, interests[], goals[], homeCity, fcmToken, calendarConnected

users/{uid}/plans/{planId}        ← Calendar'dan sinxron
  title, start, end, locationText, lat, lng, city, source: "gcal", gcalEventId

events/{eventId}                  ← umumiy baza
  title{ko,en}, description, type: event|concert|festival|conference|hackathon|job|scholarship
  tags[], start, end, venue, address, lat, lng, city, url, registerUrl, deadline, source, imageUrl

users/{uid}/insights/{insightId}
  kind: plan_alert|opportunity|route|deadline
  title, body, why, impact, confidence(0-1)
  planId?, eventIds[], signals[{type:weather|event, summary}], sources[{title,url}]
  createdAt, notified, feedback: like|dislike|hidden|null

users/{uid}/routes/{routeId}
  origin{name,lat,lng}, dest{...}, date, polyline, durationMin, distanceKm
  opportunities[{eventId, detourKm, detourMin, score, why}]
```

---

## 5. Ekranlar

| Ekran | Asosiy elementlar |
|---|---|
| Splash / Login | Google bilan kirish, privacy tushuntirish |
| Onboarding | Qiziqish chiplari, maqsad, Calendar ruxsati |
| **Home** | Insight kartalari (why, signal ikonlari, ishonch, manba), 👍👎 |
| **Map** | Layer toggle, mode: Explore / My Map / Route, bottom sheet |
| Route input | Qayerdan / qayerga / sana → natija ro'yxati + xarita |
| **Discover** | Kategoriya filtrlari, ro'yxat, "Why for you" |
| Event detail | Ma'lumot, xaritada, Register, Kalendarga qo'shish |
| My Plans | Kalendardan kelgan rejalar, har biriga bog'langan insightlar |
| Settings | Til, ulangan servislar (disconnect), push sozlamalari |

---

## 6. Kunlik reja (9 kun)

| Kun | Sana | Vazifa | Natija |
|---|---|---|---|
| D1 | 11-05 (bugun) | Plan ✔ · **API kalitlarga ariza** (data.go.kr TourAPI/KOPIS, Kakao, Gemini, OpenWeather) · Firebase loyiha · Google Cloud OAuth (Calendar scope, test users) | Barcha kalitlar |
| D2 | 11-06 | Flutter skelet (Riverpod, go_router, theme, i18n) · Login + Onboarding · Dizayn tizimi | Kirish ishlaydi |
| D3 | 11-07 | Calendar read → plans sinxron · `geocodePlan` · `ingestEvents` + seed JSON | Firestore'da real data |
| D4 | 11-08 | `buildInsights` (matching + Gemini + ob-havo) · **Home ekran** | Birinchi AI kartasi ✨ |
| D5 | 11-09 | **Map**: markerlar, layerlar, bottom sheet, Event detail | Xarita ishlaydi |
| D6 | 11-10 | **Route**: Kakao directions, koridor, detour hisob | Seoul→Busan demo |
| D7 | 11-11 | Discover · Kalendarga qo'shish · Register link · Feedback · FCM push + cron | Barcha Must tayyor |
| D8 | 11-12 | ko/en tarjima · UI polish · bo'sh/xato holatlar · demo ssenariy datasi | Demo tayyor |
| D9 | 11-13 | Bug fix · release APK · demo video · pitch deck | Topshirishga tayyor |
| — | 11-14 | **Topshirish** (zaxira kun) | 🚀 |

---

## 7. Risklar

| Risk | Yechim |
|---|---|
| data.go.kr API tasdiqlanishi kechikishi | Bugun ariza; kechiksa curated JSON bilan davom |
| Google OAuth "unverified app" | Testing rejim + demo akkauntlar test user sifatida |
| Gemini limit/rate | Insight'larni cache qilish (Firestore), faqat yangi nomzodlar uchun chaqirish |
| Kakao Mobility kvota | Route natijalarini saqlash; detour faqat top 5 uchun |
| Vaqt yetmasligi | Should-funksiyalar birinchi qisqaradi; demo ssenariy yo'li har doim ishlashi kerak |

---

## 8. Repo tuzilishi (taklif)

```
hack_idea/
  app/          ← Flutter
  functions/    ← Cloud Functions (TypeScript)
  data/seed/    ← curated eventlar JSON
  docs/         ← PLAN.uz.md, PLAN.ko.md, dizayn, pitch
  firebase.json, firestore.rules
```
