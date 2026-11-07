# Demo ssenariysi (video va pitch uchun)

PLAN'dagi 5 qadamli hikoya ilovada shunday ko'rsatiladi. Hammasi `(sample)` belgili demo ma'lumotlarga tayanadi (`app/lib/data/sample_data.dart`), shuning uchun internetdagi real eventlar o'zgarsa ham ssenariy buzilmaydi.

## Sanalar

| Narsa | Sana (11-14 gacha) |
|---|---|
| Busan safari (reja) | 11-20 — 11-22, Haeundae |
| Busan katta konsert | 11-20, Asiad stadioni |
| Daejeon AI seminar | 11-20; **ro'yxatdan o'tish muddati 11-15** |
| AI & Startup Expo (BEXCO) | 11-21; muddat 11-18 |

**11-15 dan keyin** hamma sample'lar butun haftalarga oldinga suriladi: Busan safari doim bugundan 6–12 kun keyin turadi. Hakamlar APK'ni keyinroq ochsa ham demo kartalari chiqadi. Sanalar o'zgaradi, hafta kunlari va oraliqlar esa saqlanadi.

## Tayyorgarlik

- [ ] `env.json` da `GEMINI_API_KEY` bor bo'lsin (AI matnlari uchun). Bo'lmasa kartalar qoida matnida chiqadi.
- [ ] Ilovani bir marta oldindan ochib qo'ying: Gemini matnlari keshga tushadi va sahnada darhol chiqadi.
- [ ] Profile → bildirishnomalarni yoqing (5-qadam uchun).
- [ ] Google Calendar ulanmagan bo'lsin: shunda sample rejalar ko'rinadi. Ulangan bo'lsa, haqiqiy kalendarda "Busan" rejasi bo'lishi kerak.
- [ ] Telefon: Kakao xarita va Google login ishlashini tekshiring.

## Qadamlar

1. **Kirish va qiziqishlar.** Google bilan kiring (yoki mehmon sifatida) → qiziqishlar: **AI, Startup, Music**.
2. **Home → AI kartasi.** "Plan alert": Busan safari kuni yaqin joyda katta konsert bor, transport va mehmonxonaga talab oshadi. Kartani oching:
   - ✨ AI belgisi va "Gemini가 작성" yozuvi;
   - ishonch darajasi va manbalar;
   - ob-havo (safari 10 kun ichida bo'lsa).
3. **Map → Route.** Seoul → Busan, sana **Busan safari kuni** (11-20). Yo'l bo'ylab **Daejeon AI seminar** chiqadi, qo'shimcha masofa va vaqti bilan.
4. **Event → harakat.** "Kalendarga qo'shish" → seminar rejaga aylanadi va Home uni kuzatadi.
   - ⚠️ Sample eventlarda ro'yxatdan o'tish linki yo'q. "Ro'yxatdan o'tish" tugmasini ko'rsatish uchun Discover'dan **haqiqiy** event oching (TourAPI/K-Startup eventlarida rasmiy link bor).
5. **Push.** Seminar muddati 2 kun ichida qolsa (11-13 dan boshlab), ilova ochilganda bildirishnoma chiqadi: *"Ro'yxatdan o'tish muddati yaqin"*. Hozircha bu lokal bildirishnoma. Server push (FCM) rejasi: [PUSH_NOTIFICATIONS.uz.md](PUSH_NOTIFICATIONS.uz.md).

**Bonus: feedback.** Konsert kartasiga 👎 bosing. Keyin boshqa konsertlar pastga tushadi, AI eventlar yuqoriga chiqadi ("fewer signals like this").

## Tekshiruv
Ssenariyning asosiy kartalari testlar bilan himoyalangan: `app/test/demo_data_test.dart`. U 11-13 va 2027 yil uchun konsert ogohlantirishi va seminar muddati kartasi chiqishini tekshiradi.
