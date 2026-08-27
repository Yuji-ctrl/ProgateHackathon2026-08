import 'package:flutter/material.dart';

import '../models/task.dart';

class TaskCreationPage extends StatefulWidget {
  const TaskCreationPage({super.key, required this.initialCategories, required this.onCategoryAdded, required this.onCreated});
  final List<String> initialCategories;
  final ValueChanged<String> onCategoryAdded;
  final ValueChanged<Task> onCreated;
  @override State<TaskCreationPage> createState() => _TaskCreationPageState();
}

class _TaskCreationPageState extends State<TaskCreationPage> {
  final _titleController = TextEditingController();
  final _detailController = TextEditingController();
  final _hoursController = TextEditingController();
  final _minutesController = TextEditingController();
  final _secondsController = TextEditingController();
  late final List<String> _categories = [...widget.initialCategories];
  String _category = 'その他';

  @override
  void dispose() { _titleController.dispose(); _detailController.dispose(); _hoursController.dispose(); _minutesController.dispose(); _secondsController.dispose(); super.dispose(); }

  void _createTask() {
    final title = _titleController.text.trim();
    final hours = int.tryParse(_hoursController.text.trim()) ?? 0;
    final minutes = int.tryParse(_minutesController.text.trim()) ?? 0;
    final secondsPart = int.tryParse(_secondsController.text.trim()) ?? 0;
    if (title.isEmpty || hours < 0 || minutes < 0 || minutes > 59 || secondsPart < 0 || secondsPart > 59) return;
    final seconds = hours * 3600 + minutes * 60 + secondsPart;
    if (seconds <= 0) return;
    widget.onCreated(Task(title, _category, seconds, detail: _detailController.text.trim())); Navigator.pop(context);
  }

  Future<void> _addCategory() async {
    final controller = TextEditingController();
    final category = await showDialog<String>(context: context, builder: (context) => AlertDialog(
      title: const Text('ジャンルを追加'), content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: 'ジャンル名', border: OutlineInputBorder())),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')), FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('追加'))],
    ));
    controller.dispose();
    if (!mounted || category == null || category.isEmpty || _categories.contains(category)) return;
    setState(() { _categories.add(category); _category = category; }); widget.onCategoryAdded(category);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('新しい習慣をつくる', style: TextStyle(fontWeight: FontWeight.w800))),
    body: ListView(padding: const EdgeInsets.all(24), children: [
      TextField(controller: _titleController, autofocus: true, decoration: const InputDecoration(labelText: 'タイトル', hintText: '例：朝の水分補給', border: OutlineInputBorder())), const SizedBox(height: 16),
      TextField(controller: _detailController, maxLines: 4, decoration: const InputDecoration(labelText: '詳細', hintText: 'やることや目標を入力', border: OutlineInputBorder())), const SizedBox(height: 16),
      DropdownButtonFormField<String>(initialValue: _category, decoration: const InputDecoration(labelText: 'ジャンル', border: OutlineInputBorder()), items: [..._categories.map((category) => DropdownMenuItem(value: category, child: Text(category))), const DropdownMenuItem(value: '__add_category__', child: Text('＋ ジャンルを追加'))], onChanged: (value) { if (value == '__add_category__') { _addCategory(); } else if (value != null) setState(() => _category = value); }),
      const SizedBox(height: 16), const Text('タイマー時間', style: TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 8),
      Row(children: [Expanded(child: TextField(controller: _hoursController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '時間', suffixText: '時間', border: OutlineInputBorder()))), const SizedBox(width: 8), Expanded(child: TextField(controller: _minutesController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '分', suffixText: '分', border: OutlineInputBorder()))), const SizedBox(width: 8), Expanded(child: TextField(controller: _secondsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '秒', suffixText: '秒', border: OutlineInputBorder())))]),
      const SizedBox(height: 24), FilledButton.icon(onPressed: _createTask, icon: const Icon(Icons.ac_unit), label: const Text('習慣を追加')),
    ]),
  );
}