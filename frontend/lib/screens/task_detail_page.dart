import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/task.dart';
import 'task_timer_page.dart';

class TaskDetailPage extends StatefulWidget {
  const TaskDetailPage({super.key, required this.task, required this.categories, required this.onUpdated, required this.onFinished, required this.onDeleted, this.forced = false});
  final Task task;
  final List<String> categories;
  final ValueChanged<Task> onUpdated;
  final VoidCallback onFinished;
  final VoidCallback onDeleted;
  final bool forced;
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

  Future<void> _save() async {
    final hours = int.tryParse(_hoursController.text.trim()) ?? 0; final minutes = int.tryParse(_minutesController.text.trim()) ?? 0; final secondsPart = int.tryParse(_secondsController.text.trim()) ?? 0; final seconds = hours * 3600 + minutes * 60 + secondsPart;
    if (_titleController.text.trim().isEmpty || hours < 0 || minutes < 0 || minutes > 59 || secondsPart < 0 || secondsPart > 59 || seconds <= 0) return;
    final title = _titleController.text.trim();
    final detail = _detailController.text.trim();

    await Supabase.instance.client.from('ice_tasks').update({
      'task_name': title,
      'category': _category,
      'melt_minutes': seconds,
      'detail': detail,
      'started_at': null,
    }).eq('id', widget.task.id as String);

    if (!mounted) return;
    final updated = Task(title, _category, seconds, id: widget.task.id, detail: detail, ghost: widget.task.ghost);
    widget.onUpdated(updated);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => TaskTimerPage(task: updated, categories: widget.categories, onUpdated: widget.onUpdated, onFinished: widget.onFinished, onDeleted: widget.onDeleted)),
      (route) => route.isFirst,
    );
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('このタスクを削除しますか？'),
      content: const Text('削除すると元に戻せません。'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('削除')),
      ],
    ));
    if (confirmed != true) return;
    await Supabase.instance.client.from('ice_tasks').delete().eq('id', widget.task.id as String);
    if (!mounted) return;
    widget.onDeleted();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !widget.forced,
    child: Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.forced,
        title: const Text('習慣の詳細', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        if (widget.forced)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xffffe1d4), borderRadius: BorderRadius.circular(12)),
              child: const Text('氷が溶けきりました。時間を再設定するか、削除してください。', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xff89534a))),
            ),
          ),
        TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'タイトル', border: OutlineInputBorder())), const SizedBox(height: 16),
        TextField(controller: _detailController, maxLines: 4, decoration: const InputDecoration(labelText: '詳細', border: OutlineInputBorder())), const SizedBox(height: 16),
        DropdownButtonFormField<String>(initialValue: _category, decoration: const InputDecoration(labelText: 'ジャンル', border: OutlineInputBorder()), items: widget.categories.map((category) => DropdownMenuItem(value: category, child: Text(category))).toList(), onChanged: (value) => setState(() => _category = value ?? _category)),
        const SizedBox(height: 16), const Text('タイマー時間', style: TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 8),
        Row(children: [Expanded(child: TextField(controller: _hoursController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '時間', suffixText: '時間', border: OutlineInputBorder()))), const SizedBox(width: 8), Expanded(child: TextField(controller: _minutesController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '分', suffixText: '分', border: OutlineInputBorder()))), const SizedBox(width: 8), Expanded(child: TextField(controller: _secondsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '秒', suffixText: '秒', border: OutlineInputBorder())))]),
        const SizedBox(height: 24),
        FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('変更を保存')),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: _delete, icon: const Icon(Icons.delete_outline), label: const Text('タスクを削除'), style: OutlinedButton.styleFrom(foregroundColor: Colors.red)),
      ]),
    ),
  );
}
