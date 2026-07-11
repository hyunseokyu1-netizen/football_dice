import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'engine/ai.dart';
import 'l10n/l10n.dart';
import 'ui/game_screen.dart';
import 'ui/mp_lobby_screen.dart';
import 'ui/settings.dart';
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

  Future<void> _changeLanguage(AppLanguage lang) async {
    setState(() => setLanguage(lang));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang.name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
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
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(height: 28),
                // 언어 선택
                SegmentedButton<AppLanguage>(
                  segments: const [
                    ButtonSegment(value: AppLanguage.ko, label: Text('한국어')),
                    ButtonSegment(
                      value: AppLanguage.en,
                      label: Text('English'),
                    ),
                  ],
                  selected: {loc.lang},
                  onSelectionChanged: (set) => _changeLanguage(set.first),
                  style: SegmentedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    selectedForegroundColor: Colors.black,
                    selectedBackgroundColor: kGold,
                    side: const BorderSide(color: Colors.white24),
                  ),
                ),
                const SizedBox(height: 12),
                // 난이도 선택
                SegmentedButton<Difficulty>(
                  segments: [
                    for (final d in Difficulty.values)
                      ButtonSegment(value: d, label: Text(_difficultyLabel(d))),
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
                const SizedBox(height: 16),
                // 주사위·카드 연출 켜기/끄기
                SizedBox(
                  width: 240,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.casino, color: Colors.white54, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        loc.effectsLabel,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Switch(
                        value: GameSettings.effects,
                        activeThumbColor: kGold,
                        onChanged: (v) =>
                            setState(() => GameSettings.setEffects(v)),
                      ),
                    ],
                  ),
                ),
                // 효과음 켜기/끄기
                SizedBox(
                  width: 240,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        GameSettings.soundOn
                            ? Icons.volume_up
                            : Icons.volume_off,
                        color: Colors.white54,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        loc.soundLabel,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Switch(
                        value: GameSettings.soundOn,
                        activeThumbColor: kGold,
                        onChanged: (v) =>
                            setState(() => GameSettings.setSoundOn(v)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
          child: Text(
            loc.howToPlayBody,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.4,
            ),
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
