import 'package:flutter/material.dart';

import '../models/task.dart';
import '../widgets/timer_page.dart';

class TaskDetailPage extends StatefulWidget {
  const TaskDetailPage({super.key, required this.task, required this.categories, required this.onUpdated, required this.onFinished});
  final Task task; final List<String> categories; final ValueChanged<Task> onUpdated; final VoidCallback onFinished;
  @override State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  late final TextEditingController _titleController = TextEditingController(text: widget.task.title);
  late final TextEditingController _detailController = TextEditingController(text: widget.task.detail);
  late final TextEditingController _hoursController = TextEditingController(text: '${widget.task.seconds ~/ 3600}');
  late final TextEditingController _minutesController = TextEditingController(text: '${(widget.task.seconds % 3600) ~/ 60}');
  late final TextEditingController _secondsController = TextEditingController(text: '${widget.task.seconds % 60}');
  late String _category = widget.task.category;

  @override
  void dispose() { _titleController.dispose(); _detailController.dispose(); _hoursController.dispose(); _minutesController.dispose(); _secondsController.dispose(); super.dispose(); }

  void _save() {
    final hours = int.tryParse(_hoursController.text.trim()) ?? 0; final minutes = int.tryParse(_minutesController.text.trim()) ?? 0; final secondsPart = int.tryParse(_secondsController.text.trim()) ?? 0; final seconds = hours * 3600 + minutes * 60 + secondsPart;
    if (_titleController.text.trim().isEmpty || hours < 0 || minutes < 0 || minutes > 59 || secondsPart < 0 || secondsPart > 59 || seconds <= 0) return;
    widget.onUpdated(Task(_titleController.text.trim(), _category, seconds, detail: _detailController.text.trim(), ghost: widget.task.ghost)); Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('習慣の詳細', style: TextStyle(fontWeight: FontWeight.w800))),
    body: ListView(padding: const EdgeInsets.all(24), children: [
      TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'タイトル', border: OutlineInputBorder())), const SizedBox(height: 16),
      TextField(controller: _detailController, maxLines: 4, decoration: const InputDecoration(labelText: '詳細', border: OutlineInputBorder())), const SizedBox(height: 16),
      DropdownButtonFormField<String>(initialValue: _category, decoration: const InputDecoration(labelText: 'ジャンル', border: OutlineInputBorder()), items: widget.categories.map((category) => DropdownMenuItem(value: category, child: Text(category))).toList(), onChanged: (value) => setState(() => _category = value ?? _category)),
      const SizedBox(height: 16), const Text('タイマー時間', style: TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 8),
      Row(children: [Expanded(child: TextField(controller: _hoursController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '時間', suffixText: '時間', border: OutlineInputBorder()))), const SizedBox(width: 8), Expanded(child: TextField(controller: _minutesController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '分', suffixText: '分', border: OutlineInputBorder()))), const SizedBox(width: 8), Expanded(child: TextField(controller: _secondsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '秒', suffixText: '秒', border: OutlineInputBorder())))]),
      const SizedBox(height: 24), FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('変更を保存')), const SizedBox(height: 28),
      TimerPage(task: widget.task, onFinished: () { widget.onFinished(); Navigator.pop(context); }),
    ]),
  );
}