/// 다국어 문자열 (한국어/영어).
///
/// UI와 엔진 모두 전역 [loc]을 통해 문자열을 얻는다.
/// 위젯에 의존하지 않는 순수 Dart 파일.
library;

enum AppLanguage { ko, en }

/// 현재 언어의 문자열 묶음 (기본: 한국어)
L10n loc = const L10nKo();

void setLanguage(AppLanguage lang) {
  loc = lang == AppLanguage.ko ? const L10nKo() : const L10nEn();
}

abstract class L10n {
  const L10n();
  AppLanguage get lang;

  /// 카드 설명. ko는 카드 데이터의 원문을 그대로 쓰고, en은 번역 맵에서 찾는다.
  String cardDescription(String id, String koDescription);

  /// 차트 카드 표시 이름 (ko: koName, en: name)
  String chartName(String name, String koName);

  // ---- 메인 메뉴 ----
  String get appSubtitle;
  String get newGame;
  String get howToPlay;
  String get howToPlayBody;
  String get howToPlayBody2;
  String get howToPlayExampleTitle;
  String get howToPlayExampleDice;
  String get howToPlayExampleResult;
  String get close;
  String get difficultyEasy;
  String get difficultyNormal;
  String get difficultyHard;
  String get effectsLabel;
  String get soundLabel;
  String get cardInfoTooltip;

  // ---- 멀티플레이 ----
  String get mpButton;
  String get mpTitle;
  String get hostGame;
  String get hostGameDesc;
  String get joinGame;
  String get joinGameDesc;
  String get waitingForFriend;
  String yourIp(String ip);
  String get searchingHosts;
  String get manualIpHint;
  String get connectButton;
  String get connectionFailed;
  String get connectionLost;
  String get opponentWaiting;
  String get opponentTurn;
  String youLabel(String team);
  String friendLabel(String team);
  String get oppOffenseLabel;
  String get oppDefenseLabel;
  String oppRevealDefense(String name);
  String oppRevealOffense(String name);
  String defensePanelTitleMp(int down, int yards);
  String get defenseTwoPointTitleMp;
  String get timeUpAutoPick;

  // ---- 스코어보드 / 공용 ----
  String get homeTeamLabel;
  String get awayTeamLabel;
  String downAndDistance(int down, int yards);
  String get offD10Label;
  String get defD10Label;
  String get myOffenseLabel;
  String get aiOffenseLabel;
  String get myDefenseLabel;
  String get aiDefenseLabel;
  String get matchupTitle;
  String get matchupHint;
  String get chartLegend;
  String get passModifiers;
  String get runModifiers;

  // ---- 게임 화면 ----
  String aiRevealDefense(String name);
  String aiRevealOffense(String name);
  String aiPuntChoice(bool long);
  String get aiFieldGoal;
  String get aiExtraKick;
  String aiTwoPoint(String name);
  String get welcome;
  String get viewCards;
  String get viewChart;
  String get aiThinking;
  String get kickoffTitle;
  String get kickoffButton;
  String get onsideButton;
  String get returnTitle;
  String get returnButton;
  String get touchbackButton;
  String get twoPointPanelTitle;
  String offensePanelTitle(int down, int yards);
  String suggestion(String situation);
  String get situationTwoPoint;
  String get situationGoalLine;
  String get situationShort;
  String get situationMedium;
  String get situationLong;
  String offenseSubtitle(bool isPass, double avgYards);
  String get fullPlaybook;
  String get fullDefense;
  String get longPuntButton;
  String get shortPuntButton;
  String get playButton;
  String get execButton;
  String get defendButton;
  String defensePanelTitle(int down, int yards);
  String get defenseTwoPointTitle;
  String get offensePlaybookTitle;
  String get longPressHint;
  String get extraPointTitle;
  String get extraKickButton;
  String get twoPointButton;
  String get gameOverTitle;
  String get drawMessage;
  String get winMessage;
  String get loseMessage;

  // ---- 엔진 로그 ----
  String coinToss(String team);
  String kickFallback(int yards);
  String kickoffLine(String team, int yards);
  String get endzoneChoiceKickoff;
  String onsideFail(String team);
  String onsideBackward(int yards);
  String onsideSuccess(int yards, String team);
  String touchbackLine(String team);
  String kickoffReturnFumble(int yards);
  String kickoffReturnLine(String team, int yards);
  String playHeader(String team, String off, String def);
  String penaltyOffset(int offD10, int defD10);
  String defenseMod(int mod, int from, int to);
  String gain(int yards);
  String loss(int yards);
  String penaltyOnOffense(int yards);
  String penaltyOnDefense(int yards);
  String get penaltyFirstDown;
  String repeatDown(int down);
  String interception(int yards);
  String get fumbleAtLine;
  String turnoverJudge(String cell);
  String returnFumble(int yards);
  String returnGain(String team, int yards);
  String fumbleRecovered(String team);
  String fumbleLost(String team);
  String puntFallback(int yards);
  String puntLine(String team, String puntName, int yards);
  String get endzoneChoicePunt;
  String puntReturnLine(String team, int yards);
  String fgSuccess(int distance);
  String get fgFumble;
  String fgFail(int distance);
  String takeoverAtSpot(String team);
  String get extraKickSuccess;
  String get extraKickFail;
  String twoPointAttempt(String off, String def);
  String conversionFailTurnover(bool isInterception);
  String get twoPointSuccess;
  String conversionFailShort(int yards);
  String touchdown(String team);
  String safety(String team);
  String scoreLine(int home, int away);
  String suddenDeathWin(String team);
  String firstDownLine(String team, int toFirst, int toGoal);
  String get firstDownRenewed;
  String downsExhausted(String team);
  String nextDown(int down, int yards);
  String halftime(String team);
  String quarterEnd(int prev, int next);
  String gameEnd(String team, int home, int away);
  String get tieOvertime;
  String drawLine(int home, int away);
}

// ---------------------------------------------------------------------------
// 한국어
// ---------------------------------------------------------------------------

class L10nKo extends L10n {
  const L10nKo();

  @override
  AppLanguage get lang => AppLanguage.ko;

  @override
  String cardDescription(String id, String koDescription) => koDescription;

  @override
  String chartName(String name, String koName) => koName;

  @override
  String get appSubtitle => '미식축구 보드게임 · AI 대전';
  @override
  String get newGame => '새 게임';
  @override
  String get howToPlay => '게임 방법';
  @override
  String get close => '닫기';
  @override
  String get difficultyEasy => '쉬움';
  @override
  String get difficultyNormal => '보통';
  @override
  String get difficultyHard => '어려움';
  @override
  String get effectsLabel => '주사위·카드 연출';
  @override
  String get soundLabel => '효과음';
  @override
  String get cardInfoTooltip => '선택한 카드 정보';

  @override
  String get mpButton => '친구와 대전 (같은 Wi-Fi)';
  @override
  String get mpTitle => '친구와 대전';
  @override
  String get hostGame => '방 만들기';
  @override
  String get hostGameDesc => '내가 방을 만들고 친구를 기다립니다';
  @override
  String get joinGame => '참가하기';
  @override
  String get joinGameDesc => '친구가 만든 방에 들어갑니다';
  @override
  String get waitingForFriend => '친구를 기다리는 중...\n친구 폰에서 [참가하기]를 눌러주세요';
  @override
  String yourIp(String ip) => '내 주소: $ip';
  @override
  String get searchingHosts => '같은 Wi-Fi에서 방을 찾는 중...';
  @override
  String get manualIpHint => '호스트 IP 직접 입력 (예: 192.168.0.5)';
  @override
  String get connectButton => '연결';
  @override
  String get connectionFailed => '연결에 실패했습니다. 같은 Wi-Fi인지 확인해주세요.';
  @override
  String get connectionLost => '연결이 끊어졌습니다';
  @override
  String get opponentWaiting => '상대의 카드 선택을 기다리는 중...';
  @override
  String get opponentTurn => '상대 차례입니다...';
  @override
  String youLabel(String team) => '나 ($team)';
  @override
  String friendLabel(String team) => '친구 ($team)';
  @override
  String get oppOffenseLabel => '상대 공격';
  @override
  String get oppDefenseLabel => '상대 수비';
  @override
  String oppRevealDefense(String name) => '상대 수비: $name';
  @override
  String oppRevealOffense(String name) => '상대 공격: $name';
  @override
  String defensePanelTitleMp(int down, int yards) =>
      '수비 게임플랜 — 상대의 $down번째 다운 ($yards야드)';
  @override
  String get defenseTwoPointTitleMp => '상대의 2점 컨버전 — 수비 대형을 선택하세요';
  @override
  String get timeUpAutoPick => '시간 초과! 자동으로 선택했습니다';

  @override
  String get howToPlayBody => '🏈 목표\n'
      '4쿼터(쿼터당 16플레이) 동안 상대보다 많은 점수를 얻으세요.\n\n'
      '📋 진행\n'
      '· 공격팀은 4번의 다운 안에 10야드를 전진해야 합니다.\n'
      '· 공격 카드(패스/러닝)와 수비 카드를 서로 몰래 선택하고, '
      '주사위를 굴려 카드 차트에서 결과를 확인합니다.\n'
      '· 수비 카드는 공격 플레이 종류별로 주사위에 보정치를 줍니다. '
      '상대의 수를 읽는 심리전이 핵심!\n\n'
      '🎲 주사위 4개 읽는 법\n'
      '결과는 공격 카드 뒷면의 차트(5행×10열)에서 행과 열을 짚어 정해집니다.\n'
      '· 공격 D10(빨강): 차트의 행(세로)을 결정합니다. '
      '수비 카드의 보정치(-3~+3)를 받아 조정됩니다. 높을수록 유리!\n'
      '· 수비 D10(파랑): 반칙 판정 전용. 양팀 D10 합이 6 또는 16이면 '
      '패널티가 발생합니다. (단, 두 주사위가 같은 눈이면 상쇄)\n'
      '· D12 두 개(보라): 양팀이 하나씩 굴려 합(2~24)으로 차트의 '
      '열(가로)을 결정합니다.';

  @override
  String get howToPlayExampleTitle => '📖 예시 — 숏 패스 카드';
  @override
  String get howToPlayExampleDice =>
      '공격 D10 9 − 수비 보정 2 = 7 → "7-8" 행\nD12 합 6+8=14 → "13-15" 열';
  @override
  String get howToPlayExampleResult =>
      '교차점은 6 → 6야드 전진!\n판정 후 "차트 보기"를 누르면 이렇게 짚은 칸이 표시됩니다.';

  @override
  String get howToPlayBody2 => '🎯 득점\n'
      '· 터치다운: 6점 (+추가 킥 1점 또는 2점 컨버전 2점)\n'
      '· 필드골: 3점 (59야드 이내에서 시도 가능)\n'
      '· 세이프티: 2점\n\n'
      '⚡ 특수 상황\n'
      '· 4번째 다운에 전진이 어려우면 펀트로 상대를 밀어내세요.\n'
      '· 인터셉트/펌블이 나오면 공격권이 넘어갈 수 있습니다.\n'
      '· 양팀 10면체 주사위 합이 6 또는 16이면 패널티!\n\n'
      '⏱ 친구와 대전 시간 제한\n'
      '· 네트워크 대전에서는 매 선택마다 15초의 제한 시간이 있습니다.\n'
      '· 5초가 남으면 카운트다운이 표시됩니다.\n'
      '· 시간이 지나면 자동으로 진행됩니다 (공격/수비: 추천 카드, '
      '킥오프: 일반 킥, 리턴: 터치백, 추가 득점: 킥).\n\n'
      '💡 팁\n'
      '카드를 길게 누르면 상세 차트와 보정치를 볼 수 있습니다.';

  @override
  String get homeTeamLabel => '나 (HOME)';
  @override
  String get awayTeamLabel => 'AI (AWAY)';
  @override
  String downAndDistance(int down, int yards) => '$down번째 다운 · $yards야드';
  @override
  String get offD10Label => '공격 D10';
  @override
  String get defD10Label => '수비 D10';
  @override
  String get myOffenseLabel => '내 공격';
  @override
  String get aiOffenseLabel => 'AI 공격';
  @override
  String get myDefenseLabel => '내 수비';
  @override
  String get aiDefenseLabel => 'AI 수비';
  @override
  String get matchupTitle => '이번 플레이 매치업';
  @override
  String get matchupHint => '카드를 탭하면 상세 정보를 볼 수 있어요';
  @override
  String get chartLegend => '행: 공격 D10(수비 보정 후) · 열: 양팀 D12 합';
  @override
  String get passModifiers => '패스 플레이 보정';
  @override
  String get runModifiers => '러닝 플레이 보정';

  @override
  String aiRevealDefense(String name) => 'AI 수비: $name';
  @override
  String aiRevealOffense(String name) => 'AI 공격: $name';
  @override
  String aiPuntChoice(bool long) => 'AI가 ${long ? '롱' : '숏'} 펀트를 선택했습니다';
  @override
  String get aiFieldGoal => 'AI가 필드골을 시도합니다';
  @override
  String get aiExtraKick => 'AI가 추가 킥을 선택했습니다';
  @override
  String aiTwoPoint(String name) => 'AI가 2점 컨버전 시도: $name';
  @override
  String get welcome => '풋볼 다이스에 오신 것을 환영합니다!';
  @override
  String get viewCards => '카드 보기';
  @override
  String get viewChart => '차트 보기';
  @override
  String get aiThinking => 'AI 진행 중...';
  @override
  String get kickoffTitle => '킥오프 — 어떻게 찰까요?';
  @override
  String get kickoffButton => '킥오프';
  @override
  String get onsideButton => '온사이드 킥 (공격권 유지 도박)';
  @override
  String get returnTitle => '공이 엔드존에 들어왔습니다';
  @override
  String get returnButton => '리턴!';
  @override
  String get touchbackButton => '터치백 (20야드에서 시작)';
  @override
  String get twoPointPanelTitle => '2점 컨버전 — 플레이를 선택하세요';
  @override
  String offensePanelTitle(int down, int yards) =>
      '공격 게임플랜 — $down번째 다운 · $yards야드';
  @override
  String suggestion(String situation) => '추천: $situation';
  @override
  String get situationTwoPoint => '2점 컨버전';
  @override
  String get situationGoalLine => '골라인 상황';
  @override
  String get situationShort => '짧은 거리 (Short)';
  @override
  String get situationMedium => '중간 거리 (Medium)';
  @override
  String get situationLong => '긴 거리 (Long)';
  @override
  String offenseSubtitle(bool isPass, double avgYards) =>
      '${isPass ? '패스' : '러닝'} · 평균 ${avgYards}yd';
  @override
  String get fullPlaybook => '전체 플레이북';
  @override
  String get fullDefense => '전체 수비 대형';
  @override
  String get longPuntButton => '롱 펀트';
  @override
  String get shortPuntButton => '숏 펀트';
  @override
  String get playButton => '플레이!';
  @override
  String get execButton => '실행!';
  @override
  String get defendButton => '수비!';
  @override
  String defensePanelTitle(int down, int yards) =>
      '수비 게임플랜 — AI의 $down번째 다운 ($yards야드)';
  @override
  String get defenseTwoPointTitle => 'AI의 2점 컨버전 — 수비 대형을 선택하세요';
  @override
  String get offensePlaybookTitle => '전체 공격 플레이북';
  @override
  String get longPressHint => '길게 누르면 상세 정보를 볼 수 있어요';
  @override
  String get extraPointTitle => '터치다운! 추가 득점을 선택하세요';
  @override
  String get extraKickButton => '추가 킥 (+1점, 성공률 높음)';
  @override
  String get twoPointButton => '2점 컨버전 (+2점, 2야드 돌파)';
  @override
  String get gameOverTitle => '경기 종료';
  @override
  String get drawMessage => '무승부!';
  @override
  String get winMessage => '🎉 승리했습니다!';
  @override
  String get loseMessage => '아쉽게 패배했습니다...';

  @override
  String coinToss(String team) => '동전 던지기: $team 팀이 킥오프합니다.';
  @override
  String kickFallback(int yards) => '킥이 불안했지만 평균 거리 $yards야드로 처리합니다.';
  @override
  String kickoffLine(String team, int yards) => '$team 킥오프: $yards야드';
  @override
  String get endzoneChoiceKickoff => '공이 엔드존에 도달했습니다. 리턴 또는 터치백을 선택하세요.';
  @override
  String onsideFail(String team) => '온사이드 킥 실패! $team 팀이 공을 확보했습니다.';
  @override
  String onsideBackward(int yards) =>
      '온사이드 킥이 뒤로 굴렀습니다! $yards야드 후퇴. 그래도 공격권은 유지합니다.';
  @override
  String onsideSuccess(int yards, String team) =>
      '온사이드 킥 성공! $yards야드 지점에서 $team 팀이 공격권을 유지합니다.';
  @override
  String touchbackLine(String team) =>
      '터치백. $team 팀이 자기 진영 20야드에서 공격을 시작합니다.';
  @override
  String kickoffReturnFumble(int yards) =>
      '킥오프 리턴 중 펌블! $yards야드 지점에서 턴오버 판정.';
  @override
  String kickoffReturnLine(String team, int yards) =>
      '$team 킥오프 리턴: $yards야드';
  @override
  String playHeader(String team, String off, String def) =>
      '$team 공격: $off vs $def';
  @override
  String penaltyOffset(int offD10, int defD10) =>
      '패널티 상쇄 (양팀 주사위 동일: $offD10-$defD10). 플레이는 그대로 진행됩니다.';
  @override
  String defenseMod(int mod, int from, int to) =>
      '수비 보정 ${mod > 0 ? '+' : ''}$mod → 공격 주사위 $from → $to';
  @override
  String gain(int yards) => '$yards야드 전진!';
  @override
  String loss(int yards) => '$yards야드 후퇴!';
  @override
  String penaltyOnOffense(int yards) =>
      '반칙! 공격팀 패널티, $yards야드 후퇴. (선택한 카드는 사용되지 않습니다)';
  @override
  String penaltyOnDefense(int yards) =>
      '반칙! 수비팀 패널티, $yards야드 전진. (선택한 카드는 사용되지 않습니다)';
  @override
  String get penaltyFirstDown => '패널티 야드로 퍼스트 다운 달성!';
  @override
  String repeatDown(int down) => '$down번째 다운을 다시 진행합니다.';
  @override
  String interception(int yards) =>
      '인터셉트! 공이 $yards야드 날아간 지점에서 가로채였습니다.';
  @override
  String get fumbleAtLine => '펌블! 스크리미지 라인에서 공을 놓쳤습니다.';
  @override
  String turnoverJudge(String cell) => '턴오버 리턴 판정 → $cell';
  @override
  String returnFumble(int yards) => '리턴 중 다시 펌블! ($yards야드 지점)';
  @override
  String returnGain(String team, int yards) => '$team 팀이 $yards야드 리턴!';
  @override
  String fumbleRecovered(String team) => '펌블 리커버! $team 팀이 공을 확보했습니다.';
  @override
  String fumbleLost(String team) => '펌블 분실! $team 팀이 공을 되찾았습니다.';
  @override
  String puntFallback(int yards) => '펀트가 불안했지만 평균 거리 $yards야드로 날아갑니다.';
  @override
  String puntLine(String team, String puntName, int yards) =>
      '$team $puntName: $yards야드';
  @override
  String get endzoneChoicePunt => '펀트가 엔드존에 도달했습니다. 리턴 또는 터치백을 선택하세요.';
  @override
  String puntReturnLine(String team, int yards) => '$team 펀트 리턴: $yards야드';
  @override
  String fgSuccess(int distance) => '$distance야드 필드골 성공! +3점';
  @override
  String get fgFumble => '필드골 시도 중 펌블! 실패.';
  @override
  String fgFail(int distance) => '$distance야드 필드골 실패!';
  @override
  String takeoverAtSpot(String team) => '$team 팀이 그 자리에서 공격권을 가져갑니다.';
  @override
  String get extraKickSuccess => '추가 킥 성공! +1점';
  @override
  String get extraKickFail => '추가 킥 실패!';
  @override
  String twoPointAttempt(String off, String def) => '2점 컨버전 시도: $off vs $def';
  @override
  String conversionFailTurnover(bool isInterception) =>
      '컨버전 실패! (${isInterception ? '인터셉트' : '펌블'})';
  @override
  String get twoPointSuccess => '2점 컨버전 성공! +2점';
  @override
  String conversionFailShort(int yards) =>
      '컨버전 실패! ($yards야드 — 엔드존에 못 미쳤습니다)';
  @override
  String touchdown(String team) => '🏈 터치다운! $team +6점';
  @override
  String safety(String team) => '세이프티! $team +2점';
  @override
  String scoreLine(int home, int away) => '스코어: HOME $home - $away AWAY';
  @override
  String suddenDeathWin(String team) => '서든 데스 연장전 — $team 팀 승리!';
  @override
  String firstDownLine(String team, int toFirst, int toGoal) =>
      '$team 팀 1st down & $toFirst, 골라인까지 $toGoal야드';
  @override
  String get firstDownRenewed => '퍼스트 다운 갱신!';
  @override
  String downsExhausted(String team) => '다운 소진! $team 팀에게 공격권이 넘어갑니다.';
  @override
  String nextDown(int down, int yards) => '$down번째 다운, $yards야드 남음';
  @override
  String halftime(String team) => '전반전 종료! 후반전은 $team 팀이 킥오프합니다.';
  @override
  String quarterEnd(int prev, int next) => '$prev쿼터 종료. $next쿼터를 시작합니다.';
  @override
  String gameEnd(String team, int home, int away) =>
      '경기 종료! $team 팀 승리! ($home - $away)';
  @override
  String get tieOvertime => '동점! 서든 데스 연장전을 시작합니다. (먼저 득점하는 팀이 승리)';
  @override
  String drawLine(int home, int away) =>
      '연장전에도 승부가 나지 않아 무승부입니다. ($home - $away)';
}

// ---------------------------------------------------------------------------
// English
// ---------------------------------------------------------------------------

class L10nEn extends L10n {
  const L10nEn();

  @override
  AppLanguage get lang => AppLanguage.en;

  static String _ordinal(int n) => switch (n) {
        1 => '1st',
        2 => '2nd',
        3 => '3rd',
        _ => '${n}th',
      };

  @override
  String cardDescription(String id, String koDescription) =>
      _enDescriptions[id] ?? koDescription;

  @override
  String chartName(String name, String koName) => name;

  @override
  String get appSubtitle => 'American football board game · vs AI';
  @override
  String get newGame => 'New Game';
  @override
  String get howToPlay => 'How to Play';
  @override
  String get close => 'Close';
  @override
  String get difficultyEasy => 'Easy';
  @override
  String get difficultyNormal => 'Normal';
  @override
  String get difficultyHard => 'Hard';
  @override
  String get effectsLabel => 'Dice & card effects';
  @override
  String get soundLabel => 'Sound effects';
  @override
  String get cardInfoTooltip => 'Selected card info';

  @override
  String get mpButton => 'Play with a friend (same Wi-Fi)';
  @override
  String get mpTitle => 'Play with a friend';
  @override
  String get hostGame => 'Host a game';
  @override
  String get hostGameDesc => 'Create a room and wait for your friend';
  @override
  String get joinGame => 'Join a game';
  @override
  String get joinGameDesc => 'Join a room your friend created';
  @override
  String get waitingForFriend =>
      'Waiting for your friend...\nAsk them to tap [Join a game]';
  @override
  String yourIp(String ip) => 'My address: $ip';
  @override
  String get searchingHosts => 'Searching for rooms on this Wi-Fi...';
  @override
  String get manualIpHint => 'Enter host IP (e.g. 192.168.0.5)';
  @override
  String get connectButton => 'Connect';
  @override
  String get connectionFailed =>
      'Connection failed. Make sure you are on the same Wi-Fi.';
  @override
  String get connectionLost => 'Connection lost';
  @override
  String get opponentWaiting => "Waiting for your opponent's card...";
  @override
  String get opponentTurn => "Opponent's turn...";
  @override
  String youLabel(String team) => 'ME ($team)';
  @override
  String friendLabel(String team) => 'FRIEND ($team)';
  @override
  String get oppOffenseLabel => 'OPP OFFENSE';
  @override
  String get oppDefenseLabel => 'OPP DEFENSE';
  @override
  String oppRevealDefense(String name) => "Opponent's defense: $name";
  @override
  String oppRevealOffense(String name) => "Opponent's offense: $name";
  @override
  String defensePanelTitleMp(int down, int yards) =>
      "Defense gameplan — opponent's ${_ordinal(down)} & $yards";
  @override
  String get defenseTwoPointTitleMp =>
      'Opponent goes for two — pick a formation';
  @override
  String get timeUpAutoPick => "Time's up! A play was picked automatically";

  @override
  String get howToPlayBody => '🏈 Goal\n'
      'Score more points than your opponent over 4 quarters '
      '(16 plays per quarter).\n\n'
      '📋 Flow\n'
      '· The offense must gain 10 yards within 4 downs.\n'
      '· Both sides secretly pick an offense card (pass/run) and a defense '
      'card, then roll dice and read the result off the card chart.\n'
      '· Defense cards modify the offense die by play type. '
      'Reading your opponent is the key!\n\n'
      '🎲 Reading the four dice\n'
      'The result comes from the chart (5 rows × 10 columns) on the back '
      'of the offense card.\n'
      '· Offense D10 (red): picks the chart row. Adjusted by the defense '
      "card's modifier (-3 to +3). Higher is better!\n"
      '· Defense D10 (blue): penalty check only. If both D10s sum to 6 or '
      '16, a penalty occurs. (Equal dice cancel it out)\n'
      '· Two D12s (purple): one per team; their sum (2-24) picks the '
      'chart column.';

  @override
  String get howToPlayExampleTitle => '📖 Example — Short Pass card';
  @override
  String get howToPlayExampleDice =>
      'Offense D10 9 − defense modifier 2 = 7 → row "7-8"\n'
      'D12 sum 6+8=14 → column "13-15"';
  @override
  String get howToPlayExampleResult =>
      'The intersection is 6 → gain 6 yards!\n'
      'Tap "View chart" after a play to see the cell like this.';

  @override
  String get howToPlayBody2 => '🎯 Scoring\n'
      '· Touchdown: 6 pts (+1 extra kick or +2 two-point conversion)\n'
      '· Field goal: 3 pts (within 59 yards)\n'
      '· Safety: 2 pts\n\n'
      '⚡ Special\n'
      '· Stuck on 4th down? Punt to push the opponent back.\n'
      '· Interceptions and fumbles can turn the ball over.\n'
      '· If both D10 dice sum to 6 or 16 — penalty!\n\n'
      '⏱ Time limit (friend matches)\n'
      '· In network games every decision has a 15-second limit.\n'
      '· A countdown appears when 5 seconds remain.\n'
      '· When time runs out the game picks for you (offense/defense: '
      'suggested card, kickoff: normal kick, return: touchback, '
      'extra point: kick).\n\n'
      '💡 Tip\n'
      'Long-press any card to see its full chart and modifiers.';

  @override
  String get homeTeamLabel => 'ME (HOME)';
  @override
  String get awayTeamLabel => 'AI (AWAY)';
  @override
  String downAndDistance(int down, int yards) =>
      '${_ordinal(down)} & $yards';
  @override
  String get offD10Label => 'OFF D10';
  @override
  String get defD10Label => 'DEF D10';
  @override
  String get myOffenseLabel => 'MY OFFENSE';
  @override
  String get aiOffenseLabel => 'AI OFFENSE';
  @override
  String get myDefenseLabel => 'MY DEFENSE';
  @override
  String get aiDefenseLabel => 'AI DEFENSE';
  @override
  String get matchupTitle => 'Play Matchup';
  @override
  String get matchupHint => 'Tap a card for details';
  @override
  String get chartLegend =>
      'Row: offense D10 (after modifier) · Col: sum of both D12';
  @override
  String get passModifiers => 'Pass play modifiers';
  @override
  String get runModifiers => 'Run play modifiers';

  @override
  String aiRevealDefense(String name) => 'AI defense: $name';
  @override
  String aiRevealOffense(String name) => 'AI offense: $name';
  @override
  String aiPuntChoice(bool long) =>
      'AI chose a ${long ? 'long' : 'short'} punt';
  @override
  String get aiFieldGoal => 'AI attempts a field goal';
  @override
  String get aiExtraKick => 'AI chose the extra-point kick';
  @override
  String aiTwoPoint(String name) => 'AI goes for two: $name';
  @override
  String get welcome => 'Welcome to Football Dice!';
  @override
  String get viewCards => 'View cards';
  @override
  String get viewChart => 'View chart';
  @override
  String get aiThinking => 'AI is thinking...';
  @override
  String get kickoffTitle => 'Kickoff — how do you want to kick?';
  @override
  String get kickoffButton => 'Kickoff';
  @override
  String get onsideButton => 'Onside kick (gamble to keep possession)';
  @override
  String get returnTitle => 'The ball is in the end zone';
  @override
  String get returnButton => 'Return!';
  @override
  String get touchbackButton => 'Touchback (start at the 20)';
  @override
  String get twoPointPanelTitle => 'Two-point conversion — pick a play';
  @override
  String offensePanelTitle(int down, int yards) =>
      'Offense gameplan — ${_ordinal(down)} & $yards';
  @override
  String suggestion(String situation) => 'Suggested: $situation';
  @override
  String get situationTwoPoint => 'Two-point conversion';
  @override
  String get situationGoalLine => 'Goal-line situation';
  @override
  String get situationShort => 'Short yardage';
  @override
  String get situationMedium => 'Medium yardage';
  @override
  String get situationLong => 'Long yardage';
  @override
  String offenseSubtitle(bool isPass, double avgYards) =>
      '${isPass ? 'Pass' : 'Run'} · avg ${avgYards}yd';
  @override
  String get fullPlaybook => 'Full playbook';
  @override
  String get fullDefense => 'All formations';
  @override
  String get longPuntButton => 'Long punt';
  @override
  String get shortPuntButton => 'Short punt';
  @override
  String get playButton => 'Play!';
  @override
  String get execButton => 'Go!';
  @override
  String get defendButton => 'Defend!';
  @override
  String defensePanelTitle(int down, int yards) =>
      "Defense gameplan — AI's ${_ordinal(down)} & $yards";
  @override
  String get defenseTwoPointTitle => 'AI goes for two — pick a formation';
  @override
  String get offensePlaybookTitle => 'Full offense playbook';
  @override
  String get longPressHint => 'Long-press a card for details';
  @override
  String get extraPointTitle => 'Touchdown! Choose your extra points';
  @override
  String get extraKickButton => 'Extra kick (+1, high success)';
  @override
  String get twoPointButton => 'Two-point try (+2, gain 2 yards)';
  @override
  String get gameOverTitle => 'Game Over';
  @override
  String get drawMessage => 'Draw!';
  @override
  String get winMessage => '🎉 You win!';
  @override
  String get loseMessage => 'You lost this one...';

  @override
  String coinToss(String team) => 'Coin toss: $team will kick off.';
  @override
  String kickFallback(int yards) =>
      'Shaky kick — resolved as the average distance of $yards yards.';
  @override
  String kickoffLine(String team, int yards) => '$team kickoff: $yards yards';
  @override
  String get endzoneChoiceKickoff =>
      'The ball reached the end zone. Choose return or touchback.';
  @override
  String onsideFail(String team) =>
      'Onside kick failed! $team recovers the ball.';
  @override
  String onsideBackward(int yards) =>
      'The onside kick rolled backwards! $yards-yard setback, '
      'but possession is kept.';
  @override
  String onsideSuccess(int yards, String team) =>
      'Onside kick success! $team keeps possession at the $yards-yard spot.';
  @override
  String touchbackLine(String team) =>
      'Touchback. $team starts the drive at their own 20-yard line.';
  @override
  String kickoffReturnFumble(int yards) =>
      'Fumble during the kickoff return! Turnover resolved at the '
      '$yards-yard spot.';
  @override
  String kickoffReturnLine(String team, int yards) =>
      '$team kickoff return: $yards yards';
  @override
  String playHeader(String team, String off, String def) =>
      '$team offense: $off vs $def';
  @override
  String penaltyOffset(int offD10, int defD10) =>
      'Penalties offset (both dice equal: $offD10-$defD10). The play stands.';
  @override
  String defenseMod(int mod, int from, int to) =>
      'Defense modifier ${mod > 0 ? '+' : ''}$mod → offense die $from → $to';
  @override
  String gain(int yards) => 'Gain of $yards yards!';
  @override
  String loss(int yards) => 'Loss of $yards yards!';
  @override
  String penaltyOnOffense(int yards) =>
      'Flag! Penalty on the offense, $yards-yard setback. '
      '(Selected cards are not used)';
  @override
  String penaltyOnDefense(int yards) =>
      'Flag! Penalty on the defense, $yards-yard gain. '
      '(Selected cards are not used)';
  @override
  String get penaltyFirstDown => 'Penalty yards earn a first down!';
  @override
  String repeatDown(int down) =>
      '${_ordinal(down)} down will be replayed.';
  @override
  String interception(int yards) =>
      'Interception! Picked off $yards yards downfield.';
  @override
  String get fumbleAtLine =>
      'Fumble! The ball is loose at the line of scrimmage.';
  @override
  String turnoverJudge(String cell) => 'Turnover return result → $cell';
  @override
  String returnFumble(int yards) =>
      'Fumbled again during the return! (at the $yards-yard spot)';
  @override
  String returnGain(String team, int yards) => '$team returns it $yards yards!';
  @override
  String fumbleRecovered(String team) => 'Fumble recovered! $team keeps the ball.';
  @override
  String fumbleLost(String team) => 'Fumble lost! $team takes the ball back.';
  @override
  String puntFallback(int yards) =>
      'Shaky punt — it flies the average distance of $yards yards.';
  @override
  String puntLine(String team, String puntName, int yards) =>
      '$team $puntName: $yards yards';
  @override
  String get endzoneChoicePunt =>
      'The punt reached the end zone. Choose return or touchback.';
  @override
  String puntReturnLine(String team, int yards) =>
      '$team punt return: $yards yards';
  @override
  String fgSuccess(int distance) =>
      '$distance-yard field goal is good! +3 points';
  @override
  String get fgFumble => 'Fumble on the field goal attempt! No good.';
  @override
  String fgFail(int distance) => '$distance-yard field goal is no good!';
  @override
  String takeoverAtSpot(String team) => '$team takes over at the spot.';
  @override
  String get extraKickSuccess => 'Extra point is good! +1 point';
  @override
  String get extraKickFail => 'Extra point is no good!';
  @override
  String twoPointAttempt(String off, String def) =>
      'Two-point conversion attempt: $off vs $def';
  @override
  String conversionFailTurnover(bool isInterception) =>
      'Conversion failed! (${isInterception ? 'interception' : 'fumble'})';
  @override
  String get twoPointSuccess => 'Two-point conversion is good! +2 points';
  @override
  String conversionFailShort(int yards) =>
      'Conversion failed! ($yards yards — short of the end zone)';
  @override
  String touchdown(String team) => '🏈 TOUCHDOWN! $team +6 points';
  @override
  String safety(String team) => 'Safety! $team +2 points';
  @override
  String scoreLine(int home, int away) => 'Score: HOME $home - $away AWAY';
  @override
  String suddenDeathWin(String team) => 'Sudden-death overtime — $team wins!';
  @override
  String firstDownLine(String team, int toFirst, int toGoal) =>
      '$team 1st down & $toFirst, $toGoal yards to the goal line';
  @override
  String get firstDownRenewed => 'First down!';
  @override
  String downsExhausted(String team) =>
      'Turnover on downs! $team takes possession.';
  @override
  String nextDown(int down, int yards) =>
      '${_ordinal(down)} down, $yards yards to go';
  @override
  String halftime(String team) =>
      'End of the first half! $team will kick off the second half.';
  @override
  String quarterEnd(int prev, int next) => 'End of Q$prev. Starting Q$next.';
  @override
  String gameEnd(String team, int home, int away) =>
      'Final! $team wins! ($home - $away)';
  @override
  String get tieOvertime =>
      'Tie game! Sudden-death overtime begins. (First score wins)';
  @override
  String drawLine(int home, int away) =>
      'Still tied after overtime — the game ends in a draw. ($home - $away)';

  /// 카드 id → 영어 설명
  static const _enDescriptions = <String, String>{
    // 공격 카드
    'long_bomb':
        "A last-ditch long pass for points, also known as the 'Hail Mary'.",
    'long_pass':
        'A long pass is more likely to be intercepted than a short pass.',
    'short_pass':
        'A short pass is less likely to be intercepted than a long pass.',
    'screen_pass':
        'A short pass disguised as a long-pass setup, slowing down an '
            'aggressive rush.',
    'dive_plunge':
        'A fullback/running back charge into either side of the middle of '
            'the defensive line.',
    'pitch_out': 'The ball is tossed to another player for a clean outside run.',
    'qb_draw':
        'A trick running play: a fake pass formation that lets the '
            'quarterback run it himself.',
    'rb_draw':
        'Good in long passing situations. Watch out for Blitz and Nickel '
            'defenses.',
    'sweep':
        'Good in long passing situations. Watch out for Blitz and Nickel '
            'defenses.',
    // 수비 카드
    'dime':
        'An extreme pass defense with six defensive backs. Weak against '
            'the run.',
    'nickel':
        'A standard formation to stop pass plays. Two corner backs and a '
            'nickel back shut down wide receivers.',
    'prevent':
        'Effective against aggressive offense. Disrupts both long passes '
            'and punts.',
    'zone': 'Defenders cover areas of the field. Good against the rush.',
    'four_three':
        'A classic defense where four front linemen add pressure on the '
            'quarterback.',
    'three_four':
        'A basic linebacker formation that pressures the quarterback while '
            'disguising direction.',
    'blitz':
        'Heavy pressure on the offensive line to break up long formations.',
    'goal_line':
        'A defense that holds the scrimmage line instead of rushing first.',
    'man_to_man':
        'Tight coverage on receivers, but vulnerable to runs where coverage '
            'breaks down.',
    // 공용/스페셜팀 카드
    'kick_off':
        'Used from your own 30-yard line to send the ball deep toward the '
            'opposing goal.',
    'kickoff_return':
        'Used when returning a kickoff. In the end zone you may decline the '
            'return and start at the 20-yard line.',
    'punt_return':
        'A punt is a shorter kick, so returns gain less than kickoff returns.',
    'turnover':
        'On an interception/fumble, determines how far the defense returns '
            'the ball.',
    'fumble':
        "Resolves the Turnover card's F result. R = Recovered, X = Lost. "
            '(48.3% recovery)',
    'fg_1_19': 'Used for goal attempts from 1-19 yards. (98.7% success)',
    'fg_20_29': 'Used for goal attempts from 20-29 yards. (96.5% success)',
    'fg_30_39': 'Used for goal attempts from 30-39 yards. (81.3% success)',
    'fg_40_49': 'Used for goal attempts from 40-49 yards. (72% success)',
    'fg_50_59':
        'Used for goal attempts from 50-59 yards. No attempts beyond 59 '
            'yards. (57.8% success)',
    'long_punt': 'Professional kickers average 43-44 yards per long punt.',
    'short_punt':
        'Unless the offense is under pressure, this punt is very accurate.',
    'on_side_kick':
        'Only from the kickoff spot. You keep possession unless the result '
            'is I. -10 means a 10-yard setback.',
  };
}
