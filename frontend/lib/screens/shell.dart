import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/task.dart';
import 'album.dart';
import 'task_creation_page.dart';
import 'task_detail_page.dart';
import 'task_timer_page.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;
  Task? _selectedTask;
  final List<String> _categories = ['からだ', 'まなび', 'こころ', 'その他'];
  final List<Task> _active = [];
  final List<Task> _album = [];
  bool _loading = true;
  Timer? _expiryTimer;
  String? _forcedTaskId;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _expiryTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _checkExpired(),
    );
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    super.dispose();
  }

  Task _taskFromRow(Map<String, dynamic> row) => Task(
    row['task_name'] as String,
    row['category'] as String? ?? 'その他',
    row['melt_minutes'] as int,
    id: row['id'] as String,
    detail: row['detail'] as String? ?? '',
    startedAt: row['started_at'] != null
        ? DateTime.parse(row['started_at'] as String)
        : null,
  );

  Future<void> _loadTasks() async {
    final rows = await Supabase.instance.client.from('ice_tasks').select();
    if (!mounted) return;
    setState(() {
      _active
        ..clear()
        ..addAll(
          rows.where((r) => r['is_completed'] != true).map(_taskFromRow),
        );
      _album
        ..clear()
        ..addAll(
          rows.where((r) => r['is_completed'] == true).map(_taskFromRow),
        );
      _loading = false;
    });
    _checkExpired();
  }

  Future<void> _finishTask(Task task) async {
    final supabase = Supabase.instance.client;
    final cup = await supabase
        .from('cups')
        .insert({'title': task.title, 'is_completed': true})
        .select()
        .single();
    await supabase
        .from('ice_tasks')
        .update({
          'cup_id': cup['id'],
          'is_completed': true,
          'completed_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', task.id as String);

    if (!mounted) return;
    setState(() {
      _active.remove(task);
      _album.insert(0, task);
      if (_selectedTask == task) _selectedTask = null;
    });
  }

  void _updateTask(Task original, Task updated) {
    final index = _active.indexOf(original);
    if (index == -1) return;
    setState(() => _active[index] = updated);
  }

  void _deleteTask(Task task) {
    setState(() {
      _active.remove(task);
      _album.remove(task);
      if (_selectedTask == task) _selectedTask = null;
    });
  }

  bool _isExpired(Task task) {
    final startedAt = task.startedAt;
    if (startedAt == null) return false;
    return DateTime.now().isAfter(
      startedAt.add(Duration(seconds: task.seconds)),
    );
  }

  void _checkExpired() {
    if (_forcedTaskId != null || !mounted) return;
    Task? expired;
    for (final task in _active) {
      if (_isExpired(task)) {
        expired = task;
        break;
      }
    }
    if (expired == null) return;
    final task = expired;
    _forcedTaskId = task.id;
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => TaskDetailPage(
              task: task,
              categories: _categories,
              onUpdated: (updated) => _updateTask(task, updated),
              onFinished: () => _finishTask(task),
              onDeleted: () => _deleteTask(task),
              forced: true,
            ),
          ),
        )
        .then((_) => _forcedTaskId = null);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_tab == 0
                ? _home()
                : Album(tasks: _album, categoryColor: _categoryColor)),
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _tab,
      onDestinationSelected: (index) => setState(() => _tab = index),
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xffffe1d4),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'ホーム',
        ),
        NavigationDestination(
          icon: Icon(Icons.photo_library_outlined),
          selectedIcon: Icon(Icons.photo_library),
          label: 'アルバム',
        ),
      ],
    ),
    floatingActionButton: _tab == 0
        ? FloatingActionButton.extended(
            onPressed: _newTask,
            backgroundColor: const Color(0xffef7d68),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('新しい習慣'),
          )
        : null,
  );

  Widget _home() => CustomScrollView(
    slivers: [
      SliverAppBar(
        automaticallyImplyLeading: false,
        pinned: true,
        backgroundColor: const Color(0xfffffaf4),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'こおり日和',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
            Text(
              '今日も、融ける前にひとつ。',
              style: TextStyle(fontSize: 12, color: Color(0xff8b7770)),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: null,
            icon: const Icon(Icons.tune),
            tooltip: '設定',
          ),
        ],
      ),
      if (_active.isEmpty)
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: Text('予定されている習慣はありません。')),
        )
      else
        SliverList.builder(
          itemCount: _active.length,
          itemBuilder: (_, index) => _timerButton(_active[index]),
        ),
      const SliverToBoxAdapter(child: SizedBox(height: 100)),
    ],
  );

  Widget _timerButton(Task task) {
    final color = _categoryColor(task.category);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: OutlinedButton(
        onPressed: () => _openTimer(task),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(18),
          alignment: Alignment.centerLeft,
          side: BorderSide(color: color, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.timer_outlined, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                task.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xffb5a8a2)),
          ],
        ),
      ),
    );
  }

  void _openTimer(Task task) {
    setState(() => _selectedTask = task);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskTimerPage(
          task: task,
          categories: _categories,
          onUpdated: (updated) => _updateTask(task, updated),
          onFinished: () {
            _finishTask(task);
            Navigator.pop(context);
          },
          onDeleted: () {
            _deleteTask(task);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Future<void> _newTask() async {
    final created = await Navigator.push<Task>(
      context,
      MaterialPageRoute(
        builder: (_) => TaskCreationPage(
          initialCategories: _categories,
          onCategoryAdded: (category) =>
              setState(() => _categories.add(category)),
          onCreated: (task) => setState(() => _active.add(task)),
        ),
      ),
    );
    if (created == null || !mounted) return;
    _openTimer(created);
  }

  Color _categoryColor(String category) =>
      {
        'からだ': const Color(0xff5cb5a5),
        'まなび': const Color(0xffe39a49),
        'こころ': const Color(0xff9d7ac2),
      }[category] ??
      const Color(0xffef7d68);
}
