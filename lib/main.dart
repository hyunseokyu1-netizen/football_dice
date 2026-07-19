import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/cards.dart';
import 'engine/ai.dart';
import 'l10n/l10n.dart';
import 'ui/game_screen.dart';
import 'ui/mp_lobby_screen.dart';
import 'ui/settings.dart';
import 'ui/settings_screen.dart';
import 'ui/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 세로 화면 고정
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  // 저장된 언어/설정 불러오기
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getString('language') == AppLanguage.en.name) {
    setLanguage(AppLanguage.en);
  }
  await GameSettings.load();
  runApp(const FootballDiceApp());
}

class FootballDiceApp extends StatelessWidget {
  const FootballDiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Football Dice',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Difficulty difficulty = Difficulty.normal;

  String _difficultyLabel(Difficulty d) => switch (d) {
    Difficulty.easy => loc.difficultyEasy,
    Difficulty.normal => loc.difficultyNormal,
    Difficulty.hard => loc.difficultyHard,
  };

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
    );
    // 설정에서 언어가 바뀌었을 수 있으므로 다시 그린다
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                onPressed: _openSettings,
                icon: const Icon(Icons.settings),
                color: Colors.white54,
                tooltip: loc.settingsTitle,
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🏈', style: TextStyle(fontSize: 72)),
                    const SizedBox(height: 16),
                    const Text(
                      'FOOTBALL\nDICE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: kGold,
                        height: 1.1,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      loc.appSubtitle,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 28),
                    // 난이도 선택
                    SegmentedButton<Difficulty>(
                      segments: [
                        for (final d in Difficulty.values)
                          ButtonSegment(
                            value: d,
                            label: Text(_difficultyLabel(d)),
                          ),
                      ],
                      selected: {difficulty},
                      onSelectionChanged: (set) =>
                          setState(() => difficulty = set.first),
                      style: SegmentedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        selectedForegroundColor: Colors.black,
                        selectedBackgroundColor: kGold,
                        side: const BorderSide(color: Colors.white24),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 220,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => GameScreen(difficulty: difficulty),
                          ),
                        ),
                        icon: const Icon(Icons.play_arrow),
                        label: Text(
                          loc.newGame,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF33691E),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 220,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const MpLobbyScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.wifi, size: 18),
                        label: Text(
                          loc.mpButton,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kGold,
                          side: const BorderSide(color: kGold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 220,
                      child: OutlinedButton.icon(
                        onPressed: () => _showHowToPlay(context),
                        icon: const Icon(Icons.help_outline, size: 18),
                        label: Text(loc.howToPlay),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white24),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHowToPlay(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF212121),
        title: Text(
          loc.howToPlay,
          style: const TextStyle(color: kGold, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.howToPlayBody,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              const _HowToPlayExample(),
              const SizedBox(height: 12),
              Text(
                loc.howToPlayBody2,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc.close, style: const TextStyle(color: kGold)),
          ),
        ],
      ),
    );
  }
}

/// 게임 방법 다이얼로그의 주사위 → 차트 예시.
///
/// 숏 패스 카드로 "공격 D10 9, 수비 보정 -2, D12 합 14" 상황을
/// 실제 게임과 같은 모양의 주사위 칩과 [ChartTable]로 보여준다.
class _HowToPlayExample extends StatelessWidget {
  const _HowToPlayExample();

  Widget _die(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24),
            ),
            child: Text(
              '$value',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 9),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = offenseById('short_pass');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Text(
            loc.howToPlayExampleTitle,
            style: const TextStyle(
              color: kGold,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _die(loc.offD10Label, 9, const Color(0xFFC62828)),
              _die(loc.defD10Label, 5, const Color(0xFF283593)),
              _die('D12', 6, const Color(0xFFAD1457)),
              _die('D12', 8, const Color(0xFF4527A0)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            loc.howToPlayExampleDice,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 8),
          FittedBox(
            child: ChartTable(
              chart: card.chart,
              highlightRow: rowIndex(9 - 2),
              highlightCol: columnIndex(6 + 8),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            loc.howToPlayExampleResult,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFFFE082), fontSize: 11),
          ),
        ],
      ),
    );
  }
}
