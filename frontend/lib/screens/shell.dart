import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/task.dart';
import 'album.dart';
import 'home_screen.dart';
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
  final Map<String, Color> _categoryColors = {
    'からだ': const Color(0xff5cb5a5),
    'まなび': const Color(0xffe39a49),
    'こころ': const Color(0xff9d7ac2),
    'その他': const Color(0xffef7d68),
  };
  final List<Task> _active = [];
  final List<Task> _album = [];
  bool _loading = true;
  Timer? _expiryTimer;
  String? _forcedTaskId;

  @override
  void initState() {
    super.initState();
    _loadCategoryColors();
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

  static const String _categoryColorsKey = 'category_colors';

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

  Future<void> _loadCategoryColors() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_categoryColorsKey);
    if (!mounted || encoded == null || encoded.isEmpty) return;
    try {
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      final next = <String, Color>{};
      for (final entry in decoded.entries) {
        final value = int.tryParse(entry.value as String? ?? '', radix: 16);
        if (value == null) continue;
        next[entry.key] = Color(value | 0xFF000000);
      }
      if (!mounted) return;
      setState(() {
        _categoryColors
          ..clear()
          ..addAll(next);
        for (final category in _categories) {
          _categoryColors.putIfAbsent(category, () => _defaultCategoryColor(category));
        }
      });
    } catch (_) {
      // Ignore malformed saved colors and keep defaults.
    }
  }

  Future<void> _saveCategoryColors() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      _categoryColors.map((key, value) => MapEntry(key, value.value.toRadixString(16).padLeft(8, '0'))),
    );
    await prefs.setString(_categoryColorsKey, encoded);
  }

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
              categoryColors: _categoryColors,
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
                ? HomeScreen(
                    active: _active,
                    categoryColor: _categoryColor,
                    onOpenTask: _openTimer,
                    onNewTask: _newTask,
                    onOpenAlbum: () => setState(() => _tab = 1),
                  )
                : Album(
                    tasks: _album,
                    categoryColor: _categoryColor,
                    onBack: () => setState(() => _tab = 0),
                  )),
    ),
  );

  void _openTimer(Task task) {
    setState(() => _selectedTask = task);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskTimerPage(
          task: task,
          categories: _categories,
          categoryColors: _categoryColors,
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
          initialCategoryColors: _categoryColors,
          onCategoryAdded: (category) => setState(() => _categories.add(category)),
          onCategoryColorsChanged: (colors) {
            setState(() => _categoryColors
              ..clear()
              ..addAll(colors));
            _saveCategoryColors();
          },
          onCreated: (task) => setState(() => _active.add(task)),
        ),
      ),
    );
    if (created == null || !mounted) return;
    _openTimer(created);
  }

  Color _defaultCategoryColor(String category) =>
      {
        'からだ': const Color(0xff5cb5a5),
        'まなび': const Color(0xffe39a49),
        'こころ': const Color(0xff9d7ac2),
      }[category] ??
      const Color(0xffef7d68);

  // Task colors are stored as a "color_<hex>" category key, so the exact
  // color is always recoverable straight from that string — this is used as
  // a fallback for when _categoryColors (the SharedPreferences-backed
  // reverse-lookup cache) hasn't loaded yet, e.g. right after a fresh
  // install, so the corkboard/album don't briefly show the wrong color.
  Color? _colorFromCategoryKey(String category) {
    final match = RegExp(r'^color_([0-9a-fA-F]+)$').firstMatch(category);
    if (match == null) return null;
    final value = int.tryParse(match.group(1)!, radix: 16);
    return value == null ? null : Color(value);
  }

  Color _categoryColor(String category) =>
      _categoryColors[category] ?? _colorFromCategoryKey(category) ?? _defaultCategoryColor(category);
}
