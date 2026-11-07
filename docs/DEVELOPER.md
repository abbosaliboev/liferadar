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

flutter run -d chrome --web-port=8080 --dart-define-from-file=env.json \
  --web-browser-flag="--user-data-dir=$PWD/.dart_tool/chrome-profile"   # 로그인·관심사·일정 유지
```

- **포트는 반드시 8080** — Kakao JavaScript SDK 도메인과 Google OAuth origin이 `http://localhost:8080`으로 등록되어 있습니다.
- VS Code: 실행 구성 **"LifeRadar (Chrome)"** 을 선택하면 위 옵션이 자동으로 들어갑니다 (`.vscode/launch.json`).
- **`--user-data-dir` 플래그**: 없으면 `flutter run`이 매번 **새 임시 Chrome 프로필**로 열어 localStorage(로그인, 관심사, 내가 만든 일정)가 실행할 때마다 사라집니다. `.dart_tool/chrome-profile`은 git에 올라가지 않습니다.
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
| `SEOUL_OPEN_API_KEY` | 실제 행사 수집 (`tool/collect_events.dart` 전용, 앱에는 안 들어감) | [서울 열린데이터광장](https://data.seoul.go.kr) → 회원가입 → 인증키 신청 (일반 인증키, 즉시 발급) | 없으면 `sample` 키로 5건만 수집 |
| `DATA_GO_KR_KEY` | 전국 축제 수집 (TourAPI), 창업 공고 (K-Startup, 예정) — 수집 스크립트 전용 | [공공데이터포털](https://www.data.go.kr) → 데이터별 **활용신청** (자동승인) → 마이페이지 → 일반 인증키 **(Decoding)** | 승인 후 1–2시간 뒤 활성화. 개발계정 일 1,000건 |
| `GEMINI_API_KEY` | 수집 데이터의 영어 번역 + 관심사 태그 (수집 스크립트) · Home 인사이트 문구 작성 (앱, `lib/ai/insight_writer.dart` — 없으면 규칙 문구) | [Google AI Studio](https://aistudio.google.com/apikey) | `AQ.`로 시작하는 새 형식 키는 `?key=` 쿼리로 전달 |
| `GOOGLE_OAUTH_WEB_CLIENT_ID` | Google 로그인 → 캘린더 접근 | Google Auth Platform → 클라이언트 → 웹 애플리케이션 | 승인된 JS 원본 `http://localhost:8080`, 대상 = 테스트 중 + **테스트 사용자 등록**, 범위 `calendar.events` |
| `TMAP_APP_KEY` | (예비) 대중교통 | SK Open API | 무료 할당량이 매우 작아 현재 미사용 |

Android Google 로그인도 `GOOGLE_OAUTH_WEB_CLIENT_ID`를 `serverClientId`로 사용합니다. 같은 Google Cloud 프로젝트에 패키지 `com.liferadar.liferadar`와 APK 서명 인증서의 SHA-1을 등록한 Android OAuth 클라이언트가 필요합니다. Android 클라이언트 ID는 이 환경 변수에 넣지 않습니다.

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
├── .vscode/launch.json       # Chrome(프로필 유지) / Android 실행 구성
└── app/                      # Flutter 앱
    ├── env.example.json      # 키 템플릿 (env.json은 git 제외)
    ├── tool/
    │   ├── gen_web_env.dart      # env.json → web/kakao_config.js
    │   ├── collect_events.dart   # 공공 API 수집 → Gemini 번역·태그 → assets/data/events.json
    │   └── cache/ai_en.json      # Gemini 결과 캐시 (한국어 원문 해시 → 영어·태그)
    ├── assets/
    │   ├── data/events.json      # 실제 행사·축제·공고 (수집 결과, 커밋됨)
    │   └── fonts/                # LifeRadar Sans (Pretendard 서브셋) + OFL.txt
    ├── web/index.html        # HTML 스플래시 + Kakao JS SDK를 Flutter보다 먼저 로드
    ├── lib/
    │   ├── main.dart                 # 진입점: prefs + events.json 로드, Kakao/Google 초기화
    │   ├── core/                     # theme(토큰·Hue·글꼴), widgets(공용 UI·MarqueeText·AppSpinner·Shimmer),
    │   │                             # toast(상단 토스트), router(첫 실행 → 로그인 → 이름 → 관심사), env, l10n 확장
    │   ├── models/models.dart        # 도메인 모델 (RadarEvent+JSON, Plan+JSON, Insight, TravelRoute…)
    │   ├── data/
    │   │   ├── providers.dart        # Riverpod: 행사(실제+샘플), 일정(기본+내 일정), 인사이트, 지도용 상위 행사, 날씨
    │   │   ├── event_feed.dart       # assets/data/events.json 로더
    │   │   ├── interests.dart        # 관심사 26개(그룹·색) + 계정별 저장, accountScope()
    │   │   ├── session.dart          # 세션(게스트/Google), 테마, 언어, setup_done, 이름, nextAfterAuth()
    │   │   ├── seen.dart             # 본 신호/행사 (카드 흐리게)
    │   │   ├── calendar_controller.dart  # Google OAuth + 캘린더 동기화·추가·수정·삭제
    │   │   └── sample_data.dart      # 데모용 샘플 (IT 행사, 일정)
    │   ├── services/
    │   │   ├── kakao_api.dart        # Kakao Local(검색) / Mobility(자동차 경로)
    │   │   ├── google_api.dart       # Google Routes TRANSIT, Weather 예보, polyline 디코더
    │   │   ├── calendar_api.dart     # Google Calendar REST v3 (읽기·추가·PATCH·DELETE)
    │   │   ├── route_matcher.dart    # 경로 주변 이벤트 매칭 (순수 Dart, 테스트됨)
    │   │   ├── insight_engine.dart   # 홈 카드 규칙 엔진 (순수 Dart, 테스트됨)
    │   │   └── sources/              # 수집용 순수 Dart (앱·도구 공용, 테스트됨)
    │   │       ├── seoul_culture.dart    # 서울시 문화행사 파서
    │   │       ├── tour_festival.dart    # TourAPI 축제 파서
    │   │       ├── kstartup.dart         # K-Startup 공고 파서 (placeless)
    │   │       ├── tagger.dart           # 키워드 → 관심사 태그, HTML·좌표 정리
    │   │       └── ai_enrich.dart        # Gemini 프롬프트·스키마·품질 검사·적용
    │   ├── features/
    │   │   ├── welcome/  # 첫 실행: 언어 → 테마
    │   │   ├── auth/     # 로그인 (Google 버튼: 웹=GIS 공식 버튼 / 그 외=authenticate)
    │   │   ├── onboarding/ # 이름(name_screen) + 관심사 선택 (첫 실행 + 수정)
    │   │   ├── profile/  # 프로필 · 설정
    │   │   ├── shell/    # 하단 탭, 샘플 배지
    │   │   ├── home/     # 필터 + 한눈에 읽히는 신호 카드, openSignal()
    │   │   ├── map/      # Kakao 지도, 레이어, 마커 아이콘
    │   │   ├── route/    # 경로 상태(controller) + 패널 UI + 장소 검색
    │   │   ├── plans/    # 내 일정 + 캘린더 연결 카드 + 일정 편집 시트
    │   │   ├── discover/ # 행사 목록 (30개씩 더 보기)
    │   │   ├── event/    # 행사 상세 시트 + SignalWhyBlock(신호 이유)
    │   │   └── weather/  # WeatherChip (일정·행사 날짜의 예보)
    │   └── l10n/         # app_en.arb, app_ko.arb (+ 생성 파일)
    └── test/             # 단위·위젯 테스트 (57개)
```

---

## 4. 아키텍처와 데이터 흐름

### 상태 관리

- **Riverpod 3** (`Notifier` / `NotifierProvider`) — 화면은 provider를 `watch`하고, 동작은 `notifier`의 메서드를 호출합니다.
- **go_router** `StatefulShellRoute.indexedStack` — 탭을 전환해도 지도 상태가 유지됩니다.

| Provider | 내용 |
|---|---|
| `eventsProvider` | 행사 목록 (현재 샘플 → TourAPI/KOPIS로 교체 예정) |
| `plansProvider` | 내 일정 = 기본 소스(캘린더 연결 전 샘플, 연결 후 실제 일정) + 앱에서 직접 만든 일정(`local`, 계정별 저장). 같은 id면 직접 만든 일정이 우선 (수정한 샘플) |
| `insightsProvider` | `InsightEngine` 결과 (일정·행사·관심사·예보가 바뀌면 자동 재계산) + 피드백 |
| `insightFeedbackProvider` | 카드 id → 👍/👎/숨기기 (shared_preferences 저장) |
| `nowProvider` | "오늘" — 테스트에서 고정 날짜로 override |
| `interestsProvider` | 관심사 태그 — 온보딩에서 선택, **계정별**로 `shared_preferences`에 저장 (비어 있으면 온보딩부터 시작) |
| `sessionProvider` | 게스트 / Google 프로필 (이름·이메일·사진만, 토큰 저장 안 함) |
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

### 실제 행사 데이터 파이프라인

```
dart run tool/collect_events.dart [--days=90]
  ├─ 서울 열린데이터광장 culturalEventInfo (1,000건/페이지)
  │    └─ SeoulCulture.parse(): 분류 → 카테고리, 키워드 → 관심사 태그(tagger.dart),
  │       PRO_TIME 자유 텍스트 → 시작/종료 시각, 좌표 검증(lat/lng 뒤바뀜 보정)
  ├─ TourAPI searchFestival2 (오늘-60일부터, 100건/페이지)
  │    └─ 범위 안 축제만 detailCommon2(개요·홈페이지) + detailIntro2(시간·장소·요금·프로그램)
  │       4개씩 병렬, 실패해도 목록 정보로 유지. HTML(<br>, <a href>) 정리, 주소 → "부산 해운대구"
  ├─ K-Startup getAnnouncementInformation01 (cond[rcrt_prgs_yn::EQ]=Y, 500건/페이지)
  │    └─ 공고는 장소가 없음 → placeless=true, start–end = 접수 기간, deadline = 접수 마감,
  │       location = 시·도 중심(내부용). 지도·경로·"근처" 인사이트에서 제외, 마감 알림에만 사용
  ├─ 오늘 ~ +90일 범위만, id로 중복 제거, 시작일 정렬
  ├─ Gemini (gemini-3.5-flash-lite → 실패 시 3.1-flash-lite): 20건씩 구조화 JSON 요청
  │    └─ title_en / description_en / tags(26개 허용 목록 enum) → AiEnrich.apply()
  │       품질 검사: 제목에 한글·가나·한자 있으면 거부, 설명 한글 비율 >15% 거부 → 2단계에서 다른 모델로 재요청
  │       캐시 tool/cache/ai_en.json (한국어 원문 FNV 해시) — 다음 실행은 새 행사만 번역
  └─ assets/data/events.json  (generatedAt, sources[출처·라이선스], events[])

앱 시작: EventFeed.load() → eventFeedProvider → eventsProvider = 실제 + 샘플
```

- **왜 앱에서 직접 호출하지 않나:** 키가 웹 번들에 노출되고, 서울 API는 `http://…:8088`이라 https 배포에서 혼합 콘텐츠로 막히며, CORS도 보장되지 않습니다. 수집 스크립트가 미리 모아 asset으로 넣습니다.
- **데이터 갱신:** 스크립트를 다시 실행하고 `assets/data/events.json`을 커밋합니다.
- **실제 결과 (2026-11-07):** 서울 347건 (교육·체험 129, 전시 91, 콘서트 56, 공연 38, 축제 33) + TourAPI 축제 110건 (전체 451건 중 범위 내, 요청 약 230회) + K-Startup 공고 195건 (접수 중 214건 중 90일 내 마감) = 652건, 약 1.2 MB.
- **진행 중 행사:** 몇 달짜리 전시·강좌는 시작일이 과거입니다. 발견 카드는 종료일(`~12월 31`)과 `진행 중` 배지로, 인사이트 문장은 일정 날짜/오늘 기준(`_on()`)으로 표시합니다.
- **혼잡 경고:** 실제 데이터에는 공연장 규모가 없어서, 작은 홀 공연까지 '혼잡'으로 오인하지 않도록 실제 데이터는 **축제만** 대상입니다.
- **AI 사용 원칙:** Gemini는 **번역과 태그만** 합니다. 날짜·장소·요금 같은 사실은 API 원본 그대로이고, 앱 상세 화면(영어)에 "Gemini로 번역됨"을 표시합니다. 키는 수집 스크립트에서만 쓰여 웹 번들에 노출되지 않습니다.
- **AI 결과 (2026-11-07):** 652건 중 651건 영어화 (나머지 1건은 원래 영어 제목), 첫 실행 약 5분, 이후 캐시로 수십 초. 행사당 평균 태그 2.2개 (키워드 태거 대비 '공연→music' 같은 오탐 감소).
- **마감 카드:** 창업 공고는 수십 건이라 마감 인사이트는 관심사 일치 → 남은 일수 순으로 **최대 3개**. 캘린더에 추가하면 접수 기간 전체가 아니라 **마감일 09:00 알림**으로 들어갑니다.
- **많은 행사 대응:** 발견 탭은 30개씩 "더 보기", 지도 추천 레이어는 30일 내 관심사 상위 60개(`mapEventsProvider`), 인사이트는 일정당 혼잡 1개(실제 데이터는 3 km 이내·3일 이하 공연/축제) + 기회 2개로 제한.
- **출처 표시:** 공공누리 조건에 따라 행사 상세에 `sourceName`과 원문 링크를 표시합니다.
- **사용하지 않는 소스:** [Dev-Event](https://github.com/brave-people/Dev-Event)는 `USAGE_POLICY.md`에서 스크래핑·크롤링, 2차 서비스, 추천 시스템 활용을 금지합니다. 이용약관이 수집을 막는 사이트는 크롤링하지 않습니다.
- **새 소스 추가:** `lib/services/sources/<name>.dart`에 `parse(row) → RadarEvent?`(순수 Dart) + 테스트, `collect_events.dart`에 수집 루프 추가.

### 계정별 로컬 저장

로그아웃 후 같은 Google 계정으로 다시 들어오면 관심사와 일정이 그대로 돌아오고, 다른 사람(게스트·다른 계정)과 섞이지 않도록 키에 계정 범위를 붙입니다.

| 키 | 내용 |
|---|---|
| `session` | 현재 세션 JSON |
| `interests:<scope>` | 관심사 태그 목록 |
| `plans:<scope>` | 앱에서 만든 일정 (JSON 배열) |

`<scope>` = `guest` 또는 `g:<이메일 소문자>` (`accountScope()`). 예전 버전의 `interests` 키는 처음 읽을 때 한 번 옮겨집니다.
기기 간 동기화는 아직 없습니다 (Firebase 도입 시 같은 구조로 옮길 예정).

### 일정 추가·수정 흐름

| 일정 출처 | 수정/삭제 |
|---|---|
| `local` (앱에서 만듦) | 기기에 저장. 편집 화면에서 "Google 캘린더에도 저장"을 켜면 캘린더 이벤트로 옮겨짐 |
| `gcal` | Calendar API `PATCH` / `DELETE` → 다시 동기화 (`CalendarApi.planBody`) |
| `sample` | 저장하면 같은 id의 `local` 일정이 샘플을 대체. 삭제 불가 |

종일 일정은 `date`, 시간 일정은 UTC `dateTime`으로 보냅니다. `PATCH`에서는 반대쪽 필드를 `null`로 보내 종일↔시간 전환이 가능합니다.

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
- `connect / sync / addEvent / savePlan / deletePlan / disconnect`
- 토큰 만료(401) 시 `addEvent`·`savePlan`·`deletePlan`은 한 번 재인증을 시도하고, `sync`는 "다시 연결" 상태로 전환

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

### 내 위치와 일정 화면

- **`myLocationProvider` (`data/location.dart`)**: `geolocator`로 권한 요청 → 현재 위치 → 20 m 이상 이동 시 갱신. 지도가 준비되면 자동 시작, ⌖ 버튼은 권한 재요청 + 카메라 이동. 거부/실패는 토스트. 위치는 저장·전송하지 않음.
- 파란 점은 `MarkerIcons.myLocation()` (앵커 0.5, 0.5, rank 30). 일정 상세의 지도 버튼은 `mapFocusProvider.focus('plan:<id>')`.
- **일정 신호 한 줄 (`plan_signals.dart`)**: 해당 `planId`의 인사이트를 비 → 혼잡 → 근처 기회 순으로. 카드에는 최대 2개, 왼쪽 막대 색 = 가장 중요한 신호 색.
- **월간 달력 (`month_view.dart`)**: 일요일 시작, 종일/여러 날 일정은 `MonthView.covers()`로 모든 날짜에 표시. 보기 선택은 `plans_view`에 저장. 각 칸은 독립 시맨틱 노드("11월 10일, 1").
- **일정 상세 (`plan_detail_sheet.dart`)**: 언제·어디서·날씨·주변 소식·메모 → **수정**은 편집 시트로.

### 알림 · 확인 시트 · 계정 삭제 · 아이콘

- **알림 (`core/notify/`, `data/notifications.dart`)**: 웹 Notification API(`package:web`), 그 외 플랫폼은 stub. 설정 스위치(`notify_enabled`)를 켤 때만 권한 요청. `AppShell`이 `insightsProvider`를 듣고 `SignalNotifier.dispatch()` → 마감 ≤ 2일, 3일 이내 일정의 planAlert만, 신호당 1번(`notified:<scope>`), 한 번에 최대 3개. 문구는 `lookupAppLocalizations()`로 현재 언어.
  - 한계: 탭이 열려 있어야 함. 앱이 닫혀 있을 때의 푸시는 FCM + 서버(Cloud Functions) + 서비스 워커 필요.
  - 헤드리스 검증: CDP `Browser.grantPermissions(['notifications'])` + `Page.addScriptToEvaluateOnNewDocument`로 `Notification` 생성자를 감싸 콘솔에 기록.
- **행사 상세 구성**: 포스터 → 조용한 분류 줄 + 제목 → **한눈에 카드**(`_FactsCard`: 언제·어디서(지도 버튼)·요금·마감 D-n, 공고는 접수 기간·주관) → 신호 이유(`SignalWhyBlock`: 신호 종류 색의 연한 배경, 테두리·왼쪽 선 없음, 한 문장 + 이유) → 소개(6줄 + 더 보기) → 내 관심사(조용한 태그) → 출처·번역 표시.
- **상세 시트 (`DetailSheet`, `core/widgets.dart`)**: 행사·일정 상세 공용. 루트 내비게이터에 화면 92% 높이로 열리고(하단 탭까지 덮음), 상단 핸들/← 영역을 위로 끌면 95%까지(전체 화면은 아님), 아래로 끌면 닫힘. ← 뒤로 버튼은 항상 보임. 모션 줄이기에서는 `animateTo` 대신 `jumpTo`(duration 0 assertion 방지).
- **확인 시트 (`core/confirm.dart`)**: `showConfirm()` — 루트 내비게이터 바텀시트(하단 탭까지 덮음), 아이콘 elastic pop, 두 개의 큰 버튼, `destructive`면 빨강. 👎, 👍/👎 취소, 일정 삭제, 계정 삭제에서 사용.
- **👍/👎 토글**: 같은 버튼을 다시 누르면 확인 후 `InsightFeedbackController.clear()`.
- **계정 삭제 (`deleteAccountAndData`)**: 캘린더 토큰 해제 → Google `disconnect()` → `SharedPreferences.clear()` → 관련 provider invalidate → `/welcome`. 위치: 프로필 → 정보 → 계정 및 데이터 (`/account`).
- **토스트**: 상단에서 56dp 아래, pill 모양, `easeOutBack` 진입(살짝 튕김) + 남은 시간 막대.
- **앱 아이콘**: 원본 `docs/brand/app-icon-source.png`(검은 배경) → 스퀘어클 마스크(4x 슈퍼샘플링, 반경 265/1040)로 투명 처리한 `docs/brand/app-icon.png`에서 `web/icons/*`, `web/favicon.png`, maskable(80% 안전 영역), Android `mipmap-*/ic_launcher.png` 생성.

### 첫 실행 흐름과 글꼴

```
/welcome (언어 → 테마, 즉시 적용, setup_done 저장 — 기기 단위)
  → /login (Google 또는 게스트)
  → /name (name:<scope>, Google 이름 미리 채움)  → /onboarding (interests:<scope>)  → /home
```
- 다음 단계는 `nextAfterAuth()` 한 곳에서 결정합니다 (이름 → 관심사 → 홈). 둘 다 있으면 로그인 후 바로 홈.
- **글꼴 `LifeRadarSans`**: Pretendard 1.3.9를 라틴 + KS X 1001 한글 2,350자로 서브셋(400/600/700, 약 1.35 MB). OFL의 Reserved Font Name 조항 때문에 이름을 바꿨고 `assets/fonts/OFL.txt`에 원 저작권을 둡니다. 서브셋 밖의 드문 음절은 Noto Sans KR로 자동 대체됩니다.
- **로딩 화면**: `web/index.html`의 HTML 스플래시(브랜드 색, 다크 모드, 모션 줄이기 대응)가 `flutter-first-frame` 이벤트에서 사라집니다.
- **스피너**는 `AppSpinner` 하나로 통일 (둥근 끝, 브랜드 색 + 연한 트랙).
- 한국어 문장은 Flutter가 글자 단위로 줄바꿈하므로, 짧은 안내문은 `\n`으로 의미 단위 줄바꿈을 넣습니다.

### 색 사용 원칙 — 관심사 태그

- **고를 때만 색**: 온보딩/관심사 수정 화면의 `InterestChip`은 관심사별 색(`Hue`)으로 구분을 돕습니다.
- **카드에서는 조용히**: 홈·발견 카드의 관심사는 `QuietTags` — 배경·테두리 없이 회색 아이콘 + 글자, `·`로 구분, 한 줄. 카드의 주인공은 제목·시간·장소이고 태그는 보조 정보이기 때문입니다.

### 홈 카드 · 토스트 · 읽음 표시

- **신호 카드 (`InsightCard`)**: 무엇(`MarqueeText` — 넘치면 가로로 흐름, 모션 줄이기에선 말줄임) · 언제 · 어디서 · 관심사 칩 최대 2개 · D-n. 본문·이유·신뢰도·출처는 카드에 없고 탭하면 `openSignal()` → 행사 시트의 `SignalWhyBlock` (행사 없는 신호는 단독 시트).
- **유리 컴포넌트 (`GlassSurface`, `GlassSegmented`, `core/widgets.dart`)**: 블러 + 반투명(라이트 0.62 / 다크 0.55) + 밝은 얇은 테두리 + 그림자. 홈 필터, 지도 모드 전환·레이어 칩·원형 버튼에 공통 사용.
- **지도 다크 모드**: Kakao JS 지도에는 다크 테마가 없어서, 다크일 때 `<html class="lr-dark-map">`(`core/map_theme/`)을 켜고 `web/index.html` CSS로 **타일 이미지(`mts.kakaocdn.net`)에만** `invert + hue-rotate` 필터를 적용합니다. 마커(data: 이미지)와 컨테이너는 필터하지 않고 배경색만 바꿉니다(컨테이너에 필터를 걸면 마커까지 어두워짐). Android 네이티브는 아직 라이트.
- **하단 탭 (`GlassTabBar`, `shell/app_shell.dart`)**: iOS "liquid glass" 스타일의 떠 있는 캡슐(블러 22, 반투명, 그림자). 선택 탭은 안쪽 캡슐이 `easeOutBack`으로 미끄러지고 아이콘이 살짝 커짐. 홈 탭에는 아직 열어 보지 않은 신호 수 빨간 배지(9+). `Scaffold(extendBody: true)` — 콘텐츠가 탭 아래로 지나가므로 각 화면 스크롤 하단 여백에 `MediaQuery.paddingOf(context).bottom`을 더합니다.
- **필터 (`HomeFilter`, `_FilterHeader`)**: 상단 숫자 3개 = 내 일정 / 전체(기본) / 마감 임박(마감일 순). `SliverPersistentHeader(pinned)` — 맨 위에선 큰 숫자 카드, 스크롤하면 `shrinkOffset`에 따라 하단 탭과 같은 **유리 캡슐**(아이콘 + 라벨 + 아이콘 모서리 배지, 마감 임박은 빨강). 스크롤해도 거의 줄어들지 않고(104→92), 위에서 14px 띄워 고정되며 더 투명해져 뒤 카드가 비침로 변하며 고정. 선택 표시는 미끄러지는 인디케이터(`AnimatedAlign`).
- **좌우 스와이프**: 목록을 옆으로 밀면(속도 > 250) 이전/다음 필터, 카드는 같은 방향으로 슬라이드 전환 + 햅틱.
- **👎 확인**: 예/아니요 다이얼로그 후 저장.
- **토스트 (`core/toast.dart`)**: `Toast.show(msg, type:)` — `GoRouter(navigatorKey: Toast.navigatorKey)`의 루트 오버레이에 위에서 내려옴, 아이콘 없음, 탭/위로 밀어 닫기. 색은 상태별(success 초록 `#15803D`, error, warning, info), 흰 글자와 4.5:1 이상. `SnackBar`는 쓰지 않습니다.
- **읽음 (`seenProvider`)**: `insight:<id>`, `event:<id>`를 계정별 최근 500개 저장 → 홈·발견 카드 불투명도 0.6.

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
| `app_test.dart` | 첫 실행(언어 → 테마 저장), 로그인 → 게스트 → 이름 → 관심사 → "Hi, Abbos", 재로그인 시 바로 홈, 프로필 언어 전환, 발견 순서, 홈 필터(마감 임박), 본 카드 흐리게, 👎 확인 다이얼로그 + 토스트, 키 없을 때 지도 안내 |
| `plans_test.dart` | 계정별 관심사(재로그인 복원, 마이그레이션), 일정 추가·수정·삭제·저장, 샘플 대체, Calendar 요청 본문, "+ 새 일정" UI, 프로필 관심사 요약 |
| `sources_test.dart` | 서울·TourAPI·K-Startup 파서(시간·좌표·HTML·무료), 태거 오탐 방지, JSON 왕복, 인사이트 상한·축제만 혼잡·진행 중 행사 날짜·공고는 "근처" 제외 |
| `ai_enrich_test.dart` | Gemini 요청 스키마(태그 enum), 응답 파싱, 품질 검사(한글·가나 거부), 적용(사실 유지) |
| `route_matcher_test.dart` | 거리 계산, 날짜/반경 필터, 서울→부산 시나리오 |
| `google_api_test.dart` | polyline 디코딩(구글 공식 예제), 최근접 지점 |
| `calendar_api_test.dart` | 시간/종일 일정 파싱 |
| `weather_test.dart` | 일별 예보 파싱, 비 예보 판단 |
| `insight_engine_test.dart` | 규칙별 카드 생성, 중복 방지, 지난 일정 제외 |

테스트는 `FakeAccessibilityFeatures(disableAnimations: true)`로 돌립니다 — 무한 애니메이션(레이더, 마키, 쉬머)이 멈추고, 앱이 모션 줄이기를 지키는지도 함께 확인됩니다.

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
| `MissingPluginException` (예: `getAll … shared_preferences`, `isLocationServiceEnabled … geolocator`) | **플러그인을 추가한 뒤** `.dart_tool`의 오래된 빌드 캐시가 재사용되어 웹 플러그인이 등록되지 않음 → `flutter clean && flutter pub get && dart run tool/gen_web_env.dart` 후 다시 빌드/실행 (핫 리스타트로는 안 됨) |
| 실행할 때마다 다시 로그인·관심사 선택 | `flutter run -d chrome`의 임시 프로필 → `--web-browser-flag="--user-data-dir=..."` (1장 참고) |
| 디버그에서만 화면이 깨짐 (`A circle cannot have a border radius`) | `BoxDecoration.copyWith(borderRadius: null)`은 radius를 **지우지 않음** → 새 `BoxDecoration` 작성. release에서는 assert가 꺼져 안 보이므로 디버그로도 확인 |
| 테스트에서 `RenderAnimatedSize was mutated in its own performLayout` | 모션 줄이기에서 `AnimatedSize(duration: 0)` → `SmoothSize` 위젯 사용 |
| Gemini `404 … no longer available to new users` | 새 계정은 구형 모델 사용 불가 → `models` 목록에서 사용 가능한 모델 선택 (현재 `gemini-3.5-flash-lite`) |
| Gemini `503 high demand` | 상위 모델(3.8-flash 등) 혼잡. lite 모델 + 재시도/백오프 사용 |
| 셸 `curl`로 한글 프롬프트 테스트 시 빈 응답 | 셸 인용 문제. Python/Dart로 요청하면 정상 |
| data.go.kr `SERVICE_KEY_IS_NOT_REGISTERED_ERROR` | 해당 API에 활용신청이 안 됐거나, 승인 직후(1–2시간) 아직 동기화 전 |
| 서울 API `INFO-100` | 인증키 오류. `sample` 키는 5건까지만 |
| 웹에서 행사 포스터가 안 보임 | 외부 이미지 서버에 CORS 헤더가 없음 → `Image.network(webHtmlElementStrategy: fallback)`로 `<img>` 사용 |
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

- [x] 실제 데이터: 서울 문화행사 · TourAPI 축제 · K-Startup 공고 (`tool/collect_events.dart`)
- [x] Gemini: 수집 단계 영어 번역 + 관심사 태그 (품질 검사·캐시)
- [x] Google Weather 일별 예보 → 일정·행사·홈 카드 (`WeatherChip`, 약 10일 범위)
- [x] 인사이트 엔진: 일정 × 행사 × 날씨 × 관심사 (규칙 기반, 실제 데이터용 상한)
- [x] 첫 실행(언어·테마) → 로그인 → 이름 → 관심사, 계정별 저장
- [x] 일정 추가·수정·삭제 (로컬 + Google 캘린더 PATCH/DELETE)
- [ ] KOPIS 공연 데이터 (키 발급 대기)
- [ ] 웹 배포 + Kakao/Google OAuth에 배포 도메인 등록 (심사용 링크)
- [ ] 👍/👎 피드백을 추천 점수에 반영
- [ ] Gemini로 카드 문장 다듬기 — 키를 숨길 서버(Cloud Functions) 필요
- [x] 웹 시스템 알림(설정에서 켜기/끄기), 계정 삭제, 앱 아이콘
- [ ] Firebase: 기기 간 동기화(Firestore), API 키 이전, FCM 푸시(앱이 닫혀 있어도)
- [ ] Android: Kakao 네이티브 키, Google OAuth Android 클라이언트(SHA-1), 실기기 데모 빌드
