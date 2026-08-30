import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';
import '../utils/time_format.dart';
import '../widgets/timer_page.dart';
import 'task_detail_page.dart';

class TaskTimerPage extends StatefulWidget {
  const TaskTimerPage({
    super.key,
    required this.task,
    required this.categories,
    required this.categoryColors,
    required this.onUpdated,
    required this.onFinished,
    required this.onDeleted,
  });
  final Task task;
  final List<String> categories;
  final Map<String, Color> categoryColors;
  final ValueChanged<Task> onUpdated;
  final VoidCallback onFinished;
  final VoidCallback onDeleted;

  @override
  State<TaskTimerPage> createState() => _TaskTimerPageState();
}

class _TaskTimerPageState extends State<TaskTimerPage> {
  static const _skipShakeKey = 'skip_shake_completion';
  bool _skipShake = false;

  @override
  void initState() {
    super.initState();
    _loadSkipShake();
  }

  Future<void> _loadSkipShake() async {
    final preferences = await SharedPreferences.getInstance();
    if (mounted) setState(() => _skipShake = preferences.getBool(_skipShakeKey) ?? false);
  }

  Future<void> _setSkipShake(bool value) async {
    setState(() => _skipShake = value);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_skipShakeKey, value);
  }

  void _openTaskSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskDetailPage(
          task: widget.task,
          categories: widget.categories,
          categoryColors: widget.categoryColors,
          onUpdated: widget.onUpdated,
          onFinished: widget.onFinished,
          onDeleted: widget.onDeleted,
        ),
      ),
    );
  }

  void _handleStarted(DateTime startedAt) {
    widget.onUpdated(Task(widget.task.title, widget.task.category, widget.task.seconds, id: widget.task.id, detail: widget.task.detail, ghost: widget.task.ghost, startedAt: startedAt));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const SizedBox.shrink(), actions: [IconButton(onPressed: () => _openTaskSettings(context), icon: const Icon(Icons.tune), tooltip: 'タスク詳細を変更')]),
        body: Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(24, 20, 24, 8), child: Column(children: [
            Text(widget.task.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: widget.categoryColors[widget.task.category] ?? Color(int.tryParse(RegExp(r'^color_([0-9a-fA-F]+)$').firstMatch(widget.task.category)?.group(1) ?? '', radix: 16) ?? 0xFFF25050), shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(formatDuration(widget.task.seconds), style: const TextStyle(color: Color(0xff89534a), fontWeight: FontWeight.w700)),
            ]),
            if (widget.task.detail.isNotEmpty) ...[const SizedBox(height: 8), Text(widget.task.detail, textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Colors.grey.shade700))],
          ])),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 20, bottom: 4),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => _setSkipShake(!_skipShake),
                  child: SizedBox(
                    height: 48,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('振る動作をスキップ', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        Switch.adaptive(value: _skipShake, onChanged: _setSkipShake),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(child: Align(alignment: Alignment.bottomCenter, child: TimerPage(
            task: widget.task,
            compact: true,
            showTaskDetails: false,
            largeTimer: true,
            categoryColors: widget.categoryColors,
            skipShake: _skipShake,
            onFinished: widget.onFinished,
            onStarted: _handleStarted,
          ))),
        ]),
      );
}
