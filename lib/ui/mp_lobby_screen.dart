/// 멀티플레이 로비: 방 만들기(호스트) / 참가하기(게스트)
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../net/session.dart';
import 'mp_game_screen.dart';
import 'widgets.dart';

class MpLobbyScreen extends StatefulWidget {
  const MpLobbyScreen({super.key});

  @override
  State<MpLobbyScreen> createState() => _MpLobbyScreenState();
}

enum _Mode { menu, hosting, joining }

class _MpLobbyScreenState extends State<MpLobbyScreen> {
  _Mode mode = _Mode.menu;

  HostSession? _host;
  List<String> _myIps = const [];

  HostFinder? _finder;
  List<DiscoveredHost> _found = const [];
  StreamSubscription<List<DiscoveredHost>>? _findSub;
  final _ipCtrl = TextEditingController();
  bool _connecting = false;

  @override
  void dispose() {
    _stopHosting();
    _stopFinding();
    _ipCtrl.dispose();
    super.dispose();
  }

  void _stopHosting() {
    _host?.dispose();
    _host = null;
  }

  void _stopFinding() {
    _findSub?.cancel();
    _findSub = null;
    _finder?.dispose();
    _finder = null;
  }

  Future<void> _startHosting() async {
    try {
      final host = await HostSession.host();
      final ips = await localIpAddresses();
      if (!mounted) {
        host.dispose();
        return;
      }
      setState(() {
        _host = host;
        _myIps = ips;
        mode = _Mode.hosting;
      });
      await host.onGuestConnected;
      if (!mounted) return;
      final session = _host;
      _host = null; // 게임 화면이 세션 소유권을 가져간다
      if (session == null) return;
      await Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => MpGameScreen(session: session)));
      if (mounted) setState(() => mode = _Mode.menu);
    } catch (_) {
      if (mounted) {
        setState(() => mode = _Mode.menu);
        _showError(loc.connectionFailed);
      }
    }
  }

  Future<void> _startJoining() async {
    setState(() {
      mode = _Mode.joining;
      _found = const [];
    });
    final finder = HostFinder();
    _finder = finder;
    _findSub = finder.hosts.listen((list) {
      if (mounted) setState(() => _found = list);
    });
    try {
      await finder.start();
    } catch (_) {
      // 검색 실패해도 수동 IP 입력은 가능
    }
  }

  Future<void> _connectTo(String ip) async {
    if (_connecting || ip.isEmpty) return;
    setState(() => _connecting = true);
    try {
      final session = await GuestSession.connect(ip.trim());
      if (!mounted) {
        session.dispose();
        return;
      }
      _stopFinding();
      setState(() => _connecting = false);
      await Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => MpGameScreen(session: session)));
      if (mounted) setState(() => mode = _Mode.menu);
    } catch (_) {
      if (mounted) {
        setState(() => _connecting = false);
        _showError(loc.connectionFailed);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        foregroundColor: kGold,
        title: Text(loc.mpTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        leading: BackButton(onPressed: () {
          if (mode == _Mode.menu) {
            Navigator.of(context).pop();
          } else {
            _stopHosting();
            _stopFinding();
            setState(() => mode = _Mode.menu);
          }
        }),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: switch (mode) {
                _Mode.menu => _menu(),
                _Mode.hosting => _hostingView(),
                _Mode.joining => _joiningView(),
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _menu() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('📶', style: TextStyle(fontSize: 56)),
        const SizedBox(height: 24),
        _modeButton(
          icon: Icons.home,
          title: loc.hostGame,
          subtitle: loc.hostGameDesc,
          onTap: _startHosting,
        ),
        const SizedBox(height: 12),
        _modeButton(
          icon: Icons.search,
          title: loc.joinGame,
          subtitle: loc.joinGameDesc,
          onTap: _startJoining,
        ),
      ],
    );
  }

  Widget _modeButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white24),
          padding: const EdgeInsets.all(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: kGold, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hostingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: kGold),
        const SizedBox(height: 24),
        Text(loc.waitingForFriend,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 16),
        for (final ip in _myIps)
          Text(loc.yourIp(ip),
              style: const TextStyle(color: kGold, fontSize: 13)),
      ],
    );
  }

  Widget _joiningView() {
    return Column(
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(color: kGold, strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(loc.searchingHosts,
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _found.isEmpty
              ? const SizedBox.shrink()
              : ListView(
                  children: [
                    for (final h in _found)
                      Card(
                        color: const Color(0xFF1E2A1E),
                        child: ListTile(
                          leading:
                              const Icon(Icons.sports_football, color: kGold),
                          title: Text(h.name,
                              style: const TextStyle(color: Colors.white)),
                          subtitle: Text(h.ip,
                              style:
                                  const TextStyle(color: Colors.white54)),
                          onTap: () => _connectTo(h.ip),
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ipCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: loc.manualIpHint,
                  hintStyle:
                      const TextStyle(color: Colors.white38, fontSize: 12),
                  enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: kGold)),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed:
                  _connecting ? null : () => _connectTo(_ipCtrl.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: kGold,
                foregroundColor: Colors.black,
              ),
              child: _connecting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(loc.connectButton,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }
}
