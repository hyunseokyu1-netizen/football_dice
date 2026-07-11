/// 게임 설정 (shared_preferences로 영속화)
library;

import 'package:shared_preferences/shared_preferences.dart';

import 'sound.dart';

class GameSettings {
  GameSettings._();

  /// 주사위 롤링·카드 대결 연출 켜기/끄기
  static bool effects = true;

  /// 효과음 켜기/끄기
  static bool soundOn = true;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    effects = prefs.getBool('effects') ?? true;
    soundOn = prefs.getBool('soundOn') ?? true;
    SoundService.instance.muted = !soundOn;
  }

  static Future<void> setEffects(bool v) async {
    effects = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('effects', v);
  }

  static Future<void> setSoundOn(bool v) async {
    soundOn = v;
    SoundService.instance.muted = !v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('soundOn', v);
  }
}
