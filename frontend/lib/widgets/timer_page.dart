import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/task.dart';
import '../utils/time_format.dart';
import 'ice_painters.dart';

class _KakigoriCompleteOverlay extends StatefulWidget {
  const _KakigoriCompleteOverlay({super.key, required this.onClose});
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
                          width: 170,
                          height: 170,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.white.withOpacity(0.95),
                                const Color(0xfff8d8a9).withOpacity(0.9),
                                const Color(0xfff39c9b).withOpacity(0.84),
                              ],
                              stops: const [0.0, 0.45, 1.0],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.9),
                                blurRadius: 18,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                          child: const Center(child: IceSundae(color: Color(0xfff8d59d))),
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

class TimerPage extends StatefulWidget {
  const TimerPage({super.key, required this.task, required this.onFinished, this.onStarted, this.skipShake = false, this.compact = false, this.showTaskDetails = true, this.largeTimer = false});
  final Task task; final VoidCallback onFinished;
  final ValueChanged<DateTime>? onStarted;
  final bool skipShake;
  final bool compact; final bool showTaskDetails; final bool largeTimer;
  @override State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> with WidgetsBindingObserver {
  late int _seconds;
  Timer? _timer;
  late final Ticker _ticker = Ticker((_) => _onTick());
  StreamSubscription<UserAccelerometerEvent>? _accelerometerSubscription;
  DateTime? _endsAt; DateTime? _lastShakeAt; double? _lastAcceleration;
  bool _running = false; bool _waitingForShake = false;

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
        _ticker.start();
        _timer = Timer.periodic(const Duration(seconds: 1), (_) => _refreshRemaining());
      }
    } else {
      _seconds = widget.task.seconds;
    }
  }

  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); _timer?.cancel(); _ticker.dispose(); _accelerometerSubscription?.cancel(); super.dispose(); }

  void _startShakeDetection() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = userAccelerometerEventStream().listen((event) {
      final acceleration = math.sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      final previousAcceleration = _lastAcceleration; _lastAcceleration = acceleration;
      if (previousAcceleration == null) return;
      final shakeStrength = (acceleration - previousAcceleration).abs(); final now = DateTime.now();
      if (!_waitingForShake || shakeStrength < 4 || _lastShakeAt != null && now.difference(_lastShakeAt!) < const Duration(milliseconds: 1200)) return;
      _lastShakeAt = now; _waitingForShake = false; _accelerometerSubscription?.cancel();
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (mounted) {
        Future.microtask(() async {
          await _completeTaskWithAnimation();
        });
      }
    }, onError: (_) {}, cancelOnError: false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_running) { _refreshRemaining(); if (!_ticker.isActive) _ticker.start(); }
      if (_waitingForShake) _startShakeDetection();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _ticker.stop(); _accelerometerSubscription?.cancel(); _accelerometerSubscription = null; _lastAcceleration = null;
    }
  }

  void _refreshRemaining() {
    if (!mounted || _endsAt == null) return;
    final remaining = _endsAt!.difference(DateTime.now()).inSeconds;
    if (remaining <= 0) { _timer?.cancel(); _ticker.stop(); setState(() { _seconds = 0; _running = false; }); }
    else setState(() => _seconds = remaining);
  }

  void _onTick() {
    if (!mounted || !_running || _endsAt == null) return;
    final remaining = _endsAt!.difference(DateTime.now());
    if (remaining <= Duration.zero) { _timer?.cancel(); _ticker.stop(); setState(() { _seconds = 0; _running = false; }); return; }
    final seconds = remaining.inSeconds;
    if (seconds != _seconds) setState(() => _seconds = seconds); else setState(() {});
  }

  Future<void> _toggle() async {
    if (_running || _seconds <= 0) return;
    final startedAt = DateTime.now();
    await Supabase.instance.client.from('ice_tasks').update({'started_at': startedAt.toUtc().toIso8601String()}).eq('id', widget.task.id as String);
    widget.onStarted?.call(startedAt);
    _endsAt = startedAt.add(Duration(seconds: _seconds)); setState(() => _running = true);
    if (!_ticker.isActive) _ticker.start(); _timer = Timer.periodic(const Duration(seconds: 1), (_) => _refreshRemaining());
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
      pageBuilder: (context, animation, secondaryAnimation) {
        return _KakigoriCompleteOverlay(
          onClose: () => Navigator.of(context, rootNavigator: true).pop(),
        );
      },
    );

    await overlayFuture;
  }

  Future<void> _completeTaskWithAnimation() async {
    if (!mounted) return;
    await _showCompletionOverlay();
    if (mounted) widget.onFinished();
  }

  Future<void> _prepareToShake() async {
    if (widget.skipShake) {
      await _completeTaskWithAnimation();
      return;
    }
    setState(() { _waitingForShake = true; _lastAcceleration = null; _lastShakeAt = null; });
    _startShakeDetection();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('かき氷を完成させよう'),
        content: const Text('端末をしっかり振ってください。\n振動を感知すると完成します。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
        ],
      ),
    );
    if (!mounted || !_waitingForShake) return;
    setState(() => _waitingForShake = false);
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    _lastAcceleration = null;
    if (mounted) Navigator.of(context, rootNavigator: true).pop();
    await _completeTaskWithAnimation();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_running && _endsAt != null ? _endsAt!.difference(DateTime.now()).inMilliseconds / (widget.task.seconds * 1000) : _seconds / widget.task.seconds).clamp(0.0, 1.0);
    final content = Card(
      elevation: 0, color: const Color(0xfffff0e8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
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