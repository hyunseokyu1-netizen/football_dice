/// Football Dice 카드 데이터.
///
/// 모든 차트는 원작 보드게임 카드(card_Kr_v01.pdf)를 그대로 옮긴 것이다.
/// 행(row): 공격자의 10면체 주사위(수비 보정 적용 후) — 위에서부터 9-10, 7-8, 5-6, 3-4, 1-2
/// 열(column): 양 팀 12면체 주사위 합 — 2-3, 4-5, 6-7, 8-9, 10-12, 13-15, 16-18, 19-20, 21-22, 23-24
///
/// 셀 값: 숫자(전진/후퇴 야드), 'I'(인터셉트), 'F'(펌블),
///        'G'(필드골 성공), 'X'(실패/분실), 'R'(펌블 리커버)
library;

/// 12면체 합(2~24) → 열 인덱스(0~9)
int columnIndex(int d12Sum) {
  if (d12Sum <= 3) return 0;
  if (d12Sum <= 5) return 1;
  if (d12Sum <= 7) return 2;
  if (d12Sum <= 9) return 3;
  if (d12Sum <= 12) return 4;
  if (d12Sum <= 15) return 5;
  if (d12Sum <= 18) return 6;
  if (d12Sum <= 20) return 7;
  if (d12Sum <= 22) return 8;
  return 9;
}

/// 보정된 10면체 값(1~10으로 클램프) → 행 인덱스(0~4)
int rowIndex(int adjustedD10) {
  final v = adjustedD10.clamp(1, 10);
  if (v >= 9) return 0;
  if (v >= 7) return 1;
  if (v >= 5) return 2;
  if (v >= 3) return 3;
  return 4;
}

const columnLabels = [
  '2-3', '4-5', '6-7', '8-9', '10-12',
  '13-15', '16-18', '19-20', '21-22', '23-24',
];
const rowLabels = ['9-10', '7-8', '5-6', '3-4', '1-2'];

enum PlayType { pass, run }

class OffenseCard {
  final String id;
  final String name;
  final String koName;
  final PlayType type;
  final double averageYards;
  final double effectiveness;
  final String description;
  final List<List<String>> chart;

  const OffenseCard({
    required this.id,
    required this.name,
    required this.koName,
    required this.type,
    required this.averageYards,
    required this.effectiveness,
    required this.description,
    required this.chart,
  });

  String cell(int row, int col) => chart[row][col];
}

class DefenseCard {
  final String id;
  final String name;
  final String description;

  /// 공격 카드 id → 공격자 10면체 주사위 보정치
  final Map<String, int> modifiers;

  const DefenseCard({
    required this.id,
    required this.name,
    required this.description,
    required this.modifiers,
  });

  int modifierFor(String offenseCardId) => modifiers[offenseCardId] ?? 0;
}

/// 공용/스페셜팀 차트 카드 (수비 카드 플레이 없이 단독 판정)
class ChartCard {
  final String id;
  final String name;
  final String koName;
  final double? averageYards;
  final String description;
  final List<List<String>> chart;

  const ChartCard({
    required this.id,
    required this.name,
    required this.koName,
    this.averageYards,
    required this.description,
    required this.chart,
  });

  String cell(int row, int col) => chart[row][col];

  int get roundedAverage => (averageYards ?? 0).round();
}

// ---------------------------------------------------------------------------
// 공격 카드 9장
// ---------------------------------------------------------------------------

const longBomb = OffenseCard(
  id: 'long_bomb',
  name: 'LONG BOMB',
  koName: '롱 밤',
  type: PlayType.pass,
  averageYards: 14.7,
  effectiveness: 44.5,
  description: "'성모 송(Hail Mary)'이라고도 불리는, 점수를 내기 위한 마지막 장거리 패스.",
  chart: [
    ['96', '61', '56', '46', '36', '19', '33', '45', '59', '71'],
    ['60', '55', '45', '35', '8', '0', '19', '32', '44', '48'],
    ['55', '45', '35', '0', '0', '0', '0', '18', '31', '43'],
    ['45', '35', 'I', '0', '-1', '0', '0', '0', '16', '30'],
    ['34', '0', '0', '0', '-5', '-2', 'I', 'F', '0', '0'],
  ],
);

const longPass = OffenseCard(
  id: 'long_pass',
  name: 'LONG PASS',
  koName: '롱 패스',
  type: PlayType.pass,
  averageYards: 10.5,
  effectiveness: 60.6,
  description: 'Long pass는 short pass보다 인터셉트 당할 확률이 높다.',
  chart: [
    ['96', '65', '54', '48', '26', '9', '7', '33', '57', '61'],
    ['65', '54', '46', '25', '8', '3', '5', '16', '19', '44'],
    ['54', '37', '22', '8', '0', '1', '0', '2', '13', '22'],
    ['36', '19', '7', '0', '-1', '1', 'I', '0', '1', '10'],
    ['8', '5', '-5', '-3', '-1', '0', '-2', '-4', 'F', '0'],
  ],
);

const shortPass = OffenseCard(
  id: 'short_pass',
  name: 'SHORT PASS',
  koName: '숏 패스',
  type: PlayType.pass,
  averageYards: 8.0,
  effectiveness: 62.7,
  description: 'Short pass는 long pass보다 인터셉트 당할 확률이 낮다.',
  chart: [
    ['95', '59', '24', '21', '9', '8', '20', '24', '32', '86'],
    ['59', '24', '21', '9', '8', '6', '8', '19', '23', '31'],
    ['24', '21', '9', '8', '6', '0', '5', '0', '18', '22'],
    ['21', '9', '8', '6', '0', '0', '0', '4', '7', '17'],
    ['9', '8', '0', 'F', '-1', '0', '-2', 'I', '-4', '5'],
  ],
);

const screenPass = OffenseCard(
  id: 'screen_pass',
  name: 'SCREEN PASS',
  koName: '스크린 패스',
  type: PlayType.pass,
  averageYards: 7.8,
  effectiveness: 64.1,
  description: 'Long pass를 위한 준비처럼 보여 공격적인 돌진 방어를 느리게 만드는 짧은 패스.',
  chart: [
    ['96', '60', '24', '19', '9', '8', '17', '23', '29', '85'],
    ['60', '24', '19', '9', '7', '4', '8', '16', '23', '29'],
    ['24', '19', '9', '7', '3', '0', '2', '6', '15', '23'],
    ['18', '9', '7', '3', '0', '0', '0', '2', '5', '14'],
    ['8', '6', '0', 'F', '-1', '0', '-2', '-4', 'I', '4'],
  ],
);

const divePlunge = OffenseCard(
  id: 'dive_plunge',
  name: 'DIVE/PLUNGE',
  koName: '다이브/플런지',
  type: PlayType.run,
  averageYards: 2.7,
  effectiveness: 74.1,
  description: 'Defensive line 중앙의 좌우로 파고드는 Fullback/Running Back 돌격.',
  chart: [
    ['48', '9', '7', '6', '5', '3', '4', '5', '6', '17'],
    ['8', '7', '6', '5', '2', '2', '3', '4', '5', '6'],
    ['6', '6', '5', '3', '1', '0', '2', '3', '4', '5'],
    ['5', '5', '3', '1', '1', '-1', '1', '2', '3', '4'],
    ['4', '0', '2', '0', '-1', '-1', '0', 'F', '2', '3'],
  ],
);

const pitchOut = OffenseCard(
  id: 'pitch_out',
  name: 'PITCH OUT',
  koName: '피치 아웃',
  type: PlayType.run,
  averageYards: 6.0,
  effectiveness: 67.1,
  description: '완벽하게 달리기 위해 다른 플레이어에게 공을 던진다.',
  chart: [
    ['87', '40', '20', '11', '10', '8', '9', '20', '33', '75'],
    ['39', '20', '10', '9', '8', '6', '6', '8', '19', '28'],
    ['20', '10', '8', '7', '0', '1', '3', '5', '8', '18'],
    ['10', '8', '7', '4', '0', '-2', '-1', '2', '4', '7'],
    ['8', '0', '0', '1', '-3', '-5', 'F', '1', '0', '4'],
  ],
);

const quarterbackDraw = OffenseCard(
  id: 'qb_draw',
  name: 'QUARTERBACK DRAW',
  koName: '쿼터백 드로우',
  type: PlayType.run,
  averageYards: 4.02,
  effectiveness: 68.5,
  description: 'Quarterback이 직접 달릴 수 있도록 가짜 패스 대형을 이루는 트릭 러닝 플레이.',
  chart: [
    ['73', '18', '15', '11', '9', '6', '8', '12', '17', '31'],
    ['16', '12', '10', '8', '5', '3', '5', '7', '11', '13'],
    ['10', '9', '7', '4', '2', '0', '0', '4', '6', '9'],
    ['8', '6', '3', '2', '1', '0', '-2', '2', '3', '5'],
    ['5', '2', '1', '-5', 'F', '-2', '-6', '-7', '1', '2'],
  ],
);

const runningbackDraw = OffenseCard(
  id: 'rb_draw',
  name: 'RUNNINGBACK DRAW',
  koName: '러닝백 드로우',
  type: PlayType.run,
  averageYards: 5.0,
  effectiveness: 66.9,
  description: 'Long passing 상황에 좋은 플레이. Blitz와 Nickel 수비를 조심하라.',
  chart: [
    ['85', '22', '19', '15', '11', '7', '8', '16', '19', '51'],
    ['20', '18', '14', '10', '6', '4', '5', '7', '13', '16'],
    ['15', '13', '9', '5', '4', '3', '0', '3', '6', '10'],
    ['9', '8', '4', '3', '-1', '0', '-2', '1', '2', '5'],
    ['6', '0', '3', '-2', 'F', '-5', '-6', '-3', '1', '2'],
  ],
);

const sweep = OffenseCard(
  id: 'sweep',
  name: 'SWEEP',
  koName: '스윕',
  type: PlayType.run,
  averageYards: 3.6,
  effectiveness: 70.0,
  description: 'Long passing 상황에 좋은 플레이. Blitz와 Nickel 수비를 조심하라.',
  chart: [
    ['38', '17', '13', '10', '8', '6', '8', '9', '10', '15'],
    ['17', '13', '10', '8', '5', '1', '6', '7', '8', '9'],
    ['13', '10', '8', '4', '1', '0', '1', '5', '7', '8'],
    ['9', '8', '3', '1', '1', '-1', '0', '1', '5', '7'],
    ['7', '2', '0', '0', '-3', '-7', '-2', 'F', '1', '5'],
  ],
);

const offenseCards = [
  longBomb, longPass, shortPass, screenPass,
  divePlunge, pitchOut, quarterbackDraw, runningbackDraw, sweep,
];

OffenseCard offenseById(String id) =>
    offenseCards.firstWhere((c) => c.id == id);

// ---------------------------------------------------------------------------
// 수비 카드 9장 — 공격 카드별 10면체 보정치
// ---------------------------------------------------------------------------

const dime = DefenseCard(
  id: 'dime',
  name: 'DIME',
  description: '6명의 수비백을 두는 극단적 패스 수비 대형. 달리기에는 취약하다.',
  modifiers: {
    'long_bomb': -2, 'long_pass': -2, 'screen_pass': 1, 'short_pass': -1,
    'dive_plunge': 1, 'pitch_out': 1, 'qb_draw': 1, 'rb_draw': 2, 'sweep': 0,
  },
);

const nickel = DefenseCard(
  id: 'nickel',
  name: 'NICKEL',
  description: '패스 플레이를 저지하기 위한 기본 대형. Corner back 2명과 Nickel back이 넓은 리시버를 차단한다.',
  modifiers: {
    'long_bomb': 0, 'long_pass': -1, 'screen_pass': -2, 'short_pass': -2,
    'dive_plunge': 0, 'pitch_out': 1, 'qb_draw': 0, 'rb_draw': 0, 'sweep': 0,
  },
);

const prevent = DefenseCard(
  id: 'prevent',
  name: 'PREVENT',
  description: '적극적인 공격 전술에 효과적. Long pass와 Punt 모두를 방해한다.',
  modifiers: {
    'long_bomb': -3, 'long_pass': -3, 'screen_pass': 1, 'short_pass': -2,
    'dive_plunge': 2, 'pitch_out': 2, 'qb_draw': 2, 'rb_draw': 3, 'sweep': 0,
  },
);

const zone = DefenseCard(
  id: 'zone',
  name: 'ZONE',
  description: '필드 지역별로 플레이어를 배치하는 수비. 돌진을 막기에 좋다.',
  modifiers: {
    'long_bomb': 1, 'long_pass': 1, 'screen_pass': 1, 'short_pass': 1,
    'dive_plunge': 0, 'pitch_out': -1, 'qb_draw': -1, 'rb_draw': 0, 'sweep': -1,
  },
);

const fourThree = DefenseCard(
  id: 'four_three',
  name: '4-3',
  description: '앞 열의 linemen 4명이 Quarterback에게 추가 압박을 가하는 전형적 수비.',
  modifiers: {
    'long_bomb': -1, 'long_pass': -1, 'screen_pass': 0, 'short_pass': 0,
    'dive_plunge': -1, 'pitch_out': 1, 'qb_draw': -2, 'rb_draw': -1, 'sweep': -1,
  },
);

const threeFour = DefenseCard(
  id: 'three_four',
  name: '3-4',
  description: '방향을 쉽게 위장하면서 Quarterback을 압박하는 기본 linebacker 대형.',
  modifiers: {
    'long_bomb': 0, 'long_pass': 0, 'screen_pass': -1, 'short_pass': -1,
    'dive_plunge': 0, 'pitch_out': -1, 'qb_draw': 0, 'rb_draw': 1, 'sweep': 1,
  },
);

const blitz = DefenseCard(
  id: 'blitz',
  name: 'BLITZ',
  description: '긴 대형 형성을 저지하기 위해 offensive line에 강한 압박을 가한다.',
  modifiers: {
    'long_bomb': -1, 'long_pass': -2, 'screen_pass': -1, 'short_pass': -1,
    'dive_plunge': -2, 'pitch_out': 1, 'qb_draw': 0, 'rb_draw': 0, 'sweep': 1,
  },
);

const goalLine = DefenseCard(
  id: 'goal_line',
  name: 'GOAL LINE',
  description: '먼저 돌진하지 않고 scrimmage line을 유지하는 수비.',
  modifiers: {
    'long_bomb': 1, 'long_pass': 1, 'screen_pass': 0, 'short_pass': 0,
    'dive_plunge': -3, 'pitch_out': -2, 'qb_draw': -3, 'rb_draw': -2, 'sweep': -2,
  },
);

const manToMan = DefenseCard(
  id: 'man_to_man',
  name: 'MAN TO MAN',
  description: '리시버를 밀착 마크하지만, 커버가 실패한 곳에서는 러닝에 취약하다.',
  modifiers: {
    'long_bomb': -1, 'long_pass': -1, 'screen_pass': -1, 'short_pass': -1,
    'dive_plunge': 0, 'pitch_out': 1, 'qb_draw': 1, 'rb_draw': 0, 'sweep': 1,
  },
);

const defenseCards = [
  dime, nickel, prevent, zone, fourThree, threeFour, blitz, goalLine, manToMan,
];

DefenseCard defenseById(String id) =>
    defenseCards.firstWhere((c) => c.id == id);

// ---------------------------------------------------------------------------
// 공용 카드
// ---------------------------------------------------------------------------

const kickOffCard = ChartCard(
  id: 'kick_off',
  name: 'KICK OFF',
  koName: '킥오프',
  averageYards: 60.2,
  description: '자신의 30야드 라인에서 상대 골 가까이 공을 보내기 위해 사용한다.',
  chart: [
    ['73', '72', '71', '70', '69', '68', '69', '70', '71', '72'],
    ['72', '71', '70', '69', '68', '67', '67', '68', '70', '71'],
    ['71', '70', '69', '68', '66', '63', '66', '66', '68', '70'],
    ['70', '69', '67', '65', '62', '60', '58', '59', '65', '67'],
    ['69', '22', '64', 'F', '37', '30', '35', '45', '55', '64'],
  ],
);

const kickoffReturnCard = ChartCard(
  id: 'kickoff_return',
  name: 'KICKOFF RETURN',
  koName: '킥오프 리턴',
  averageYards: 23.3,
  description: 'Kickoff를 받아 전진할 때 사용한다. End zone에서는 리턴을 거절하고 20야드 라인으로 이동할 수 있다.',
  chart: [
    ['98', '53', '45', '36', '33', '32', '30', '33', '37', '58'],
    ['52', '45', '35', '32', '29', '26', '27', '29', '33', '37'],
    ['28', '27', '26', '25', '23', '16', '24', '25', '26', '27'],
    ['27', '26', '25', '22', '16', '12', '15', '23', '24', '26'],
    ['23', '20', '16', '14', 'F', '3', '11', '17', '23', '26'],
  ],
);

const puntReturnCard = ChartCard(
  id: 'punt_return',
  name: 'PUNT RETURN',
  koName: '펀트 리턴',
  averageYards: 9.1,
  description: 'Punt는 짧은 킥이라 Kick Off보다는 리턴이 덜 나간다.',
  chart: [
    ['73', '49', '39', '25', '23', '19', '20', '24', '42', '62'],
    ['44', '36', '22', '20', '5', '3', '8', '12', '15', '21'],
    ['33', '9', '5', '4', '3', '1', '2', '4', '7', '9'],
    ['11', '8', '4', '2', '0', '1', '0', '3', '8', '6'],
    ['8', '4', '1', '1', '0', '0', '0', '1', '4', '9'],
  ],
);

const turnoverCard = ChartCard(
  id: 'turnover',
  name: 'TURNOVER',
  koName: '턴오버',
  averageYards: 15.36,
  description: 'Interception/Fumble 발생 시 수비팀이 공을 되돌려 달린 거리를 판정한다.',
  chart: [
    ['92', '58', '36', '29', '22', '20', '21', '22', '48', '56'],
    ['48', '35', '28', '21', '19', '18', '19', '20', '21', '47'],
    ['34', '27', '20', '18', '17', '15', '9', '18', '19', '20'],
    ['26', '19', '17', '17', '15', '-1', '2', '7', '17', '18'],
    ['18', '16', '16', '-3', '-9', 'F', '-1', '1', '5', '9'],
  ],
);

/// R = 수비팀(리터너)이 공격권 획득, X = 기존 공격팀이 공격권 유지
const fumbleCard = ChartCard(
  id: 'fumble',
  name: 'FUMBLE',
  koName: '펌블',
  description: 'Turnover 카드의 F 결과를 판정한다. R = Recovered, X = Lost. (회수율 48.3%)',
  chart: [
    ['R', 'R', 'R', 'R', 'R', 'R', 'R', 'R', 'X', 'R'],
    ['R', 'R', 'R', 'R', 'R', 'R', 'R', 'X', 'R', 'R'],
    ['R', 'R', 'R', 'R', 'X', 'X', 'X', 'R', 'R', 'X'],
    ['R', 'R', 'X', 'X', 'X', 'X', 'X', 'R', 'R', 'R'],
    ['R', 'X', 'X', 'X', 'X', 'X', 'X', 'X', 'X', 'X'],
  ],
);

/// 12면체 합 열 인덱스 → 패널티 야드
const penaltyYards = [15, 15, 10, 10, 5, 5, 5, 10, 10, 15];

// ---------------------------------------------------------------------------
// 스페셜팀 카드
// ---------------------------------------------------------------------------

const patFieldGoal = ChartCard(
  id: 'fg_1_19',
  name: 'POINT AFTER/FIELD GOAL',
  koName: 'PAT/필드골 (1-19야드)',
  description: '1~19야드 거리에서 골을 시도할 때 사용한다. (성공률 98.7%)',
  chart: [
    ['G', 'G', 'G', 'G', 'G', 'G', 'G', 'G', 'G', 'G'],
    ['G', 'G', 'G', 'G', 'G', 'G', 'G', 'G', 'G', 'G'],
    ['G', 'G', 'G', 'G', 'G', 'G', 'G', 'G', 'G', 'G'],
    ['G', 'G', 'G', 'G', 'G', 'G', 'G', 'G', 'G', 'X'],
    ['F', 'G', 'G', 'G', 'G', 'G', 'G', 'G', 'G', 'G'],
  ],
);

const fieldGoal2029 = ChartCard(
  id: 'fg_20_29',
  name: '20-29 YARD FIELD GOAL',
  koName: '필드골 (20-29야드)',
  description: '20~29야드 거리에서 골을 시도할 때 사용한다. (성공률 96.5%)',
  chart: [
    ['G', 'G', 'G', 'G', 'G', 'G', 'G', 'G', 'G', 'G'],
    ['G', 'G', 'G', 'G', 'G', 'G', 'G', 'G', 'G', 'G'],
    ['G', 'G', 'G', 'G', 'G', 'G', 'G', 'G', 'G', 'G'],
    ['G', 'G', 'G', 'G', 'G', 'G', 'G', 'G', 'G', 'X'],
    ['G', 'G', 'F', 'G', 'G', 'G', 'G', 'X', 'G', 'G'],
  ],
);

const fieldGoal3039 = ChartCard(
  id: 'fg_30_39',
  name: '30-39 YARD FIELD GOAL',
  koName: '필드골 (30-39야드)',
  description: '30~39야드 거리에서 골을 시도할 때 사용한다. (성공률 81.3%)',
  chart: [
    ['G', 'G', 'G', 'G', 'G', 'G', 'G', 'G', 'G', 'G'],
    ['G', 'G', 'G', 'G', 'G', 'G', 'G', 'G', 'G', 'G'],
    ['G', 'G', 'G', 'G', 'G', 'G', 'G', 'G', 'G', 'X'],
    ['X', 'G', 'G', 'G', 'G', 'X', 'G', 'G', 'G', 'X'],
    ['G', 'G', 'G', 'G', 'X', 'X', 'F', 'G', 'X', 'G'],
  ],
);

const fieldGoal4049 = ChartCard(
  id: 'fg_40_49',
  name: '40-49 YARD FIELD GOAL',
  koName: '필드골 (40-49야드)',
  description: '40~49야드 거리에서 골을 시도할 때 사용한다. (성공률 72%)',
  chart: [
    ['G', 'G', 'G', 'G', 'G', 'G', 'G', 'G', 'G', 'G'],
    ['G', 'G', 'G', 'G', 'G', 'G', 'G', 'G', 'G', 'G'],
    ['G', 'G', 'G', 'G', 'G', 'G', 'G', 'X', 'G', 'G'],
    ['G', 'X', 'G', 'G', 'X', 'G', 'X', 'G', 'G', 'G'],
    ['X', 'G', 'X', 'F', 'X', 'X', 'G', 'X', 'X', 'X'],
  ],
);

const fieldGoal5059 = ChartCard(
  id: 'fg_50_59',
  name: '50-59 YARD FIELD GOAL',
  koName: '필드골 (50-59야드)',
  description: '50~59야드 거리에서 골을 시도할 때 사용한다. 59야드 초과는 시도 불가. (성공률 57.8%)',
  chart: [
    ['G', 'G', 'G', 'G', 'G', 'G', 'G', 'G', 'X', 'G'],
    ['G', 'G', 'G', 'G', 'X', 'G', 'G', 'X', 'G', 'G'],
    ['G', 'G', 'X', 'G', 'G', 'X', 'X', 'G', 'X', 'G'],
    ['G', 'X', 'G', 'X', 'G', 'X', 'X', 'G', 'G', 'X'],
    ['G', 'X', 'G', 'X', 'F', 'X', 'G', 'X', 'X', 'X'],
  ],
);

const longPuntCard = ChartCard(
  id: 'long_punt',
  name: 'LONG PUNT',
  koName: '롱 펀트',
  averageYards: 43.7,
  description: '전문 kicker는 Long Punt 당 43~44야드가 평균이다.',
  chart: [
    ['70', '63', '61', '59', '57', '55', '56', '58', '60', '65'],
    ['60', '58', '56', '54', '52', '48', '51', '53', '55', '57'],
    ['55', '53', '51', '49', '45', '40', '44', '48', '50', '52'],
    ['50', '48', '46', '44', '42', '30', '41', '43', '45', '47'],
    ['40', '38', '36', 'F', '30', '15', '20', '26', '30', '34'],
  ],
);

const shortPuntCard = ChartCard(
  id: 'short_punt',
  name: 'SHORT PUNT',
  koName: '숏 펀트',
  averageYards: 22.5,
  description: '공격이 압박받고 있지 않는 한 이 punt는 매우 정확하다.',
  chart: [
    ['50', '45', '40', '34', '30', '28', '32', '36', '46', '51'],
    ['45', '40', '33', '28', '24', '22', '25', '32', '36', '46'],
    ['40', '32', '26', '24', '19', '15', '22', '25', '32', '36'],
    ['31', '24', '23', '18', '14', '12', '14', '22', '25', '32'],
    ['23', '22', 'F', '13', '11', '10', '12', '15', '22', '24'],
  ],
);

const onSideKickCard = ChartCard(
  id: 'on_side_kick',
  name: 'ON SIDE KICK',
  koName: '온사이드 킥',
  averageYards: 11.77,
  description: '킥오프 위치에서만 사용. I가 아닌 이상 공격권을 유지한다. -10은 10야드 후퇴.',
  chart: [
    ['15', '14', '13', '12', '11', '10', '11', '12', '13', '14'],
    ['14', '13', '12', '11', '10', 'I', '10', '10', '11', '12'],
    ['13', '12', '11', '10', '-10', 'I', 'I', '10', '10', '11'],
    ['12', '10', '-10', '-10', 'I', 'I', 'I', 'I', '10', '10'],
    ['10', '-10', '-10', '-10', 'I', 'I', 'I', 'I', 'I', '10'],
  ],
);

/// 골라인까지 거리에 맞는 필드골 카드. 60야드 이상이면 null(시도 불가).
ChartCard? fieldGoalCardFor(int distance) {
  if (distance <= 0) return null;
  if (distance <= 19) return patFieldGoal;
  if (distance <= 29) return fieldGoal2029;
  if (distance <= 39) return fieldGoal3039;
  if (distance <= 49) return fieldGoal4049;
  if (distance <= 59) return fieldGoal5059;
  return null;
}
