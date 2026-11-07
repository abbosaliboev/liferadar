# Proaktiv push (M9) — Firebase + FCM + Cloud Functions

> Holat (2026-11-07): **hali qilinmagan.** Loyihada Firebase umuman yo'q. Bu hujjat keyinchalik amalga oshirish uchun reja.

## Hozirgi holat

- Rejalar, qiziqishlar, feedback telefonda saqlanadi (`shared_preferences`).
- Insight'lar telefonda hisoblanadi: `app/lib/services/insight_engine.dart` (Dart, qoidalar asosida) + Gemini matnni boyitadi (`app/lib/ai/`).
- Login faqat Google Sign-In (Firebase Auth yo'q).
- Ilova ichidagi bildirishnoma uchun `app/lib/core/notify/` va `app/lib/data/notifications.dart` bor (lokal).

Shuning uchun asosiy qiyinchilik FCM'ning o'zi emas, **server foydalanuvchi ma'lumotini bilmasligi**.

## Variantlar

| Variant | Nima qiladi | Taxminiy vaqt | Server ma'lumot biladimi |
|---|---|---|---|
| **A. Faqat FCM** | Firebase ulanadi, telefon token oladi, push'ni Firebase Console'dan qo'lda yuborasiz | ~2–3 soat | Yo'q |
| **B. Gibrid** (tavsiya) | Cloud Function har kuni ertalab hamma qurilmaga "uyg'on" signalini yuboradi. Ilova insight'larni o'zi hisoblaydi va yangi muhim narsa bo'lsa bildirishnoma chiqaradi | ~0.5–1 kun | Faqat FCM token |
| **C. To'liq server** | Rejalar va qiziqishlar Firestore'ga sinxron bo'ladi, insight engine TypeScript'ga ko'chiriladi, push'ni server tanlaydi va matnini yozadi | ~2 kun yoki ko'proq | Ha |

## B variant — batafsil

```
Cloud Scheduler (har kuni 08:00 KST)
   └─▶ Cloud Function `dailyScan` (TypeScript)
          └─▶ FCM topic "daily-scan" ga data message {type: "scan"}
                 └─▶ Telefon: firebase_messaging background handler
                        ├─ rejalar/eventlar/qiziqishlarni qurilmadan o'qiydi
                        ├─ InsightEngine.build(...) ni ishlatadi
                        ├─ yangi planAlert/deadline bormi? (seenProvider bilan solishtiradi)
                        └─ bor bo'lsa → lokal bildirishnoma (core/notify)
```

Afzalliklari: insight engine bitta joyda (Dart'da) qoladi. Serverda shaxsiy ma'lumot saqlanmaydi. Token bazasi ham kerak emas, chunki topic'ga yuboriladi.

### 1. Firebase Console (qo'lda, ~20 daqiqa)
1. https://console.firebase.google.com → **Add project**. Mavjud Google Cloud loyihasini tanlash mumkin: OAuth client va API key turgan loyiha.
2. **Blaze** planga o'tish: Cloud Functions va Scheduler uchun shart. Darhol **Budget alert** qo'ying (masalan, $1 / $5).
3. Android ilova qo'shish: paket `com.liferadar.liferadar`, SHA-1 `5E:91:F8:91:6E:62:58:0C:71:56:81:95:61:DB:29:A0:94:2E:6B:F1`.
4. Cloud Messaging yoqilganini tekshirish (FCM HTTP v1 standart holatda yoqilgan bo'ladi).

### 2. Flutter tomoni (front)
```bash
dart pub global activate flutterfire_cli
cd app && flutterfire configure --platforms=android,web   # lib/firebase_options.dart yaratiladi
flutter pub add firebase_core firebase_messaging
```
- `main()`: `await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);`
- Android 13+: `FirebaseMessaging.instance.requestPermission()`. `POST_NOTIFICATIONS` manifestda bo'lishi kerak.
- `FirebaseMessaging.instance.subscribeToTopic('daily-scan')`. Web'da topic yo'q, shuning uchun faqat Android.
- `FirebaseMessaging.onBackgroundMessage(_bgHandler)`. Top-level funksiya bo'ladi, `@pragma('vm:entry-point')` bilan. Ichida `SharedPreferences` ochiladi, event feed asset'dan o'qiladi va `InsightEngine` chaqiriladi.
  - ⚠️ Background isolate'da Riverpod `ProviderScope` yo'q. Engine sof Dart bo'lgani uchun to'g'ridan-to'g'ri chaqirish mumkin.
  - ⚠️ Background'da Gemini chaqirmang (vaqt chegarasi bor). Qoida asosidagi matn yetarli.
- Bildirishnoma bosilsa, Home'ga o'tish va kartani ochish (`openSignal`).

### 3. Cloud Function (back)
```bash
npm i -g firebase-tools && firebase login
firebase init functions   # TypeScript
```
```ts
// functions/src/index.ts
import { onSchedule } from "firebase-functions/v2/scheduler";
import { initializeApp } from "firebase-admin/app";
import { getMessaging } from "firebase-admin/messaging";

initializeApp();

export const dailyScan = onSchedule(
  { schedule: "0 8 * * *", timeZone: "Asia/Seoul", region: "asia-northeast3" },
  async () => {
    await getMessaging().send({
      topic: "daily-scan",
      data: { type: "scan" },
      android: { priority: "high" },
    });
  },
);
```
`firebase deploy --only functions`

Demo uchun qo'shimcha: qo'lda chaqiriladigan HTTPS funksiya (`scanNow`). Bu taymerni kutmasdan sahnada push ko'rsatish uchun kerak.

### 4. Narx (taxminiy)
- FCM: bepul.
- Cloud Functions: oyiga 2 mln chaqiruv bepul. Kuniga 1 marta chaqirilsa, bu ≈ 0.
- Cloud Scheduler: 3 ta job'gacha bepul.
- Blaze karta talab qiladi, lekin bu hajmda to'lov ≈ $0. Budget alert baribir qo'yilsin.

### 5. Risklar
- **Samsung/Xiaomi batareya tejash** rejimi background handler'ni kechiktirishi yoki o'chirishi mumkin. Demo uchun "high priority" va ilovani "cheklanmagan" rejimga qo'yish kerak.
- **Data message va notification message:** faqat data message background handler'ni ishga tushiradi. Notification payload qo'shilsa, tizim o'zi ko'rsatadi va handler ishlamaydi.
- **8GB RAM:** Android build sekin. Push'ni faqat haqiqiy telefonda sinash mumkin.

## C variant — qachon kerak
Ko'p qurilma, server tomonda Gemini bilan shaxsiy push matni yoki tahlil kerak bo'lganda:
- Firebase Auth (Google provider) → `users/{uid}` ga `interests`, `plans`, `fcmTokens`, `feedback`.
- `insight_engine.dart` → TypeScript port (yoki Dart'ni server'da ishlatish, masalan Cloud Run).
- `dailyScan` har bir foydalanuvchi uchun insight hisoblaydi va yangisini token'ga yuboradi.
- Shaxsiy ma'lumot serverda saqlanadi. Maxfiylik siyosati va o'chirish oqimi kerak bo'ladi (account deletion allaqachon bor, uni Firestore'ga ham ulash kerak).

## Repo'larga bo'linish (hackathon: front / back / ai)

| Qism | Repo |
|---|---|
| Flutter ilova, `firebase_messaging` handler, lokal bildirishnoma | **front** |
| `functions/` (dailyScan, scanNow, keyinchalik Gemini proxy) | **back** |
| Gemini prompt/sxema/validatsiya (`app/lib/ai/`, `services/sources/ai_enrich.dart`), event yig'ish skripti (`tool/collect_events.dart`) | **ai** |

Eslatma: hozir Gemini kaliti ilova ichida (demo uchun). Back tayyor bo'lgach, Gemini chaqiruvi `back`dagi proxy funksiyaga o'tkazilsin, kalit esa ilovadan olib tashlansin.
