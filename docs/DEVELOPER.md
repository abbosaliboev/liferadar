# LifeRadar — 개발자 가이드

이 문서는 LifeRadar 코드를 처음 보는 개발자가 **로컬에서 실행하고, 구조를 이해하고, 기능을 추가**할 수 있도록 정리한 것입니다.
제품 소개는 [README](../README.md), 사용법은 [사용자 가이드](USER_GUIDE.md)를 보세요.

---

## 목차

1. [빠른 시작](#1-빠른-시작)
2. [API 키와 외부 서비스 설정](#2-api-키와-외부-서비스-설정)
3. [프로젝트 구조](#3-프로젝트-구조)
4. [아키텍처와 데이터 흐름](#4-아키텍처와-데이터-흐름)
5. [핵심 모듈 설명](#5-핵심-모듈-설명)
6. [디자인 시스템](#6-디자인-시스템) · [다국어 (i18n)](#6-1-다국어-i18n)
7. [테스트와 검증](#7-테스트와-검증)
8. [알려진 함정 (Gotchas)](#8-알려진-함정-gotchas)
9. [작업 규칙](#9-작업-규칙)
10. [다음 작업 (TODO)](#10-다음-작업-todo)

---

## 1. 빠른 시작

### 필요 환경

| 도구 | 버전 (확인된 환경) |
|---|---|
| Flutter | 3.41 (stable), Dart 3.11 |
| Chrome | 웹 실행용 (기본 개발 환경) |
| Android SDK | 35 — Android 빌드할 때만 |

> 💡 **기본 개발은 Chrome(Flutter Web)** 으로 합니다. Android 에뮬레이터는 메모리를 많이 쓰므로 필요하지 않습니다.
> Android는 데모 때 **실제 휴대폰**으로만 확인합니다 (Kakao 네이티브 SDK는 ARM 기기 전용).

### 실행

```bash
git clone https://github.com/abbosaliboev/hack_idea.git
cd hack_idea/app

flutter pub get
cp env.example.json env.json          # 키 입력 (2장 참고)
dart run tool/gen_web_env.dart        # web/kakao_config.js 생성 (Kakao 지도 JS SDK 로더)

flutter run -d chrome --web-port=8080 --dart-define-from-file=env.json
```

- **포트는 반드시 8080** — Kakao JavaScript SDK 도메인과 Google OAuth origin이 `http://localhost:8080`으로 등록되어 있습니다.
- VS Code: 실행 구성 **"LifeRadar (Chrome)"** 을 선택하면 위 옵션이 자동으로 들어갑니다 (`.vscode/launch.json`).
- `Address already in use` 오류 → 8080을 다른 프로세스가 쓰고 있습니다: `lsof -nP -iTCP:8080 -sTCP:LISTEN`

---

## 2. API 키와 외부 서비스 설정

모든 키는 `app/env.json` 에 넣고 `--dart-define-from-file=env.json` 으로 앱에 전달합니다.
**`env.json`과 `web/kakao_config.js`는 `.gitignore` 되어 있으므로 절대 커밋하지 마세요.**

| 키 | 용도 | 발급처 | 필수 설정 |
|---|---|---|---|
| `KAKAO_JS_KEY` | 웹 지도 표시 | [Kakao Developers](https://developers.kakao.com) → 앱 → 플랫폼 키 → JavaScript 키 | **JavaScript SDK 도메인**에 `http://localhost:8080` 추가, 카카오맵 사용 설정 ON |
| `KAKAO_NATIVE_APP_KEY` | Android 지도 표시 | 같은 앱 → 네이티브 앱 키 | Android 패키지 `com.liferadar.liferadar` + 키 해시 등록 |
| `KAKAO_REST_API_KEY` | 장소 검색, 자동차 경로 | 같은 앱 → REST API 키 | — |
| `GOOGLE_API_KEY` | 대중교통 경로(Routes), Places, Weather | Google Cloud Console → 사용자 인증 정보 | Routes / Places (New) / Weather / Calendar API 사용 설정 |
| `GOOGLE_OAUTH_WEB_CLIENT_ID` | Google 로그인 → 캘린더 접근 | Google Auth Platform → 클라이언트 → 웹 애플리케이션 | 승인된 JS 원본 `http://localhost:8080`, 대상 = 테스트 중 + **테스트 사용자 등록**, 범위 `calendar.events` |
| `TMAP_APP_KEY` | (예비) 대중교통 | SK Open API | 무료 할당량이 매우 작아 현재 미사용 |

### Android 키 해시 (Kakao 네이티브)

```bash
keytool -exportcert -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android \
  | openssl sha1 -binary | openssl base64
```

### 키가 정상인지 빠르게 확인

```bash
# Kakao REST
curl -H "Authorization: KakaoAK $KAKAO_REST_API_KEY" \
  "https://dapi.kakao.com/v2/local/search/keyword.json?query=BEXCO&size=1"

# Kakao JS 도메인 등록 확인 — "domain mismatched"가 나오면 도메인 미등록
curl -H "Referer: http://localhost:8080/" \
  "https://dapi.kakao.com/v2/maps/sdk.js?appkey=$KAKAO_JS_KEY" | head -c 120
```

---

## 3. 프로젝트 구조

```
hack_idea/
├── README.md                 # 제품 소개 (심사위원용)
├── docs/
│   ├── DEVELOPER.md          # 이 문서
│   ├── USER_GUIDE.md         # 사용자 가이드
│   ├── PLAN.ko.md / PLAN.uz.md   # MVP 계획
│   └── images/               # 스크린샷
├── .vscode/launch.json       # Chrome / Android 실행 구성
└── app/                      # Flutter 앱
    ├── env.example.json      # 키 템플릿 (env.json은 git 제외)
    ├── tool/gen_web_env.dart # env.json → web/kakao_config.js
    ├── web/index.html        # Kakao JS SDK를 Flutter보다 먼저 로드
    ├── lib/
    │   ├── main.dart                 # 앱 진입점, Kakao/Google 초기화
    │   ├── core/                     # theme(디자인 토큰), widgets(공용 UI), router, env, l10n 확장, Kakao SDK 체크
    │   ├── models/models.dart        # 도메인 모델 (RadarEvent, Plan, Insight, TravelRoute…)
    │   ├── data/
    │   │   ├── providers.dart        # Riverpod provider (이벤트, 일정, 인사이트, 날씨, API 클라이언트)
    │   │   ├── interests.dart        # 관심사 목록 + 저장(shared_preferences)
    │   │   ├── session.dart          # 로그인 세션(게스트/Google), 테마, 언어 (저장)
    │   │   ├── calendar_controller.dart  # Google OAuth + 캘린더 동기화
    │   │   └── sample_data.dart      # 샘플 행사·일정·인사이트
    │   ├── services/
    │   │   ├── kakao_api.dart        # Kakao Local(검색) / Mobility(자동차 경로)
    │   │   ├── google_api.dart       # Google Routes TRANSIT, Weather 예보, polyline 디코더
    │   │   ├── calendar_api.dart     # Google Calendar REST v3
    │   │   ├── route_matcher.dart    # 경로 주변 이벤트 매칭 (순수 Dart, 테스트됨)
    │   │   └── insight_engine.dart   # 홈 카드 규칙 엔진 (순수 Dart, 테스트됨)
    │   ├── features/
    │   │   ├── auth/     # 로그인 (Google 버튼: 웹=GIS 공식 버튼 / 그 외=authenticate)
    │   │   ├── onboarding/ # 관심사 선택 (첫 실행 + 수정)
    │   │   ├── profile/  # 프로필 · 설정
    │   │   ├── shell/    # 하단 탭, 언어 버튼, 샘플 배지
    │   │   ├── home/     # 인사이트 카드
    │   │   ├── map/      # Kakao 지도, 레이어, 마커 아이콘
    │   │   ├── route/    # 경로 상태(controller) + 패널 UI + 장소 검색
    │   │   ├── plans/    # 내 일정 + 캘린더 연결 카드
    │   │   ├── discover/ # 행사 목록
    │   │   ├── event/    # 이벤트 상세 바텀시트 (신청, 캘린더 추가)
    │   │   └── weather/  # WeatherChip (일정·행사 날짜의 예보)
    │   └── l10n/         # app_en.arb, app_ko.arb (+ 생성 파일)
    └── test/             # 단위·위젯 테스트
```

---

## 4. 아키텍처와 데이터 흐름

### 상태 관리

- **Riverpod 3** (`Notifier` / `NotifierProvider`) — 화면은 provider를 `watch`하고, 동작은 `notifier`의 메서드를 호출합니다.
- **go_router** `StatefulShellRoute.indexedStack` — 탭을 전환해도 지도 상태가 유지됩니다.

| Provider | 내용 |
|---|---|
| `eventsProvider` | 행사 목록 (현재 샘플 → TourAPI/KOPIS로 교체 예정) |
| `plansProvider` | 내 일정 — 캘린더 연결 전 샘플, 연결 후 실제 일정 |
| `insightsProvider` | `InsightEngine` 결과 (일정·행사·관심사·예보가 바뀌면 자동 재계산) + 피드백 |
| `insightFeedbackProvider` | 카드 id → 👍/👎/숨기기 (shared_preferences 저장) |
| `nowProvider` | "오늘" — 테스트에서 고정 날짜로 override |
| `interestsProvider` | 관심사 태그 — 온보딩에서 선택, `shared_preferences`에 저장 (비어 있으면 온보딩부터 시작) |
| `routeProvider` | 경로 탐색 입력·결과·기회 목록 |
| `calendarProvider` | 캘린더 연결 상태 |
| `mapFocusProvider` | 홈/발견에서 "지도에서 보기" 요청 |
| `forecastProvider` | 위치(약 1 km 반올림)·언어별 10일 예보 캐시 |

### 경로 기반 발견 흐름

```
사용자: 출발/도착/날짜/이동수단 → [경로 주변 기회 찾기]
  │
  ├─ 대중교통: Google Routes (TRANSIT, 09:00 출발) → encoded polyline
  └─ 자동차  : Kakao Mobility directions          → vertexes
  │
  ▼
RouteMatcher.match()
  1) polyline을 ~1 km 간격으로 샘플링
  2) 각 행사 → 경로까지 최단 거리 (선분 투영)
  3) 필터: 경로 15 km 이내 AND 같은 날짜
  4) 점수 = 관심사 일치 0.6 + 근접도 0.4  → 정렬
  │
  ▼  (먼저 결과 표시, 이후 상위 5개 보강)
추가 이동(detour) 계산
  ├─ 자동차  : Kakao A→행사→B − A→B          (waypoint)
  └─ 대중교통: 경로상 최근접 지점(역) ↔ 행사장 왕복 × 2  (Google TRANSIT은 경유지 미지원)
  │
  ▼
지도: 초록 경로선 + 출발/도착 + 기회 마커,  패널: "+7.1 km · +17분"
```

### 캘린더 흐름

```
[Google 캘린더 연결] (사용자 클릭 = 팝업 허용 조건)
  → GoogleSignIn.authorizationClient.authorizeScopes([calendar.events])   (GIS 팝업)
  → access token (메모리, 1시간)
  → Calendar API: 향후 90일 이벤트
  → 장소 텍스트 → Kakao 키워드 검색으로 좌표 (캐시)
  → plansProvider 갱신 → 지도 "내 일정" 레이어 다시 그림
```

---

## 5. 핵심 모듈 설명

### `services/route_matcher.dart`
외부 의존성이 없는 순수 Dart 로직입니다. 테스트하기 쉽고, 나중에 Cloud Functions(TS)로 옮기기 쉽게 분리했습니다.
- `haversineKm`, `distanceToPolylineKm` (등장방형 근사 — 한국 범위에서 충분히 정확), `nearestPointOnPolyline`, `sample`
- 반경·샘플 간격은 생성자 파라미터 (`corridorKm = 15`, `sampleKm = 1.0`)

### `services/insight_engine.dart`
홈 카드를 만드는 **결정적 규칙 엔진** (AI 아님). 카드 id가 규칙+대상으로 고정되어 재계산해도 피드백이 유지됩니다.

| 규칙 | 조건 | 카드 id |
|---|---|---|
| 혼잡 경고 | 일정 기간 + 일정 장소 15 km 이내의 공연/축제 | `crowd:<planId>:<eventId>` |
| 체류 중 기회 | 일정 기간 + 15 km 이내 + 관심사 일치 | `nearby:<planId>:<eventId>` |
| 비 예보 | 일정 당일 강수 확률 ≥ 60% | `rain:<planId>:<y-m-d>` |
| 신청 마감 | 관심사 일치 + 마감 14일 이내 | `deadline:<eventId>` |
| 새 기회 | 위에서 쓰지 않은, 45일 이내 관심사 일치 상위 2개 | `opportunity:<eventId>` |

정렬: 일정 경고 → 마감 → 기회, 같은 그룹은 신뢰도 순. 👎 카드는 맨 아래, 숨긴 카드는 표시 안 함.
Gemini를 붙일 때는 이 결과의 `body/why`만 다시 쓰게 하고, 사실(날짜·거리·행사)은 엔진 값을 그대로 씁니다.

### `services/google_api.dart`
- Routes API `computeRoutes` (TRANSIT). 필요한 필드만 `X-Goog-FieldMask`로 요청합니다.
- `decodePolyline` — Google Encoded Polyline. **웹 호환을 위해 `~x` 대신 `-(x + 1)`** 을 씁니다 ([8장](#8-알려진-함정-gotchas)).

### `services/kakao_api.dart`
- `searchPlaces` — 키워드 검색 (장소 선택, 일정 지오코딩)
- `directions` — 자동차 경로. `withGeometry: false`이면 요약만 받아 detour 계산에 사용

### `data/calendar_controller.dart`
- `connect / sync / addEvent / disconnect`
- 토큰 만료(401) 시 `addEvent`는 한 번 재인증을 시도하고, `sync`는 "다시 연결" 상태로 전환

### `features/map/map_screen.dart`
- 레이어별로 `Poi` 목록을 들고 있다가 `show()/hide()` 로 토글
- 경로/일정 다시 그리기는 `_drawing` Future 체인으로 **순차 실행** (동시 호출로 마커가 중복되는 것을 방지)
- 마커 이미지는 에셋 없이 `MarkerIcons`가 런타임에 그림 (3배 해상도, dp 크기 전달)

---

## 6. 디자인 시스템

모든 화면은 `lib/core/theme.dart`의 토큰과 `lib/core/widgets.dart`의 공용 컴포넌트로 만듭니다. **화면 코드에 hex 색이나 임의 여백을 직접 쓰지 마세요.**

| 토큰 | 내용 |
|---|---|
| `AppPalette` (ThemeExtension) | `background / surface / surfaceAlt / border / text / textMuted / primary / primarySoft / accent / danger / info / skeleton` — 라이트·다크 각각 정의 (본문 대비 ≥ 4.5:1). 사용: `context.palette.primary` |
| `Space` | 4/8dp 리듬: `xs 4 · sm 8 · md 12 · lg 16 · xl 20 · xxl 24 · xxxl 32 · gutter 20` |
| `Radii` | `sm 8 · md 12 · lg 16 · xl 24` |
| `Motion` | `fast 150ms · normal 220ms · slow 320ms`, `Motion.of(context, d)`는 "모션 줄이기"면 0 |
| `AppColors` | 지도 마커 전용 (일정 teal · 추천 amber · 경로 blue) |

공용 컴포넌트: `Shimmer` + `SkeletonBox/SkeletonCard`(로딩), `SectionHeader`, `Pill`(Tone: neutral/primary/accent/danger/info), `MetaRow`, `DateTile`, `IconTile`, `EmptyState`, `AppAvatar`, `GroupCard`, `FadeSlideIn`(목록 등장 애니메이션).

전환: 최상위 화면은 `_fadePage`(페이드+살짝 위로), 탭 간에는 `FadeBranchContainer`(상태 유지 + 페이드). 테스트는 `disableAnimations: true`로 실행해 모션 줄이기 경로도 함께 검증합니다.

## 6-1. 다국어 (i18n)

- 문자열: `lib/l10n/app_en.arb` (템플릿), `app_ko.arb`
- 키를 추가하면 **두 파일 모두** 수정 후 `flutter gen-l10n`
- 코드에서: `context.l10n.키이름`, 데이터 텍스트는 `LocalizedText` + `context.tr(...)`

---

## 7. 테스트와 검증

```bash
flutter analyze                       # 정적 분석 — 이슈 0 유지
flutter test                          # VM 테스트
flutter test --platform chrome test/google_api_test.dart   # 웹(dart2js) 동작 확인이 필요한 로직
```

| 테스트 파일 | 내용 |
|---|---|
| `app_test.dart` | 로그인 → 게스트 → 온보딩 → 홈, 관심사 저장, 프로필에서 언어 전환, 관심사별 발견 순서, 빈 상태, 피드백 저장, 키 없을 때 지도 안내 |
| `route_matcher_test.dart` | 거리 계산, 날짜/반경 필터, 서울→부산 시나리오 |
| `google_api_test.dart` | polyline 디코딩(구글 공식 예제), 최근접 지점 |
| `calendar_api_test.dart` | 시간/종일 일정 파싱 |
| `weather_test.dart` | 일별 예보 파싱, 비 예보 판단 |
| `insight_engine_test.dart` | 규칙별 카드 생성, 중복 방지, 지난 일정 제외 |

**웹 E2E 확인 팁:** 에뮬레이터 대신 `flutter build web` 결과를 헤드리스 Chrome으로 열어 스크린샷을 찍습니다. 웹 전용 버그(예: polyline)는 VM 테스트로 잡히지 않으므로 **웹에서 한 번은 직접 확인**하세요.

---

## 8. 알려진 함정 (Gotchas)

| 증상 | 원인 / 해결 |
|---|---|
| 지도 영역에 "SDK를 불러오지 못했습니다" | Kakao JS SDK 도메인에 현재 origin 미등록. 포트 8080 확인 |
| 웹에서 경로가 이상한 곳에 그려지고 기회 0개 | dart2js에서 `~`(비트 NOT)는 **부호 없는 32비트** 결과 → `-(x + 1)` 사용 |
| Google로 자동차 경로가 안 나옴 | Google은 한국 자동차 길찾기 미지원 → 자동차는 Kakao Mobility |
| 서울→부산 자동차 경로에서 대전 행사가 안 나옴 | 정상. 추천 고속도로는 대전에서 약 68 km 떨어짐 (KTX는 6 km) |
| TMAP `QUOTA_EXCEEDED` | 무료 할당량 매우 작음 → 대중교통은 Google Routes 사용 |
| 캘린더 연결 시 "확인되지 않은 앱" | 테스트 모드 정상 동작. 테스트 사용자로 등록된 계정만 가능 |
| `access_denied` | 해당 Gmail이 테스트 사용자에 없음 |
| 새로고침 후 캘린더 연결이 풀림 | 토큰을 메모리에만 저장(의도된 동작). 다시 연결 |
| Kakao 네이티브 지도가 에뮬레이터에서 안 보임 | x86 미지원. ARM 실기기 사용 |
| 웹 release 빌드만 흰 화면 + `MissingPluginException(getAll … shared_preferences)` | 플러그인 추가 후 `.dart_tool`의 오래된 빌드 캐시가 재사용되어 플러그인이 등록되지 않음 → `flutter clean && flutter pub get` 후 다시 빌드 |
| `Route` 이름 충돌 | Flutter의 `Route`와 Kakao의 `Route` → `import ... as km` 사용 |

---

## 9. 작업 규칙

- **브랜치:** `main`에 직접 커밋하지 않고 `feat/...`, `fix/...`, `docs/...` 브랜치에서 작업 → PR
- **커밋 메시지:** `feat(app): ...`, `fix(route): ...`, `docs: ...` (Conventional Commits)
- **비밀 정보:** 키·비밀번호는 커밋 금지. 커밋 전 `git diff --cached`로 확인
- **샘플 데이터:** `source: 'sample'`로 표시하고 UI에 배지가 보이게 유지 (데모에서 실제 데이터처럼 보이지 않게)
- **AI 원칙:** AI는 코드가 고른 후보만 설명한다. AI가 행사·사실을 만들어내지 않게 한다.

---

## 10. 다음 작업 (TODO)

- [ ] `eventsProvider` → TourAPI(축제) / KOPIS(공연) 실제 데이터, IT 행사는 큐레이션 JSON
- [x] Google Weather 일별 예보 → 내 일정·이벤트 상세·홈 카드에 표시 (`WeatherChip`, 약 10일 범위)
- [x] 인사이트 엔진: 일정 × 행사 × 날씨 × 관심사 (규칙 기반)
- [ ] Gemini로 카드 문장 다듬기 (JSON 출력, 사실은 엔진 값 유지)
- [x] 온보딩: 관심사 선택 → `interestsProvider` (저장·수정 가능). 목표(goal) 입력은 추후
- [ ] Firebase: Firestore 저장, Cloud Functions로 API 키 이전, FCM 푸시
- [ ] Android: Kakao 네이티브 키, Google OAuth Android 클라이언트(SHA-1), 실기기 데모 빌드
