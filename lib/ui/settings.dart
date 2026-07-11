/// 게임 설정 (shared_preferences로 영속화)
library;

import 'package:shared_preferences/shared_preferences.dart';

class GameSettings {
  GameSettings._();

  /// 주사위 롤링·카드 대결 연출 켜기/끄기
  static bool effects = true;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    effects = prefs.getBool('effects') ?? true;
  }

  static Future<void> setEffects(bool v) async {
    effects = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('effects', v);
  }
}
