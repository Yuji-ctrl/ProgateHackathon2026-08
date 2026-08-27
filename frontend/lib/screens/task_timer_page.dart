import 'package:flutter/material.dart';

import '../models/task.dart';
import '../utils/time_format.dart';
import '../widgets/timer_page.dart';
import 'task_detail_page.dart';

class TaskTimerPage extends StatelessWidget {
  const TaskTimerPage({super.key, required this.task, required this.categories, required this.onUpdated, required this.onFinished});
  final Task task;
  final List<String> categories;
  final ValueChanged<Task> onUpdated;
  final VoidCallback onFinished;

  void _openTaskSettings(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailPage(task: task, categories: categories, onUpdated: onUpdated, onFinished: onFinished)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const SizedBox.shrink(), actions: [IconButton(onPressed: () => _openTaskSettings(context), icon: const Icon(Icons.tune), tooltip: 'タスク詳細を変更')]),
        body: Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(24, 20, 24, 8), child: Column(children: [
            Text(task.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8), Text('${task.category} ・ ${formatDuration(task.seconds)}', style: const TextStyle(color: Color(0xff89534a), fontWeight: FontWeight.w700)),
            if (task.detail.isNotEmpty) ...[const SizedBox(height: 8), Text(task.detail, textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Colors.grey.shade700))],
          ])),
          Expanded(child: Align(alignment: Alignment.bottomCenter, child: TimerPage(task: task, compact: true, showTaskDetails: false, largeTimer: true, onFinished: onFinished))),
        ]),
      );
}