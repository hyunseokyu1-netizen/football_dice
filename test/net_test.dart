import 'package:flutter_test/flutter_test.dart';
import 'package:football_dice/engine/engine.dart';
import 'package:football_dice/net/protocol.dart';
import 'package:football_dice/net/session.dart';

void main() {
  group('프로토콜', () {
    test('GameState 직렬화 왕복', () {
      final s = GameState()
        ..ballPos = 37
        ..possession = Team.away
        ..down = 3
        ..firstDownTarget = 27
        ..quarter = 2
        ..playCount = 9
        ..phase = GamePhase.play
        ..kickingTeam = Team.home
        ..pendingReturn = PendingReturn.punt
        ..overtime = false;
      s.score[Team.home] = 14;
      s.score[Team.away] = 7;

      final restored = decodeState(encodeState(s));
      expect(restored.ballPos, 37);
      expect(restored.possession, Team.away);
      expect(restored.down, 3);
      expect(restored.firstDownTarget, 27);
      expect(restored.quarter, 2);
      expect(restored.playCount, 9);
      expect(restored.phase, GamePhase.play);
      expect(restored.score[Team.home], 14);
      expect(restored.score[Team.away], 7);
      expect(restored.winner, null);
    });

    test('Resolution 직렬화 왕복', () {
      final r = Resolution()
        ..offD10 = 9
        ..defD10 = 4
        ..offD12 = 7
        ..defD12 = 11
        ..offCardId = 'short_pass'
        ..defCardId = 'zone'
        ..row = 1
        ..col = 5
        ..cellValue = '6';
      r.log.addAll(['첫 줄', '둘째 줄']);
      r.ballPath.addAll([50, 56]);
      r.sfx.add(SfxEvent.score);

      final restored = decodeResolution(encodeResolution(r));
      expect(restored.log, ['첫 줄', '둘째 줄']);
      expect(restored.offD10, 9);
      expect(restored.offCardId, 'short_pass');
      expect(restored.ballPath, [50, 56]);
      expect(restored.sfx.contains(SfxEvent.score), true);
    });
  });

  group('호스트-게스트 세션', () {
    test('루프백 연결 후 킥오프까지 상태가 동기화된다', () async {
      final host = await HostSession.host();
      final guest = await GuestSession.connect('127.0.0.1');
      await host.onGuestConnected;

      expect(host.myTeam, Team.home);
      expect(guest.myTeam, Team.away);
      expect(guest.state.phase, GamePhase.kickoff);

      // 킥오프 담당 팀이 찬다
      if (host.state.kickingTeam == Team.home) {
        host.chooseKickoff(onside: false);
      } else {
        guest.chooseKickoff(onside: false);
      }
      await Future<void>.delayed(const Duration(milliseconds: 400));

      expect(host.version, greaterThan(0));
      expect(guest.version, host.version);
      expect(guest.state.phase, host.state.phase);
      expect(guest.state.ballPos, host.state.ballPos);
      expect(guest.lastResolution, isNotNull);

      guest.dispose();
      host.dispose();
    });
  });
}
