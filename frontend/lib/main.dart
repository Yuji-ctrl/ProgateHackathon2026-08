import 'dart:async';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class Task {
  Task(this.title, this.category, this.minutes, {this.ghost = false});
  final String title;
  final String category;
  final int minutes;
  final bool ghost;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'こおり日和',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xffef7d68)),
          scaffoldBackgroundColor: const Color(0xfffffaf4),
          appBarTheme: const AppBarTheme(backgroundColor: Color(0xfffffaf4), foregroundColor: Color(0xff263238)),
        ),
        home: const Shell(),
      );
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;
  final List<Task> _active = [Task('朝のストレッチ', 'からだ', 15), Task('読書を20ページ', 'まなび', 30)];
  final List<Task> _album = [Task('水を8杯飲む', 'からだ', 10), Task('日記を書く', 'こころ', 15, ghost: true), Task('英単語を覚える', 'まなび', 25)];

  void _openTimer(Task task) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TimerPage(task: task, onFinished: () {
        setState(() { _active.remove(task); _album.insert(0, task); });
      })));

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
          actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.tune), tooltip: '設定')],
        ),
        SliverToBoxAdapter(child: _progressHeader()),
        SliverPadding(padding: const EdgeInsets.fromLTRB(20, 22, 20, 100), sliver: SliverList.builder(
          itemCount: _active.length + 1,
          itemBuilder: (_, index) => index == 0 ? const Padding(
            padding: EdgeInsets.only(bottom: 12), child: Text('とりかかっている習慣', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          ) : _taskCard(_active[index - 1]),
        )),
      ]);

  Widget _progressHeader() => Container(
        margin: const EdgeInsets.fromLTRB(20, 18, 20, 0), padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: const Color(0xffffe4d8), borderRadius: BorderRadius.circular(24)),
        child: Row(children: [const Text('☀', style: TextStyle(fontSize: 36)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('今日の達成度', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xff89534a))), const SizedBox(height: 8),
          LinearProgressIndicator(value: .62, minHeight: 9, borderRadius: BorderRadius.circular(8), color: const Color(0xffef7d68), backgroundColor: Colors.white), const SizedBox(height: 7),
          const Text('2 / 3 個のかき氷を完成', style: TextStyle(fontSize: 12, color: Color(0xff89534a))),
        ]))]),
      );

  Widget _taskCard(Task task) { final color = _categoryColor(task.category); return Card(
    margin: const EdgeInsets.only(bottom: 12), elevation: 0, color: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: color.withAlpha(55))),
    child: InkWell(borderRadius: BorderRadius.circular(18), onTap: () => _openTimer(task), child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
      _MiniIce(color: color), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(task.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)), const SizedBox(height: 5),
        Text('${task.category}  ・  ${task.minutes}分', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ])), const Icon(Icons.chevron_right, color: Color(0xffb5a8a2)),
    ]))),
  ); }

  Widget _albumPage() => CustomScrollView(slivers: [
    const SliverAppBar(automaticallyImplyLeading: false, pinned: true, title: Text('アルバム', style: TextStyle(fontWeight: FontWeight.w800))),
    SliverPadding(padding: const EdgeInsets.all(20), sliver: SliverGrid.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: .82),
      itemCount: _album.length, itemBuilder: (_, index) { final task = _album[index]; final color = _categoryColor(task.category); return Card(
        elevation: 0, color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Center(child: Stack(alignment: Alignment.center, children: [_IceSundae(color: color, small: true), if (task.ghost) const Positioned(right: 0, top: 0, child: Text('👻', style: TextStyle(fontSize: 25)))]))),
          Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 4),
          Text(task.ghost ? '亡霊のかき氷' : '完成 ・ ${task.category}', style: TextStyle(fontSize: 11, color: task.ghost ? const Color(0xff8e6aae) : color)),
        ])),
      ); },
    )),
  ]);

  void _newTask() { final controller = TextEditingController(); showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => Padding(
    padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('新しい習慣をつくる', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), const SizedBox(height: 18),
      TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: '習慣の名前', hintText: '例：朝の水分補給', border: OutlineInputBorder())), const SizedBox(height: 16),
      SizedBox(width: double.infinity, child: FilledButton(onPressed: () { if (controller.text.trim().isNotEmpty) { setState(() => _active.add(Task(controller.text.trim(), 'その他', 15))); Navigator.pop(context); } }, child: const Text('冷凍庫に入れる'))),
    ]),
  )); }

  Color _categoryColor(String category) => {'からだ': const Color(0xff5cb5a5), 'まなび': const Color(0xffe39a49), 'こころ': const Color(0xff9d7ac2)}[category] ?? const Color(0xffef7d68);
}

class TimerPage extends StatefulWidget {
  const TimerPage({super.key, required this.task, required this.onFinished});
  final Task task; final VoidCallback onFinished;
  @override State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  late int _seconds = widget.task.minutes * 60; Timer? _timer; bool _running = false;
  @override void dispose() { _timer?.cancel(); super.dispose(); }
  void _toggle() { setState(() => _running = !_running); if (_running) { _timer = Timer.periodic(const Duration(seconds: 1), (_) { if (_seconds > 0) setState(() => _seconds--); }); } else { _timer?.cancel(); } }
  @override Widget build(BuildContext context) { final progress = _seconds / (widget.task.minutes * 60); return Scaffold(
    appBar: AppBar(title: const Text('とりかかる', style: TextStyle(fontWeight: FontWeight.w800))), body: Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Column(children: [
      const SizedBox(height: 12), Text(widget.task.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), Text('融け切るまでに完成させよう', style: TextStyle(color: Colors.grey.shade600)), const SizedBox(height: 22),
      Text('${_seconds ~/ 60}:${(_seconds % 60).toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w800, letterSpacing: 2)), const SizedBox(height: 8),
      LinearProgressIndicator(value: progress, minHeight: 8, borderRadius: BorderRadius.circular(8), color: const Color(0xffef7d68), backgroundColor: const Color(0xffffdfd2)),
      Expanded(child: Center(child: _IceSundae(color: const Color(0xffef7d68), melt: 1 - progress))), Text(_seconds == 0 ? '氷が融けてしまった…' : '集中できたら、かき氷機を回そう', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xff765f59))), const SizedBox(height: 16),
      Row(children: [Expanded(child: OutlinedButton.icon(onPressed: _toggle, icon: Icon(_running ? Icons.pause : Icons.play_arrow), label: Text(_running ? '一時停止' : 'タイマー開始'))), const SizedBox(width: 12), Expanded(child: FilledButton.icon(onPressed: () { widget.onFinished(); Navigator.pop(context); }, icon: const Icon(Icons.vibration), label: const Text('振って完成')))]), const SizedBox(height: 28),
    ])),
  ); }
}

class _MiniIce extends StatelessWidget { const _MiniIce({required this.color}); final Color color; @override Widget build(BuildContext context) => SizedBox(width: 48, height: 48, child: _IceSundae(color: color, small: true)); }
class _IceSundae extends StatelessWidget { const _IceSundae({required this.color, this.small = false, this.melt = 0}); final Color color; final bool small; final double melt; @override Widget build(BuildContext context) { final size = small ? 78.0 : 190.0 * (.68 + melt * .32); return SizedBox(width: size, height: size * .95, child: CustomPaint(painter: _IcePainter(color, melt))); } }
class _IcePainter extends CustomPainter { _IcePainter(this.color, this.melt); final Color color; final double melt; @override void paint(Canvas canvas, Size size) { final cx = size.width / 2; final top = size.height * (.12 + melt * .1); final path = Path()..moveTo(cx, top)..cubicTo(size.width * .12, top + size.height * .12, size.width * .12, size.height * .5, size.width * .25, size.height * .7)..lineTo(size.width * .75, size.height * .7)..cubicTo(size.width * .88, size.height * .5, size.width * .88, top + size.height * .12, cx, top)..close(); canvas.drawPath(path, Paint()..color = color.withAlpha(210)); canvas.drawOval(Rect.fromLTWH(size.width * .18, size.height * .65, size.width * .64, size.height * .18), Paint()..color = const Color(0xffb96a50)); canvas.drawCircle(Offset(size.width * .33, size.height * .35), size.width * .06, Paint()..color = Colors.white.withAlpha(110)); } @override bool shouldRepaint(covariant _IcePainter old) => old.melt != melt || old.color != color; }
