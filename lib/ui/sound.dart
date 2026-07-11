/// 효과음 재생 서비스
library;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundService {
  static final SoundService instance = SoundService._();
  SoundService._();

  bool muted = false;

  Future<void> _play(String name) async {
    if (muted) return;
    try {
      final player = AudioPlayer();
      player.onPlayerComplete.listen((_) => player.dispose());
      await player.play(AssetSource('sfx/$name.wav'), volume: 0.8);
    } catch (e) {
      // 사운드 실패는 게임 진행에 영향 없음
      debugPrint('sfx error: $e');
    }
  }

  Future<void> dice() => _play('dice');
  Future<void> whistle() => _play('whistle');
  Future<void> score() => _play('score');
  Future<void> bad() => _play('bad');
  Future<void> kick() => _play('kick');
}
