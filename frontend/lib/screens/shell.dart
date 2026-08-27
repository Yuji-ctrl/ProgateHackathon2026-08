import 'package:flutter/material.dart';

import '../models/task.dart';
import '../utils/time_format.dart';
import '../widgets/ice_painters.dart';
import 'task_creation_page.dart';
import 'task_timer_page.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;
  Task? _selectedTask;
  final List<String> _categories = ['からだ', 'まなび', 'こころ', 'その他'];
  final List<Task> _active = [Task('朝のストレッチ', 'からだ', 15), Task('読書を20ページ', 'まなび', 30)];
  final List<Task> _album = [Task('水を8杯飲む', 'からだ', 10), Task('日記を書く', 'こころ', 15, ghost: true), Task('英単語を覚える', 'まなび', 25)];

  void _finishTask(Task task) {
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

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(child: _tab == 0 ? _home() : _albumPage()),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tab, onDestinationSelected: (index) => setState(() => _tab = index),
          backgroundColor: Colors.white, indicatorColor: const Color(0xffffe1d4),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'ホーム'),
            NavigationDestination(icon: Icon(Icons.photo_library_outlined), selectedIcon: Icon(Icons.photo_library), label: 'アルバム'),
          ],
        ),
        floatingActionButton: _tab == 0 ? FloatingActionButton.extended(
          onPressed: _newTask, backgroundColor: const Color(0xffef7d68), foregroundColor: Colors.white,
          icon: const Icon(Icons.add), label: const Text('新しい習慣'),
        ) : null,
      );

  Widget _home() => CustomScrollView(slivers: [
    SliverAppBar(
      automaticallyImplyLeading: false, pinned: true, backgroundColor: const Color(0xfffffaf4),
      title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('こおり日和', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        Text('今日も、融ける前にひとつ。', style: TextStyle(fontSize: 12, color: Color(0xff8b7770))),
      ]),
      actions: [IconButton(onPressed: null, icon: const Icon(Icons.tune), tooltip: '設定')],
    ),
    if (_active.isEmpty)
      const SliverFillRemaining(hasScrollBody: false, child: Center(child: Text('予定されている習慣はありません。')))
    else
      SliverList.builder(itemCount: _active.length, itemBuilder: (_, index) => _timerButton(_active[index])),
    const SliverToBoxAdapter(child: SizedBox(height: 100)),
  ]);

  Widget _timerButton(Task task) => Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: OutlinedButton(
                  onPressed: () => _openTimer(task),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(18), alignment: Alignment.centerLeft,
                    side: const BorderSide(color: Color(0xffef7d68), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.timer_outlined, color: Color(0xffef7d68)), const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(task.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)), const SizedBox(height: 4),
                      Text('${task.category} ・ ${formatDuration(task.seconds)}', style: const TextStyle(color: Color(0xff89534a), fontSize: 12)),
                    ])),
                    const Icon(Icons.chevron_right, color: Color(0xffb5a8a2)),
                  ]),
                ),
              );

  void _openTimer(Task task) {
    setState(() => _selectedTask = task);
    Navigator.push(context, MaterialPageRoute(builder: (_) => TaskTimerPage(
      task: task, categories: _categories,
      onUpdated: (updated) => _updateTask(task, updated),
      onFinished: () { _finishTask(task); Navigator.pop(context); },
    )));
  }

  Widget _albumPage() => CustomScrollView(slivers: [
    const SliverAppBar(automaticallyImplyLeading: false, pinned: true, title: Text('アルバム', style: TextStyle(fontWeight: FontWeight.w800))),
    SliverPadding(padding: const EdgeInsets.all(20), sliver: SliverGrid.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: .82),
      itemCount: _album.length, itemBuilder: (_, index) { final task = _album[index]; final color = _categoryColor(task.category); return Card(
        elevation: 0, color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Center(child: Stack(alignment: Alignment.center, children: [IceSundae(color: color, small: true), if (task.ghost) const Positioned(right: 0, top: 0, child: Text('👻', style: TextStyle(fontSize: 25)))]))),
          Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 4),
          Text(task.ghost ? '亡霊のかき氷' : '完成 ・ ${task.category}', style: TextStyle(fontSize: 11, color: task.ghost ? const Color(0xff8e6aae) : color)),
        ])),
      ); },
    )),
  ]);

  void _newTask() => Navigator.push(context, MaterialPageRoute(builder: (_) => TaskCreationPage(
      initialCategories: _categories,
      onCategoryAdded: (category) => setState(() => _categories.add(category)),
      onCreated: (task) => setState(() => _active.add(task)),
    )));

  Color _categoryColor(String category) => {'からだ': const Color(0xff5cb5a5), 'まなび': const Color(0xffe39a49), 'こころ': const Color(0xff9d7ac2)}[category] ?? const Color(0xffef7d68);
}