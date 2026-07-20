# Football Dice — 버전별 변경 사항 / Release Notes

---

## v1.2.0 (2026-07-20)

### Play Console 릴리즈 노트 (What's new)

**한국어 (500자 이하)**
```
설정 화면이 새로 생겼습니다!

- 언어, 주사위·카드 연출, 효과음 설정을 메인 화면에서 별도 설정 페이지로 이동
- 메인 화면 우상단 톱니바퀴 아이콘으로 접근
- 메인 화면 구성이 더 단순해졌습니다
```

**English (500 chars max)**
```
A brand-new Settings screen!

- Language, dice/card animation, and sound settings moved to a dedicated Settings page
- Access it via the gear icon at the top right of the main screen
- The main screen is now simpler and cleaner
```

### 변경 사항 / Changes
- 언어(한국어/English), 주사위·카드 연출, 효과음 설정을 메인 화면에서 별도 설정 페이지(SettingsScreen)로 이동
- 메인 화면 우상단에 설정 아이콘 추가, 난이도 선택과 주요 버튼만 남겨 화면 단순화
- 설정 화면에서 언어를 바꾸면 메인 화면으로 돌아올 때 즉시 반영

### 빌드
- versionCode: 3
- versionName: 1.2.0
- AAB: `~/Documents/workspace/apk_build_files/football_dice/v1.2.0/app-release.aab`

---

## v1.1.0 (2026-07-19)

### Play Console 릴리즈 노트 (What's new)

**한국어 (500자 이하)**
```
친구와 대전이 더 팽팽해졌습니다!

- 네트워크 대전에 15초 턴 제한 추가 — 5초 남으면 카운트다운 표시
- 시간이 지나면 자동으로 진행 (공격/수비: 추천 카드, 킥오프: 일반 킥, 리턴: 터치백, 추가 득점: 킥)
- 게임 방법에 주사위·차트 읽는 법 시각 예시 추가
```

**English (500 chars max)**
```
Friend matches just got more intense!

- 15-second turn limit in network games — a countdown appears at 5 seconds
- When time runs out the game picks for you (offense/defense: suggested card, kickoff: normal kick, return: touchback, extra point: kick)
- How to Play now includes a visual dice & chart example
```

### 변경 사항 / Changes
- 친구와 대전(로컬 Wi-Fi)에서 매 선택마다 15초 제한 시간 적용, 5초부터 빨간 카운트다운 표시
- 시간 초과 시 자동 선택으로 게임이 멈추지 않고 진행
- 게임 방법 다이얼로그에 실제 게임 위젯을 재사용한 주사위 4개 → 차트 교차점 예시(숏 패스 카드) 추가
- 게임 방법에 시간 제한 규칙 안내 추가 (한국어/영어)

### 빌드
- versionCode: 2
- versionName: 1.1.0
- AAB: `~/Documents/workspace/apk_build_files/football_dice/v1.1.0/app-release.aab`

---

## v1.0.0 (2026-07-11)

### Play Console 릴리즈 노트 (What's new)

**한국어 (500자 이하)**
```
Football Dice 첫 출시!

- 주사위와 카드로 승부하는 미식축구 보드게임
- 쉬움·보통·어려움 3단계 AI 대전
- 같은 Wi-Fi에서 친구와 로컬 멀티플레이
- 전체 공격·수비 플레이북 열람
- 한국어·영어 지원
- 주사위·카드 연출, 효과음 켜고 끄기
```

**English (500 chars max)**
```
Football Dice launches!

- A tabletop-style American football board game resolved by dice and cards
- Play against AI on Easy, Normal, or Hard difficulty
- Local multiplayer with a friend over the same Wi-Fi network
- Browse the full offense and defense playbook
- Korean and English support
- Toggle dice/card animations and sound effects independently
```

### 주요 기능 / Key Features
- 공격/수비 카드 매치업 + 주사위 판정 엔진
- 4쿼터(쿼터당 16플레이) 게임 진행, 다운·거리·시간 관리
- 킥오프/온사이드킥, 펀트(롱/숏), 필드골, 2점 컨버전 등 실제 미식축구 룰 반영
- AI 난이도별 수비 전략 조정 (Easy / Normal / Hard)
- 로컬 Wi-Fi 소켓 기반 친구 대전 (호스트/참가)
- 전체 플레이북 열람 (추천 3장 외 카드 자유 선택)
- 한국어/영어 다국어 지원
- 주사위·카드 연출, 효과음 개별 온오프 토글
- 라이트/다크 대응 앱 아이콘 및 스플래시

### 빌드
- versionCode: 1
- versionName: 1.0.0
- AAB: `~/Documents/workspace/apk_build_files/football_dice/v1.0.0/app-release.aab`
