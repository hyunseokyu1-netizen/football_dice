/// 설정 화면 (언어 · 주사위/카드 연출 · 효과음).
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/l10n.dart';
import 'settings.dart';
import 'widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _changeLanguage(AppLanguage lang) async {
    setState(() => setLanguage(lang));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang.name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        foregroundColor: Colors.white70,
        title: Text(
          loc.settingsTitle,
          style: const TextStyle(color: kGold, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                leading: const Icon(Icons.language, color: Colors.white54),
                title: Text(
                  loc.languageLabel,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                trailing: SegmentedButton<AppLanguage>(
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
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
              const Divider(color: Colors.white12),
              SwitchListTile(
                secondary: const Icon(Icons.casino, color: Colors.white54),
                title: Text(
                  loc.effectsLabel,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                value: GameSettings.effects,
                activeThumbColor: kGold,
                onChanged: (v) => setState(() => GameSettings.setEffects(v)),
              ),
              SwitchListTile(
                secondary: Icon(
                  GameSettings.soundOn ? Icons.volume_up : Icons.volume_off,
                  color: Colors.white54,
                ),
                title: Text(
                  loc.soundLabel,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                value: GameSettings.soundOn,
                activeThumbColor: kGold,
                onChanged: (v) => setState(() => GameSettings.setSoundOn(v)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
