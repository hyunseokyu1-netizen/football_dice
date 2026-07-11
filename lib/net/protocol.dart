/// 로컬 네트워크(같은 Wi-Fi) 대전용 프로토콜.
///
/// - TCP [kGamePort]: 게임 메시지 (줄바꿈으로 구분된 JSON)
/// - UDP [kDiscoveryPort]: 방 검색 (게스트가 프로브를 브로드캐스트하면
///   호스트가 자기 정보로 응답)
///
/// 호스트가 유일한 판정 권한을 가진다. 게스트는 선택만 보내고,
/// 호스트가 엔진을 돌린 뒤 전체 상태를 브로드캐스트한다.
library;

import '../engine/engine.dart';

const kGamePort = 47846;
const kDiscoveryPort = 47845;
const kDiscoverProbe = 'pf_discover_v1';
const kProtocolVersion = 1;

Map<String, dynamic> encodeState(GameState s) => {
      'ballPos': s.ballPos,
      'possession': s.possession.name,
      'down': s.down,
      'firstDownTarget': s.firstDownTarget,
      'quarter': s.quarter,
      'playCount': s.playCount,
      'scoreHome': s.score[Team.home],
      'scoreAway': s.score[Team.away],
      'phase': s.phase.name,
      'kickingTeam': s.kickingTeam.name,
      'pendingReturn': s.pendingReturn.name,
      'overtime': s.overtime,
      'winner': s.winner?.name,
      'isDraw': s.isDraw,
    };

GameState decodeState(Map<String, dynamic> j) {
  final s = GameState()
    ..ballPos = j['ballPos'] as int
    ..possession = Team.values.byName(j['possession'] as String)
    ..down = j['down'] as int
    ..firstDownTarget = j['firstDownTarget'] as int?
    ..quarter = j['quarter'] as int
    ..playCount = j['playCount'] as int
    ..phase = GamePhase.values.byName(j['phase'] as String)
    ..kickingTeam = Team.values.byName(j['kickingTeam'] as String)
    ..pendingReturn = PendingReturn.values.byName(j['pendingReturn'] as String)
    ..overtime = j['overtime'] as bool
    ..isDraw = j['isDraw'] as bool;
  s.score[Team.home] = j['scoreHome'] as int;
  s.score[Team.away] = j['scoreAway'] as int;
  final w = j['winner'] as String?;
  s.winner = w == null ? null : Team.values.byName(w);
  return s;
}

Map<String, dynamic> encodeResolution(Resolution r) => {
      'log': r.log,
      'offD10': r.offD10,
      'defD10': r.defD10,
      'offD12': r.offD12,
      'defD12': r.defD12,
      'offCardId': r.offCardId,
      'defCardId': r.defCardId,
      'chartCardId': r.chartCardId,
      'row': r.row,
      'col': r.col,
      'cellValue': r.cellValue,
      'ballPath': r.ballPath,
      'sfx': [for (final e in r.sfx) e.name],
    };

Resolution decodeResolution(Map<String, dynamic> j) {
  final r = Resolution()
    ..offD10 = j['offD10'] as int?
    ..defD10 = j['defD10'] as int?
    ..offD12 = j['offD12'] as int?
    ..defD12 = j['defD12'] as int?
    ..offCardId = j['offCardId'] as String?
    ..defCardId = j['defCardId'] as String?
    ..chartCardId = j['chartCardId'] as String?
    ..row = j['row'] as int?
    ..col = j['col'] as int?
    ..cellValue = j['cellValue'] as String?;
  for (final line in (j['log'] as List)) {
    r.log.add(line as String);
  }
  r.ballPath.addAll([for (final p in j['ballPath'] as List) p as int]);
  for (final name in (j['sfx'] as List)) {
    r.sfx.add(SfxEvent.values.byName(name as String));
  }
  return r;
}
