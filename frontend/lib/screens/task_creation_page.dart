import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/task.dart';

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

class TaskCreationPage extends StatefulWidget {
  const TaskCreationPage({
    super.key,
    required this.initialCategories,
    required this.initialCategoryColors,
    required this.onCategoryAdded,
    required this.onCategoryColorsChanged,
    required this.onCreated,
  });

  final List<String> initialCategories;
  final Map<String, Color> initialCategoryColors;
  final ValueChanged<String> onCategoryAdded;
  final ValueChanged<Map<String, Color>> onCategoryColorsChanged;
  final ValueChanged<Task> onCreated;

  @override
  State<TaskCreationPage> createState() => _TaskCreationPageState();
}

class _TaskCreationPageState extends State<TaskCreationPage> {
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

  final _titleController = TextEditingController();
  final _detailController = TextEditingController();
  final _hoursController = TextEditingController();
  final _minutesController = TextEditingController();
  final _secondsController = TextEditingController();
  late final Map<String, Color> _categoryColors = Map<String, Color>.from(widget.initialCategoryColors);
  late Color _selectedColor = widget.initialCategoryColors.values.isNotEmpty ? widget.initialCategoryColors.values.first : _palette.first;

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

  Future<void> _createTask() async {
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

    final supabase = Supabase.instance.client;
    final startedAt = DateTime.now();
    final iceTask = await supabase.from('ice_tasks').insert({
      'task_name': form.title,
      'melt_minutes': form.seconds,
      'category': form.categoryKey,
      'detail': form.detail,
      'started_at': startedAt.toUtc().toIso8601String(),
    }).select().single();

    if (!mounted) return;
    final task = Task(form.title, form.categoryKey, form.seconds, id: iceTask['id'] as String, detail: form.detail, startedAt: startedAt);
    _categoryColors[form.categoryKey] = _selectedColor;
    widget.onCategoryColorsChanged(_categoryColors);
    widget.onCreated(task);
    Navigator.pop(context, task);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('新しい習慣をつくる', style: TextStyle(fontWeight: FontWeight.w800))),
    body: ListView(padding: const EdgeInsets.all(24), children: [
      TextField(controller: _titleController, autofocus: true, decoration: const InputDecoration(labelText: 'タイトル', hintText: '例：朝の水分補給', border: OutlineInputBorder())), const SizedBox(height: 16),
      TextField(controller: _detailController, maxLines: 4, decoration: const InputDecoration(labelText: '詳細', hintText: 'やることや目標を入力', border: OutlineInputBorder())), const SizedBox(height: 16),
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
      const SizedBox(height: 24), FilledButton.icon(onPressed: _createTask, icon: const Icon(Icons.ac_unit), label: const Text('習慣を追加')),
    ]),
  );
}