/// 멀티플레이 세션.
///
/// [HostSession]: 방을 만들고 엔진을 직접 돌린다 (HOME 팀).
/// [GuestSession]: 호스트에 접속해 선택을 보내고 상태를 받는다 (AWAY 팀).
/// 두 클래스 모두 [MpSession] 인터페이스로 UI에 노출된다.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../engine/engine.dart';
import 'protocol.dart';

/// 멀티플레이 게임 화면이 사용하는 공통 인터페이스
abstract class MpSession {
  /// 내가 조종하는 팀 (호스트 = home, 게스트 = away)
  Team get myTeam;

  GameState get state;
  Resolution? get lastResolution;

  /// 최근 판정 당시의 공격팀 (카드 연출 방향 결정용)
  Team? get lastOffTeam;

  /// 판정마다 증가 (애니메이션 트리거)
  int get version;

  /// 2점 컨버전 카드 선택 대기 중인지
  bool get awaiting2pt;

  /// 이번 플레이에서 내 선택을 이미 보냈는지 (상대 대기 표시용)
  bool get iSubmitted;

  /// 연결 오류 (null이면 정상)
  String? get error;

  /// 상태가 바뀔 때마다 이벤트
  Stream<void> get updates;

  void chooseKickoff({required bool onside});
  void chooseReturn({required bool touchback});
  void chooseOffense(String cardId);
  void choosePunt({required bool long});
  void chooseFieldGoal();
  void chooseDefense(String cardId);
  void chooseExtraPoint({required bool twoPoint});
  void restart();
  void dispose();
}

/// 이 기기의 Wi-Fi IPv4 주소 목록
Future<List<String>> localIpAddresses() async {
  final result = <String>[];
  for (final ni
      in await NetworkInterface.list(type: InternetAddressType.IPv4)) {
    for (final addr in ni.addresses) {
      if (!addr.isLoopback) result.add(addr.address);
    }
  }
  // 사설망 주소(192.168.x 등)를 앞으로
  result.sort((a, b) =>
      (b.startsWith('192.168.') ? 1 : 0) - (a.startsWith('192.168.') ? 1 : 0));
  return result;
}

// ---------------------------------------------------------------------------
// 호스트
// ---------------------------------------------------------------------------

class HostSession implements MpSession {
  HostSession._(this._server);

  final ServerSocket _server;
  RawDatagramSocket? _beacon;
  Socket? _guest;
  StreamSubscription<String>? _guestSub;

  GameEngine _engine = GameEngine();

  String? _pendingOffCard;
  String? _pendingDefCard;
  bool _awaiting2pt = false;
  Resolution? _lastRes;
  Team? _lastOffTeam;
  int _version = 0;
  String? _error;

  final _updates = StreamController<void>.broadcast();
  final _connected = Completer<void>();

  /// 게스트가 접속하면 완료
  Future<void> get onGuestConnected => _connected.future;

  static Future<HostSession> host() async {
    final server = await ServerSocket.bind(InternetAddress.anyIPv4, kGamePort,
        shared: true);
    final s = HostSession._(server);
    await s._startBeacon();
    server.listen(s._onGuestSocket, onError: (Object _) {});
    return s;
  }

  /// UDP 검색 프로브에 응답하는 비콘
  Future<void> _startBeacon() async {
    try {
      _beacon = await RawDatagramSocket.bind(
          InternetAddress.anyIPv4, kDiscoveryPort,
          reuseAddress: true);
      _beacon!.listen((event) {
        if (event != RawSocketEvent.read) return;
        final dg = _beacon!.receive();
        if (dg == null) return;
        String text;
        try {
          text = utf8.decode(dg.data);
        } catch (_) {
          return;
        }
        if (text == kDiscoverProbe) {
          final reply = jsonEncode({
            'pf': kProtocolVersion,
            'name': Platform.localHostname,
            'port': kGamePort,
          });
          _beacon!.send(utf8.encode(reply), dg.address, dg.port);
        }
      });
    } catch (_) {
      // 비콘 실패해도 수동 IP 접속은 가능하므로 무시
    }
  }

  void _onGuestSocket(Socket sock) {
    if (_guest != null) {
      sock.destroy(); // 2인용: 추가 접속 거절
      return;
    }
    _guest = sock;
    _guestSub = sock
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_onGuestLine, onDone: _onGuestGone, onError: (Object _) {
      _onGuestGone();
    });
    _send({'t': 'welcome', 'v': kProtocolVersion, 'youAre': Team.away.name});
    _broadcast();
    if (!_connected.isCompleted) _connected.complete();
  }

  void _onGuestGone() {
    if (_error != null) return;
    _error = 'disconnected';
    _updates.add(null);
  }

  void _onGuestLine(String line) {
    Map<String, dynamic> msg;
    try {
      msg = jsonDecode(line) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    _input(Team.away, msg);
  }

  void _send(Map<String, dynamic> msg) {
    try {
      _guest?.write('${jsonEncode(msg)}\n');
    } catch (_) {
      _onGuestGone();
    }
  }

  void _broadcast() {
    final res = _lastRes;
    _send({
      't': 'state',
      'version': _version,
      'state': encodeState(_engine.state),
      'resolution': res == null ? null : encodeResolution(res),
      'offTeam': _lastOffTeam?.name,
      'awaiting2pt': _awaiting2pt,
    });
    _updates.add(null);
  }

  void _show(Resolution r, {Team? offTeam}) {
    _lastRes = r;
    _lastOffTeam = offTeam;
    _version++;
    _pendingOffCard = null;
    _pendingDefCard = null;
    _broadcast();
  }

  // ---- 입력 처리 (호스트 로컬 + 게스트 공용) ----

  void _input(Team from, Map<String, dynamic> msg) {
    final s = _engine.state;
    switch (msg['t']) {
      case 'kickoff':
        if (s.phase != GamePhase.kickoff || from != s.kickingTeam) return;
        final r = (msg['onside'] as bool? ?? false)
            ? _engine.onsideKick()
            : _engine.kickoff();
        _show(r);
      case 'return':
        if (s.phase != GamePhase.returnChoice || from != s.possession) return;
        final r = (msg['touchback'] as bool? ?? true)
            ? _engine.chooseTouchback()
            : _engine.chooseReturn();
        _show(r);
      case 'offense':
        final cardId = msg['cardId'] as String?;
        if (cardId == null || from != s.possession) return;
        final isPlay = s.phase == GamePhase.play;
        final is2pt = s.phase == GamePhase.extraPoint && _awaiting2pt;
        if (!isPlay && !is2pt) return;
        _pendingOffCard = cardId;
        _tryResolveCards();
      case 'defense':
        final cardId = msg['cardId'] as String?;
        if (cardId == null || from != s.possession.opponent) return;
        final isPlay = s.phase == GamePhase.play;
        final is2pt = s.phase == GamePhase.extraPoint && _awaiting2pt;
        if (!isPlay && !is2pt) return;
        _pendingDefCard = cardId;
        _tryResolveCards();
      case 'punt':
        if (from != s.possession || !_engine.canPunt) return;
        final r = _engine.punt(msg['long'] as bool? ?? true);
        _show(r);
      case 'fieldGoal':
        if (from != s.possession || _engine.availableFieldGoal == null) return;
        _show(_engine.fieldGoalAttempt());
      case 'extraPoint':
        if (s.phase != GamePhase.extraPoint ||
            from != s.possession ||
            _awaiting2pt) {
          return;
        }
        if (msg['twoPoint'] as bool? ?? false) {
          _awaiting2pt = true;
          _broadcast();
        } else {
          _show(_engine.extraPointKick());
        }
      case 'restart':
        _engine = GameEngine();
        _pendingOffCard = null;
        _pendingDefCard = null;
        _awaiting2pt = false;
        _lastRes = null;
        _lastOffTeam = null;
        _version++;
        _broadcast();
    }
  }

  void _tryResolveCards() {
    final off = _pendingOffCard, def = _pendingDefCard;
    if (off == null || def == null) {
      _updates.add(null); // 내 선택 반영 (대기 표시)
      return;
    }
    final offTeam = _engine.state.possession;
    final Resolution r;
    if (_awaiting2pt) {
      _awaiting2pt = false;
      r = _engine.twoPointConversion(off, def);
    } else {
      r = _engine.runPlay(off, def);
    }
    _show(r, offTeam: offTeam);
  }

  // ---- MpSession ----

  @override
  Team get myTeam => Team.home;
  @override
  GameState get state => _engine.state;
  @override
  Resolution? get lastResolution => _lastRes;
  @override
  Team? get lastOffTeam => _lastOffTeam;
  @override
  int get version => _version;
  @override
  bool get awaiting2pt => _awaiting2pt;
  @override
  bool get iSubmitted => state.possession == Team.home
      ? _pendingOffCard != null
      : _pendingDefCard != null;
  @override
  String? get error => _error;
  @override
  Stream<void> get updates => _updates.stream;

  @override
  void chooseKickoff({required bool onside}) =>
      _input(Team.home, {'t': 'kickoff', 'onside': onside});
  @override
  void chooseReturn({required bool touchback}) =>
      _input(Team.home, {'t': 'return', 'touchback': touchback});
  @override
  void chooseOffense(String cardId) =>
      _input(Team.home, {'t': 'offense', 'cardId': cardId});
  @override
  void choosePunt({required bool long}) =>
      _input(Team.home, {'t': 'punt', 'long': long});
  @override
  void chooseFieldGoal() => _input(Team.home, {'t': 'fieldGoal'});
  @override
  void chooseDefense(String cardId) =>
      _input(Team.home, {'t': 'defense', 'cardId': cardId});
  @override
  void chooseExtraPoint({required bool twoPoint}) =>
      _input(Team.home, {'t': 'extraPoint', 'twoPoint': twoPoint});
  @override
  void restart() => _input(Team.home, {'t': 'restart'});

  @override
  void dispose() {
    _guestSub?.cancel();
    _guest?.destroy();
    _beacon?.close();
    _server.close();
    _updates.close();
  }
}

// ---------------------------------------------------------------------------
// 게스트
// ---------------------------------------------------------------------------

class GuestSession implements MpSession {
  GuestSession._(this._sock);

  final Socket _sock;
  StreamSubscription<String>? _sub;

  GameState _state = GameState();
  Resolution? _lastRes;
  Team? _lastOffTeam;
  int _version = 0;
  bool _awaiting2pt = false;
  bool _iSubmitted = false;
  String? _error;

  final _updates = StreamController<void>.broadcast();

  static Future<GuestSession> connect(String host) async {
    final sock = await Socket.connect(host, kGamePort,
        timeout: const Duration(seconds: 5));
    final s = GuestSession._(sock);
    final firstState = Completer<void>();
    s._sub = sock
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      s._onLine(line);
      if (s._version >= 0 &&
          !firstState.isCompleted &&
          s._gotFirstState) {
        firstState.complete();
      }
    }, onDone: s._onGone, onError: (Object _) {
      s._onGone();
      if (!firstState.isCompleted) {
        firstState.completeError(const SocketException('closed'));
      }
    });
    await firstState.future.timeout(const Duration(seconds: 5));
    return s;
  }

  bool _gotFirstState = false;

  void _onGone() {
    if (_error != null) return;
    _error = 'disconnected';
    if (!_updates.isClosed) _updates.add(null);
  }

  void _onLine(String line) {
    Map<String, dynamic> msg;
    try {
      msg = jsonDecode(line) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    if (msg['t'] != 'state') return;
    _state = decodeState(msg['state'] as Map<String, dynamic>);
    final resJson = msg['resolution'] as Map<String, dynamic>?;
    _lastRes = resJson == null ? null : decodeResolution(resJson);
    final offTeam = msg['offTeam'] as String?;
    _lastOffTeam = offTeam == null ? null : Team.values.byName(offTeam);
    _awaiting2pt = msg['awaiting2pt'] as bool? ?? false;
    final newVersion = msg['version'] as int;
    if (newVersion != _version) _iSubmitted = false;
    _version = newVersion;
    _gotFirstState = true;
    _updates.add(null);
  }

  void _send(Map<String, dynamic> msg) {
    try {
      _sock.write('${jsonEncode(msg)}\n');
    } catch (_) {
      _onGone();
    }
  }

  // ---- MpSession ----

  @override
  Team get myTeam => Team.away;
  @override
  GameState get state => _state;
  @override
  Resolution? get lastResolution => _lastRes;
  @override
  Team? get lastOffTeam => _lastOffTeam;
  @override
  int get version => _version;
  @override
  bool get awaiting2pt => _awaiting2pt;
  @override
  bool get iSubmitted => _iSubmitted;
  @override
  String? get error => _error;
  @override
  Stream<void> get updates => _updates.stream;

  @override
  void chooseKickoff({required bool onside}) =>
      _send({'t': 'kickoff', 'onside': onside});
  @override
  void chooseReturn({required bool touchback}) =>
      _send({'t': 'return', 'touchback': touchback});
  @override
  void chooseOffense(String cardId) {
    _iSubmitted = true;
    _send({'t': 'offense', 'cardId': cardId});
    _updates.add(null);
  }

  @override
  void choosePunt({required bool long}) => _send({'t': 'punt', 'long': long});
  @override
  void chooseFieldGoal() => _send({'t': 'fieldGoal'});
  @override
  void chooseDefense(String cardId) {
    _iSubmitted = true;
    _send({'t': 'defense', 'cardId': cardId});
    _updates.add(null);
  }

  @override
  void chooseExtraPoint({required bool twoPoint}) =>
      _send({'t': 'extraPoint', 'twoPoint': twoPoint});
  @override
  void restart() => _send({'t': 'restart'});

  @override
  void dispose() {
    _sub?.cancel();
    _sock.destroy();
    _updates.close();
  }
}

// ---------------------------------------------------------------------------
// 방 검색 (게스트용)
// ---------------------------------------------------------------------------

class DiscoveredHost {
  final String ip;
  final String name;
  const DiscoveredHost(this.ip, this.name);
}

class HostFinder {
  RawDatagramSocket? _sock;
  Timer? _timer;
  final Map<String, DiscoveredHost> _found = {};
  final _hostsCtrl = StreamController<List<DiscoveredHost>>.broadcast();

  Stream<List<DiscoveredHost>> get hosts => _hostsCtrl.stream;

  Future<void> start() async {
    _sock = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    _sock!.broadcastEnabled = true;
    _sock!.listen((event) {
      if (event != RawSocketEvent.read) return;
      final dg = _sock!.receive();
      if (dg == null) return;
      try {
        final msg = jsonDecode(utf8.decode(dg.data)) as Map<String, dynamic>;
        if (msg['pf'] != kProtocolVersion) return;
        final ip = dg.address.address;
        _found[ip] = DiscoveredHost(ip, msg['name'] as String? ?? ip);
        _hostsCtrl.add(_found.values.toList());
      } catch (_) {
        // 무시
      }
    });
    void probe() {
      try {
        _sock?.send(utf8.encode(kDiscoverProbe),
            InternetAddress('255.255.255.255'), kDiscoveryPort);
      } catch (_) {
        // 일부 네트워크는 브로드캐스트 차단 — 수동 IP로 대체 가능
      }
    }

    probe();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => probe());
  }

  void dispose() {
    _timer?.cancel();
    _sock?.close();
    _hostsCtrl.close();
  }
}
