import 'package:flutter_test/flutter_test.dart';
import 'package:football_dice/data/cards.dart';
import 'package:football_dice/engine/ai.dart';
import 'package:football_dice/engine/engine.dart';
import 'package:football_dice/l10n/l10n.dart';

void main() {
  group('카드 데이터', () {
    test('모든 차트는 5행 10열', () {
      final charts = <List<List<String>>>[
        for (final c in offenseCards) c.chart,
        kickOffCard.chart,
        kickoffReturnCard.chart,
        puntReturnCard.chart,
        turnoverCard.chart,
        fumbleCard.chart,
        patFieldGoal.chart,
        fieldGoal2029.chart,
        fieldGoal3039.chart,
        fieldGoal4049.chart,
        fieldGoal5059.chart,
        longPuntCard.chart,
        shortPuntCard.chart,
        onSideKickCard.chart,
      ];
      for (final chart in charts) {
        expect(chart.length, 5);
        for (final row in chart) {
          expect(row.length, 10);
        }
      }
    });

    test('차트 셀은 숫자 또는 유효한 특수문자', () {
      final valid = RegExp(r'^(-?\d+|I|F|G|X|R)$');
      for (final c in offenseCards) {
        for (final row in c.chart) {
          for (final cell in row) {
            expect(valid.hasMatch(cell), true, reason: '${c.id}: $cell');
          }
        }
      }
    });

    test('수비 카드는 9개 공격 카드 전부에 대한 보정치를 가진다', () {
      for (final d in defenseCards) {
        for (final o in offenseCards) {
          expect(d.modifiers.containsKey(o.id), true,
              reason: '${d.id} → ${o.id}');
        }
      }
    });

    test('행/열 인덱스 계산', () {
      expect(columnIndex(2), 0);
      expect(columnIndex(3), 0);
      expect(columnIndex(10), 4);
      expect(columnIndex(12), 4);
      expect(columnIndex(24), 9);
      expect(rowIndex(10), 0);
      expect(rowIndex(9), 0);
      expect(rowIndex(1), 4);
      expect(rowIndex(5), 2);
      // 클램프
      expect(rowIndex(13), 0);
      expect(rowIndex(-2), 4);
    });

    test('필드골 카드 거리 선택', () {
      expect(fieldGoalCardFor(5)!.id, 'fg_1_19');
      expect(fieldGoalCardFor(19)!.id, 'fg_1_19');
      expect(fieldGoalCardFor(20)!.id, 'fg_20_29');
      expect(fieldGoalCardFor(59)!.id, 'fg_50_59');
      expect(fieldGoalCardFor(60), null);
    });
  });

  group('게임 엔진', () {
    test('킥오프로 시작해 공격권이 정해진다', () {
      final e = GameEngine(seed: 1);
      expect(e.state.phase, GamePhase.kickoff);
      e.kickoff();
      // 리턴까지 끝나면 play 또는 returnChoice
      expect(
        e.state.phase == GamePhase.play ||
            e.state.phase == GamePhase.returnChoice,
        true,
      );
    });

    test('AI끼리 풀시뮬레이션 100판 — 크래시/무한루프 없음', () {
      for (var seed = 0; seed < 100; seed++) {
        final e = GameEngine(seed: seed);
        final aiHome = AiPlayer(Team.home, seed: seed);
        final aiAway = AiPlayer(Team.away, seed: seed + 1000);
        var guard = 0;

        AiPlayer aiFor(Team t) => t == Team.home ? aiHome : aiAway;

        while (e.state.phase != GamePhase.gameOver && guard++ < 2000) {
          switch (e.state.phase) {
            case GamePhase.kickoff:
              final ai = aiFor(e.state.kickingTeam);
              if (ai.chooseOnsideKick(e.state)) {
                e.onsideKick();
              } else {
                e.kickoff();
              }
            case GamePhase.returnChoice:
              final ai = aiFor(e.state.possession);
              if (ai.chooseTouchback(e.state)) {
                e.chooseTouchback();
              } else {
                e.chooseReturn();
              }
            case GamePhase.play:
              final offAi = aiFor(e.state.possession);
              final defAi = aiFor(e.state.possession.opponent);
              final action = offAi.chooseOffense(e);
              switch (action.type) {
                case AiOffenseActionType.play:
                  e.runPlay(action.offenseCardId!, defAi.chooseDefense(e));
                case AiOffenseActionType.punt:
                  e.punt(action.longPunt);
                case AiOffenseActionType.fieldGoal:
                  e.fieldGoalAttempt();
              }
            case GamePhase.extraPoint:
              final ai = aiFor(e.state.possession);
              if (ai.chooseTwoPoint(e.state)) {
                e.twoPointConversion(
                  ai.chooseConversionPlay(),
                  aiFor(e.state.possession.opponent).chooseDefense(e),
                );
              } else {
                e.extraPointKick();
              }
            case GamePhase.gameOver:
              break;
          }
          // 공은 항상 필드 안(0~100)에 있어야 한다
          expect(e.state.ballPos >= 0 && e.state.ballPos <= 100, true,
              reason: 'seed $seed: ballPos ${e.state.ballPos}');
        }

        expect(guard < 2000, true, reason: 'seed $seed: 무한 루프 의심');
        expect(e.state.phase, GamePhase.gameOver, reason: 'seed $seed');
        expect(e.state.winner != null || e.state.isDraw, true,
            reason: 'seed $seed');
      }
    });

    test('영어 모드에서도 풀시뮬레이션이 정상 동작하고 로그가 영어로 나온다', () {
      setLanguage(AppLanguage.en);
      addTearDown(() => setLanguage(AppLanguage.ko));

      final e = GameEngine(seed: 42);
      final aiHome = AiPlayer(Team.home, seed: 42);
      final aiAway = AiPlayer(Team.away, seed: 1042);
      AiPlayer aiFor(Team t) => t == Team.home ? aiHome : aiAway;
      var guard = 0;

      while (e.state.phase != GamePhase.gameOver && guard++ < 2000) {
        switch (e.state.phase) {
          case GamePhase.kickoff:
            e.kickoff();
          case GamePhase.returnChoice:
            e.chooseTouchback();
          case GamePhase.play:
            final offAi = aiFor(e.state.possession);
            final defAi = aiFor(e.state.possession.opponent);
            final action = offAi.chooseOffense(e);
            switch (action.type) {
              case AiOffenseActionType.play:
                e.runPlay(action.offenseCardId!, defAi.chooseDefense(e));
              case AiOffenseActionType.punt:
                e.punt(action.longPunt);
              case AiOffenseActionType.fieldGoal:
                e.fieldGoalAttempt();
            }
          case GamePhase.extraPoint:
            e.extraPointKick();
          case GamePhase.gameOver:
            break;
        }
      }

      expect(e.state.phase, GamePhase.gameOver);
      // 게임 로그에 한국어가 섞여 있으면 안 된다
      final koreanLines =
          e.gameLog.where((l) => RegExp(r'[가-힣]').hasMatch(l));
      expect(koreanLines, isEmpty, reason: koreanLines.join('\n'));
    });

    test('시뮬레이션 점수가 현실적인 범위', () {
      var totalPoints = 0;
      const games = 50;
      for (var seed = 0; seed < games; seed++) {
        final e = GameEngine(seed: seed + 5000);
        final aiHome = AiPlayer(Team.home, seed: seed);
        final aiAway = AiPlayer(Team.away, seed: seed + 1000);
        AiPlayer aiFor(Team t) => t == Team.home ? aiHome : aiAway;
        var guard = 0;
        while (e.state.phase != GamePhase.gameOver && guard++ < 2000) {
          switch (e.state.phase) {
            case GamePhase.kickoff:
              aiFor(e.state.kickingTeam).chooseOnsideKick(e.state)
                  ? e.onsideKick()
                  : e.kickoff();
            case GamePhase.returnChoice:
              aiFor(e.state.possession).chooseTouchback(e.state)
                  ? e.chooseTouchback()
                  : e.chooseReturn();
            case GamePhase.play:
              final action = aiFor(e.state.possession).chooseOffense(e);
              switch (action.type) {
                case AiOffenseActionType.play:
                  e.runPlay(action.offenseCardId!,
                      aiFor(e.state.possession.opponent).chooseDefense(e));
                case AiOffenseActionType.punt:
                  e.punt(action.longPunt);
                case AiOffenseActionType.fieldGoal:
                  e.fieldGoalAttempt();
              }
            case GamePhase.extraPoint:
              e.extraPointKick();
            case GamePhase.gameOver:
              break;
          }
        }
        totalPoints += e.state.score[Team.home]! + e.state.score[Team.away]!;
      }
      final avg = totalPoints / games;
      // 한 경기 합계 평균이 0점 초과, 120점 미만이면 상식적
      expect(avg > 0 && avg < 120, true, reason: '평균 합계 득점: $avg');
    });
  });
}
