import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_dice/main.dart';
import 'package:football_dice/ui/widgets.dart';

void main() {
  testWidgets('홈 → 게임 화면 → 여러 플레이 진행 스모크 테스트', (tester) async {
    // 폰 세로 화면 크기
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const FootballDiceApp());
    expect(find.text('새 게임'), findsOneWidget);

    await tester.tap(find.text('새 게임'));
    await tester.pumpAndSettle();

    // 최대 60 스텝 동안 상황에 맞는 버튼을 눌러가며 진행
    for (var step = 0; step < 60; step++) {
      await tester.pump(const Duration(seconds: 1));

      // 카드 대결 연출이 떠 있으면 탭해서 스킵
      if (find.byType(CardFlyby).evaluate().isNotEmpty) {
        await tester.tap(find.byType(CardFlyby));
        await tester.pump();
      }

      if (find.text('킥오프').evaluate().isNotEmpty) {
        await tester.tap(find.text('킥오프'));
      } else if (find.textContaining('터치백 (').evaluate().isNotEmpty) {
        await tester.tap(find.textContaining('터치백 ('));
      } else if (find.text('전체 플레이북').evaluate().isNotEmpty) {
        // 공격: 추천 카드 선택 후 실행
        await tester.tap(find.byType(GameplanCard).first);
        await tester.pump();
        await tester.tap(find.textContaining('실행!'));
      } else if (find.text('전체 수비 대형').evaluate().isNotEmpty) {
        // 수비: 추천 대형 선택 후 실행
        await tester.tap(find.byType(GameplanCard).first);
        await tester.pump();
        await tester.tap(find.textContaining('수비!').last);
      } else if (find.textContaining('추가 킥 (').evaluate().isNotEmpty) {
        await tester.tap(find.textContaining('추가 킥 ('));
      } else if (find.textContaining('리턴!').evaluate().isNotEmpty) {
        await tester.tap(find.text('리턴!'));
      }
      // 공 이동 애니메이션(최대 2.2초) 소화
      await tester.pump(const Duration(milliseconds: 2500));

      // 예외 없이 진행되는지 확인
      expect(tester.takeException(), isNull, reason: 'step $step');
    }

    // 스코어보드가 계속 표시되고 있어야 한다
    expect(find.textContaining('PLAY '), findsOneWidget);
  });
}
