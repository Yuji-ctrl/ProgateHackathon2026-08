import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/task.dart';
import 'task_timer_page.dart';

class _TaskFormValue {
  const _TaskFormValue({
    required this.title,
    required this.detail,
    required this.seconds,
    required this.categoryKey,
  });

  final String title;
  final String detail;
  final int seconds;
  final String categoryKey;
}

class _TaskFormController {
  const _TaskFormController();

  static String colorKey(Color color) => 'color_${color.toARGB32().toRadixString(16)}';

  static int parseSeconds({
    required String hours,
    required String minutes,
    required String seconds,
  }) {
    final hoursValue = int.tryParse(hours.trim()) ?? 0;
    final minutesValue = int.tryParse(minutes.trim()) ?? 0;
    final secondsValue = int.tryParse(seconds.trim()) ?? 0;
    return hoursValue * 3600 + minutesValue * 60 + secondsValue;
  }

  static bool isValidDuration({
    required String hours,
    required String minutes,
    required String seconds,
  }) {
    final hoursValue = int.tryParse(hours.trim()) ?? 0;
    final minutesValue = int.tryParse(minutes.trim()) ?? 0;
    final secondsValue = int.tryParse(seconds.trim()) ?? 0;
    if (hoursValue < 0 || minutesValue < 0 || secondsValue < 0) return false;
    if (minutesValue > 59 || secondsValue > 59) return false;
    return parseSeconds(hours: hours, minutes: minutes, seconds: seconds) > 0;
  }

  static _TaskFormValue buildValue({
    required String title,
    required String detail,
    required String hours,
    required String minutes,
    required String seconds,
    required Color selectedColor,
  }) {
    final validatedSeconds = parseSeconds(hours: hours, minutes: minutes, seconds: seconds);
    return _TaskFormValue(
      title: title.trim(),
      detail: detail.trim(),
      seconds: validatedSeconds,
      categoryKey: colorKey(selectedColor),
    );
  }
}

class TaskDetailPage extends StatefulWidget {
  const TaskDetailPage({
    super.key,
    required this.task,
    required this.categories,
    required this.categoryColors,
    required this.onUpdated,
    required this.onFinished,
    required this.onDeleted,
    this.forced = false,
  });

  final Task task;
  final List<String> categories;
  final Map<String, Color> categoryColors;
  final ValueChanged<Task> onUpdated;
  final VoidCallback onFinished;
  final VoidCallback onDeleted;
  final bool forced;

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  static const List<Color> _palette = [
    Color(0xfff25050),
    Color(0xfff2993d),
    Color(0xfff4df45),
    Color(0xff9bd75d),
    Color(0xff3fa9f5),
    Color(0xff9b5de5),
    Color(0xff2ec4b6),
    Color(0xff8c4c32),
  ];

  late final TextEditingController _titleController = TextEditingController(text: widget.task.title);
  late final TextEditingController _detailController = TextEditingController(text: widget.task.detail);
  late final TextEditingController _hoursController = TextEditingController(text: '${widget.task.seconds ~/ 3600}');
  late final TextEditingController _minutesController = TextEditingController(text: '${(widget.task.seconds % 3600) ~/ 60}');
  late final TextEditingController _secondsController = TextEditingController(text: '${widget.task.seconds % 60}');
  late Color _selectedColor = widget.categoryColors[widget.task.category] ?? _taskColorFromCategory(widget.task.category);

  static Color _taskColorFromCategory(String category) {
    final match = RegExp(r'^color_([0-9a-fA-F]+)$').firstMatch(category);
    if (match != null) {
      final value = int.tryParse(match.group(1)!, radix: 16);
      if (value != null) return Color(value);
    }
    return const Color(0xfff25050);
  }

  @override
  void dispose() { _titleController.dispose(); _detailController.dispose(); _hoursController.dispose(); _minutesController.dispose(); _secondsController.dispose(); super.dispose(); }

  Future<void> _pickCategoryColor() async {
    final picked = await showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('色を選ぶ'),
        content: SizedBox(
          width: 300,
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _palette.map((color) {
              final selected = color.toARGB32() == _selectedColor.toARGB32();
              return GestureDetector(
                onTap: () => Navigator.pop(context, color),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? const Color(0xff263238) : Colors.transparent,
                      width: selected ? 3 : 0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withAlpha(120),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedColor = picked;
    });
  }

  Future<void> _save() async {
    final form = _TaskFormController.buildValue(
      title: _titleController.text,
      detail: _detailController.text,
      hours: _hoursController.text,
      minutes: _minutesController.text,
      seconds: _secondsController.text,
      selectedColor: _selectedColor,
    );

    if (form.title.isEmpty || !_TaskFormController.isValidDuration(
      hours: _hoursController.text,
      minutes: _minutesController.text,
      seconds: _secondsController.text,
    )) {
      return;
    }

    await Supabase.instance.client.from('ice_tasks').update({
      'task_name': form.title,
      'category': form.categoryKey,
      'melt_minutes': form.seconds,
      'detail': form.detail,
      'started_at': null,
    }).eq('id', widget.task.id as String);

    if (!mounted) return;
    final updated = Task(form.title, form.categoryKey, form.seconds, id: widget.task.id, detail: form.detail, ghost: widget.task.ghost);
    widget.categoryColors[form.categoryKey] = _selectedColor;
    widget.onUpdated(updated);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => TaskTimerPage(
          task: updated,
          categories: widget.categories,
          categoryColors: widget.categoryColors,
          onUpdated: widget.onUpdated,
          onFinished: widget.onFinished,
          onDeleted: widget.onDeleted,
        ),
      ),
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
        const Text('色', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickCategoryColor,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _selectedColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('かき氷の色を選ぶ', style: TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                const Icon(Icons.palette_outlined, size: 18),
              ],
            ),
          ),
        ),
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
