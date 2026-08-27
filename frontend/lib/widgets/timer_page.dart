import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../models/task.dart';
import '../utils/time_format.dart';
import 'ice_painters.dart';

class TimerPage extends StatefulWidget {
  const TimerPage({super.key, required this.task, required this.onFinished, this.compact = false, this.showTaskDetails = true, this.largeTimer = false});
  final Task task; final VoidCallback onFinished;
  final bool compact; final bool showTaskDetails; final bool largeTimer;
  @override State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> with WidgetsBindingObserver {
  late int _seconds = widget.task.seconds;
  Timer? _timer;
  late final Ticker _ticker = Ticker((_) => _onTick());
  StreamSubscription<UserAccelerometerEvent>? _accelerometerSubscription;
  DateTime? _endsAt; DateTime? _lastShakeAt; double? _lastAcceleration;
  bool _running = false; bool _waitingForShake = false;

  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); }

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
      if (mounted) Navigator.of(context, rootNavigator: true).pop(); widget.onFinished();
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

  void _toggle() {
    if (_running || _seconds <= 0) return;
    _endsAt = DateTime.now().add(Duration(seconds: _seconds)); setState(() => _running = true);
    if (!_ticker.isActive) _ticker.start(); _timer = Timer.periodic(const Duration(seconds: 1), (_) => _refreshRemaining());
  }

  Future<void> _prepareToShake() async {
    setState(() { _waitingForShake = true; _lastAcceleration = null; _lastShakeAt = null; }); _startShakeDetection();
    await showDialog<void>(context: context, barrierDismissible: false, builder: (context) => AlertDialog(
      title: const Text('かき氷を完成させよう'), content: const Text('端末を振ってください。\n振ると完成画面が表示されます。'),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル'))],
    ));
    if (!mounted || !_waitingForShake) return;
    setState(() => _waitingForShake = false); _accelerometerSubscription?.cancel(); _accelerometerSubscription = null; _lastAcceleration = null;
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
        Row(children: [Expanded(child: OutlinedButton.icon(onPressed: _toggle, icon: Icon(_running ? Icons.timelapse : Icons.play_arrow), label: Text(_running ? '稼働中' : 'タイマー開始'))), const SizedBox(width: 10), Expanded(child: FilledButton.icon(onPressed: _prepareToShake, icon: const Icon(Icons.vibration), label: Text(_waitingForShake ? '振ってください' : '振って完成')))]),
      ])),
    );
    if (widget.compact) return content;
    return Scaffold(appBar: AppBar(title: const Text('とりかかる', style: TextStyle(fontWeight: FontWeight.w800))), body: Padding(padding: const EdgeInsets.all(24), child: content));
  }
}