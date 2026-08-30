import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/task.dart';
import '../utils/time_format.dart';
import 'ice_painters.dart';

String _kakigoriAssetForColor(Color color) {
  final hex = color.toARGB32();
  final map = <int, String>{
    const Color(0xfff25050).toARGB32(): 'assets/images/red.png',
    const Color(0xfff2993d).toARGB32(): 'assets/images/orange.png',
    const Color(0xfff4df45).toARGB32(): 'assets/images/yellow.png',
    const Color(0xff9bd75d).toARGB32(): 'assets/images/yellowgreen.png',
    const Color(0xff3fa9f5).toARGB32(): 'assets/images/blue.png',
    const Color(0xff9b5de5).toARGB32(): 'assets/images/purple.png',
    const Color(0xff2ec4b6).toARGB32(): 'assets/images/green.png',
    const Color(0xff8c4c32).toARGB32(): 'assets/images/brown.png',
  };
  return map[hex] ?? 'assets/images/red.png';
}

class _KakigoriCompleteOverlay extends StatefulWidget {
  const _KakigoriCompleteOverlay({super.key, required this.color, required this.onClose});
  final Color color;
  final VoidCallback onClose;

  @override
  State<_KakigoriCompleteOverlay> createState() => _KakigoriCompleteOverlayState();
}

class _KakigoriCompleteOverlayState extends State<_KakigoriCompleteOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final iceSway = math.sin(t * math.pi * 2) * 0.12;
        final sparkleOffsets = [
          const Offset(0.18, 0.18),
          const Offset(0.82, 0.2),
          const Offset(0.28, 0.38),
          const Offset(0.7, 0.36),
          const Offset(0.15, 0.7),
          const Offset(0.85, 0.72),
          const Offset(0.5, 0.12),
          const Offset(0.5, 0.82),
        ];

        return Center(
          child: Container(
            width: 320,
            height: 420,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: const Color(0xfff9d9c3), width: 3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xffef7d68).withOpacity(0.28),
                  blurRadius: 24,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                ...sparkleOffsets.asMap().entries.map((entry) {
                  final index = entry.key;
                  final offset = entry.value;
                  final angle = t * math.pi * 2 + index;
                  final size = 14 + (math.sin(angle * 2.5) + 1) * 10;
                  final opacity = 0.3 + (math.sin(angle * 3.2) + 1) * 0.35;
                  return Positioned(
                    left: 18 + (320 - 36) * offset.dx,
                    top: 18 + (420 - 36) * offset.dy,
                    child: Transform.rotate(
                      angle: angle,
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        size: size,
                        color: const Color(0xffffe39a).withOpacity(opacity),
                      ),
                    ),
                  );
                }),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.rotate(
                      angle: iceSway,
                      child: Transform.scale(
                        scale: 0.92 + math.sin(t * math.pi * 2) * 0.08,
                        child: Container(
                          width: 190,
                          height: 190,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.9),
                                blurRadius: 18,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              _kakigoriAssetForColor(widget.color),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'かき氷完成！',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                        color: const Color(0xff6a4338),
                        shadows: [
                          Shadow(color: Colors.white.withOpacity(0.8), blurRadius: 12),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'おめでとう！',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: 180,
                      child: FilledButton.icon(
                        onPressed: widget.onClose,
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('閉じる'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xffef7d68),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

enum _TimerPagePhase {
  idle,
  running,
  waitingForShake,
  shaking,
  completing,
  finished,
}

class TimerPage extends StatefulWidget {
  const TimerPage({
    super.key,
    required this.task,
    required this.onFinished,
    this.categoryColors = const {},
    this.onStarted,
    this.skipShake = false,
    this.compact = false,
    this.showTaskDetails = true,
    this.largeTimer = false,
  });
  final Task task;
  final VoidCallback onFinished;
  final Map<String, Color> categoryColors;
  final ValueChanged<DateTime>? onStarted;
  final bool skipShake;
  final bool compact;
  final bool showTaskDetails;
  final bool largeTimer;
  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> with WidgetsBindingObserver {
  static const double _shakeThreshold = 12.0;
  static const double _restingAcceleration = 9.81;
  static const Duration _shakeCompletionDuration = Duration(seconds: 3);
  static const Duration _shakeCooldownDuration = Duration(milliseconds: 300);
  static const int _consecutiveShakeRequirement = 2;

  late int _seconds;
  Timer? _timer;
  Timer? _shakeProgressTimer;
  Timer? _shakeHintTimer;
  late final Ticker _ticker = Ticker((_) => _onTick());
  StreamSubscription<UserAccelerometerEvent>? _accelerometerSubscription;
  DateTime? _endsAt; DateTime? _lastShakeAt; double? _lastAcceleration;
  DateTime? _shakeCooldownUntil;
  int _consecutiveShakeDetections = 0;
  bool _running = false;
  bool _waitingForShake = false;
  bool _isCompleted = false;
  bool _isShaking = false;
  bool _isShakeLocked = false;
  bool _showShakeHint = false;
  double _shakeProgress = 0.0;
  _TimerPagePhase _phase = _TimerPagePhase.idle;
  final AudioPlayer _chimePlayer = AudioPlayer();

  void _stopAllTimerWork() {
    _timer?.cancel();
    _timer = null;
    _shakeProgressTimer?.cancel();
    _shakeProgressTimer = null;
    _shakeHintTimer?.cancel();
    _shakeHintTimer = null;
    _ticker.stop();
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    _lastAcceleration = null;
    _lastShakeAt = null;
    _shakeCooldownUntil = null;
    _consecutiveShakeDetections = 0;
    _endsAt = null;
    _running = false;
    _waitingForShake = false;
    _isShaking = false;
    _isShakeLocked = true;
    _showShakeHint = false;
    _phase = _TimerPagePhase.finished;
  }

  void _startShakeProgress() {
    if (_isCompleted || _isShakeLocked || !_waitingForShake) return;
    _isShaking = true;
    _phase = _TimerPagePhase.shaking;
    _shakeProgressTimer?.cancel();
    _shakeProgressTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted || _isCompleted || _isShakeLocked || !_isShaking) return;
      final step = 50 / _shakeCompletionDuration.inMilliseconds;
      final nextProgress = (_shakeProgress + step).clamp(0.0, 1.0);
      if (nextProgress <= _shakeProgress) return;
      if (mounted) {
        setState(() => _shakeProgress = nextProgress);
      }
      if (nextProgress >= 1.0) {
        _isShakeLocked = true;
        _isShaking = false;
        _shakeProgressTimer?.cancel();
        _shakeProgressTimer = null;
        _phase = _TimerPagePhase.completing;
        if (mounted) {
          _completeTaskWithAnimation();
        }
      }
    });
  }

  void _pauseShakeProgress() {
    if (!_isShaking) return;
    _isShaking = false;
    _shakeProgressTimer?.cancel();
    _shakeProgressTimer = null;
    _consecutiveShakeDetections = 0;
    if (_phase == _TimerPagePhase.shaking) {
      _phase = _TimerPagePhase.waitingForShake;
    }
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final startedAt = widget.task.startedAt;
    if (startedAt != null) {
      _endsAt = startedAt.add(Duration(seconds: widget.task.seconds));
      final remaining = _endsAt!.difference(DateTime.now()).inSeconds;
      _seconds = remaining > 0 ? remaining : 0;
      if (_seconds > 0) {
        _running = true;
        _phase = _TimerPagePhase.running;
        _ticker.start();
        _timer = Timer.periodic(const Duration(seconds: 1), (_) => _refreshRemaining());
      } else {
        _phase = _TimerPagePhase.finished;
      }
    } else {
      _seconds = widget.task.seconds;
      _phase = _TimerPagePhase.idle;
    }
  }

  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); _timer?.cancel(); _ticker.dispose(); _accelerometerSubscription?.cancel(); _chimePlayer.dispose(); super.dispose(); }

  void _playChime() {
    _chimePlayer.play(AssetSource('sounds/chime.mp3'));
  }

  void _startShakeDetection() {
    if (_isCompleted || _isShakeLocked || _phase == _TimerPagePhase.completing) return;
    _consecutiveShakeDetections = 0;
    _shakeCooldownUntil = null;
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = userAccelerometerEventStream().listen((event) {
      if (_isCompleted || _isShakeLocked || _phase == _TimerPagePhase.completing) {
        _accelerometerSubscription?.cancel();
        _accelerometerSubscription = null;
        return;
      }

      if (!_waitingForShake) return;

      final magnitude = math.sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      final deviationFromRest = (magnitude - _restingAcceleration).abs();
      final now = DateTime.now();

      // クールダウン中は検出をスキップ
      if (_shakeCooldownUntil != null && now.isBefore(_shakeCooldownUntil!)) {
        if (_isShaking && _lastShakeAt != null && now.difference(_lastShakeAt!) > const Duration(milliseconds: 180)) {
          _pauseShakeProgress();
        }
        return;
      }

      // 振動なし
      if (deviationFromRest < _shakeThreshold) {
        _consecutiveShakeDetections = 0;
        if (_isShaking && _lastShakeAt != null && now.difference(_lastShakeAt!) > const Duration(milliseconds: 180)) {
          _pauseShakeProgress();
        }
        return;
      }

      // 振動あり：連続検出をカウント
      _consecutiveShakeDetections++;
      _lastShakeAt = now;

      // 2回連続検出でシェイク開始
      if (_consecutiveShakeDetections >= _consecutiveShakeRequirement && !_isShaking) {
        _consecutiveShakeDetections = 0;
        _shakeCooldownUntil = now.add(_shakeCooldownDuration);
        _startShakeProgress();
      }
    }, onError: (_) {}, cancelOnError: false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_phase == _TimerPagePhase.completing || _phase == _TimerPagePhase.finished) return;
    if (state == AppLifecycleState.resumed) {
      if (_running) { _refreshRemaining(); if (!_ticker.isActive) _ticker.start(); }
      if (_waitingForShake) _startShakeDetection();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _ticker.stop(); _accelerometerSubscription?.cancel(); _accelerometerSubscription = null; _lastAcceleration = null;
    }
  }

  void _refreshRemaining() {
    if (!mounted || _endsAt == null || _isCompleted || _phase == _TimerPagePhase.completing) return;
    final remaining = _endsAt!.difference(DateTime.now()).inSeconds;
    if (remaining <= 0) {
      // Time running out only stops the countdown — finishing the task
      // still requires the shake (or the skip-shake button), same as
      // before the timer expires. Auto-completing here would mark the
      // task done without the user ever confirming it.
      _timer?.cancel();
      _ticker.stop();
      _playChime();
      setState(() { _seconds = 0; _running = false; });
      return;
    }
    setState(() => _seconds = remaining);
  }

  void _onTick() {
    if (!mounted || !_running || _endsAt == null || _isCompleted || _phase == _TimerPagePhase.completing) return;
    final remaining = _endsAt!.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      _timer?.cancel();
      _ticker.stop();
      _playChime();
      setState(() { _seconds = 0; _running = false; });
      return;
    }
    final seconds = remaining.inSeconds;
    if (seconds != _seconds) {
      setState(() => _seconds = seconds);
    } else {
      setState(() {});
    }
  }

  Future<void> _toggle() async {
    if (_isCompleted || _phase == _TimerPagePhase.completing || _running || _seconds <= 0) return;
    final startedAt = DateTime.now();
    await Supabase.instance.client.from('ice_tasks').update({'started_at': startedAt.toUtc().toIso8601String()}).eq('id', widget.task.id as String);
    widget.onStarted?.call(startedAt);
    _endsAt = startedAt.add(Duration(seconds: _seconds));
    _phase = _TimerPagePhase.running;
    setState(() => _running = true);
    if (!_ticker.isActive) _ticker.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _refreshRemaining());
  }

  Future<void> _showCompletionOverlay() async {
    final overlayFuture = showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.18),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          child: ScaleTransition(
            scale: CurvedAnimation(parent: animation, curve: Curves.elasticOut, reverseCurve: Curves.easeOutCubic),
            child: child,
          ),
        );
      },
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final selectedColor = widget.task.category.startsWith('color_')
            ? Color(int.tryParse(RegExp(r'^color_([0-9a-fA-F]+)$').firstMatch(widget.task.category)?.group(1) ?? '', radix: 16) ?? 0xFFF25050)
            : (widget.categoryColors[widget.task.category] ?? const Color(0xfff25050));
        return _KakigoriCompleteOverlay(
          color: selectedColor,
          onClose: () {
            if (Navigator.of(dialogContext).canPop()) {
              Navigator.of(dialogContext).pop();
            }
          },
        );
      },
    );

    await overlayFuture;
  }

  Future<void> _completeTaskWithAnimation() async {
    if (_isCompleted || !mounted) return;

    _isCompleted = true;
    _phase = _TimerPagePhase.completing;
    _stopAllTimerWork();

    await _showCompletionOverlay();
    if (mounted) widget.onFinished();
  }

  Future<void> _prepareToShake() async {
    if (_isCompleted || _isShakeLocked || _phase == _TimerPagePhase.completing) return;
    if (widget.skipShake) {
      _phase = _TimerPagePhase.completing;
      await _completeTaskWithAnimation();
      return;
    }

    _shakeHintTimer?.cancel();
    _showShakeHint = true;
    _isShaking = false;
    _isShakeLocked = false;
    _shakeProgress = 0.0;
    _phase = _TimerPagePhase.waitingForShake;
    _waitingForShake = true;
    _lastAcceleration = null;
    _lastShakeAt = null;
    _shakeCooldownUntil = null;
    _consecutiveShakeDetections = 0;
    _startShakeDetection();

    if (!mounted) return;
    setState(() {});
    _shakeHintTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      setState(() => _showShakeHint = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_running && _endsAt != null ? _endsAt!.difference(DateTime.now()).inMilliseconds / (widget.task.seconds * 1000) : _seconds / widget.task.seconds).clamp(0.0, 1.0);
    final isShakeAnimationVisible = _isShaking && !_isCompleted && !_isShakeLocked;
    final content = Card(
      elevation: 0, color: const Color(0xfffff0e8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        if (isShakeAnimationVisible || _showShakeHint) ...[
          AnimatedOpacity(
            opacity: (isShakeAnimationVisible || _showShakeHint) ? 1 : 0,
            duration: const Duration(milliseconds: 250),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.65),
                borderRadius: BorderRadius.circular(18),
              ),
              child: isShakeAnimationVisible
                  ? Column(
                      children: [
                        SizedBox(
                          height: 150,
                          child: Image.asset(
                            'assets/animations/ice_animation.gif',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(_shakeProgress * 100).round()}%',
                          style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xff89534a)),
                        ),
                      ],
                    )
                  : Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          '振ってみよう！',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xff89534a),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (widget.largeTimer) const Spacer(),
        if (widget.largeTimer) Expanded(child: Center(child: MeltingIceTimer(progress: progress, label: formatClock(_seconds))))
        else Row(children: [Expanded(child: widget.showTaskDetails ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.compact ? 'いま取り組む習慣' : 'とりかかる', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xff89534a))), const SizedBox(height: 4),
          Text(widget.task.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), const SizedBox(height: 4),
          Text('${widget.task.category} ・ ${formatDuration(widget.task.seconds)}', style: const TextStyle(fontSize: 12, color: Color(0xff89534a), fontWeight: FontWeight.w600)),
          if (widget.task.detail.isNotEmpty) ...[const SizedBox(height: 4), Text(widget.task.detail, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))],
        ]) : const SizedBox.shrink()), Text('${_seconds ~/ 60}:${(_seconds % 60).toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: 1))]),
        if (widget.largeTimer) const Spacer(), const SizedBox(height: 12),
        if (!widget.largeTimer) LinearProgressIndicator(value: progress, minHeight: 8, borderRadius: BorderRadius.circular(8), color: const Color(0xffef7d68), backgroundColor: Colors.white),
        if (widget.compact) const Spacer(), const SizedBox(height: 12),
        Row(children: [Expanded(child: OutlinedButton.icon(onPressed: _toggle, icon: Icon(_running ? Icons.timelapse : Icons.play_arrow), label: Text(_running ? '稼働中' : 'タイマー開始'))), const SizedBox(width: 10), Expanded(child: FilledButton.icon(onPressed: _prepareToShake, icon: const Icon(Icons.check), label: const Text('完成')))]),
      ])),
    );
    if (widget.compact) return content;
    return Scaffold(appBar: AppBar(title: const Text('とりかかる', style: TextStyle(fontWeight: FontWeight.w800))), body: Padding(padding: const EdgeInsets.all(24), child: content));
  }
}