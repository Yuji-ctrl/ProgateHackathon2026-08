import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() => runApp(const MyApp());

String formatDuration(int seconds) {
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final remainingSeconds = seconds % 60;
  if (hours > 0) return '$hours時間 $minutes分 $remainingSeconds秒';
  if (minutes > 0) return '$minutes分 $remainingSeconds秒';
  return '$remainingSeconds秒';
}

String formatClock(int seconds) {
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final remainingSeconds = seconds % 60;
  if (hours > 0) return '$hours:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
}

class Task {
  Task(this.title, this.category, this.seconds, {this.detail = '', this.ghost = false});
  final String title;
  final String category;
  final int seconds;
  final String detail;
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
                    padding: const EdgeInsets.all(18),
                    alignment: Alignment.centerLeft,
                    side: const BorderSide(color: Color(0xffef7d68), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.timer_outlined, color: Color(0xffef7d68)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(task.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text('${task.category} ・ ${formatDuration(task.seconds)}', style: const TextStyle(color: Color(0xff89534a), fontSize: 12)),
                    ])),
                    const Icon(Icons.chevron_right, color: Color(0xffb5a8a2)),
                  ]),
                ),
              );

  void _openTimer(Task task) {
    setState(() => _selectedTask = task);
    Navigator.push(context, MaterialPageRoute(builder: (_) => TaskTimerPage(
      task: task,
      categories: _categories,
      onUpdated: (updated) => _updateTask(task, updated),
      onFinished: () {
        _finishTask(task);
        Navigator.pop(context);
      },
    )));
  }

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

  void _newTask() => Navigator.push(context, MaterialPageRoute(builder: (_) => TaskCreationPage(
      initialCategories: _categories,
      onCategoryAdded: (category) => setState(() => _categories.add(category)),
        onCreated: (task) => setState(() => _active.add(task)),
      )));

  Color _categoryColor(String category) => {'からだ': const Color(0xff5cb5a5), 'まなび': const Color(0xffe39a49), 'こころ': const Color(0xff9d7ac2)}[category] ?? const Color(0xffef7d68);
}

class TaskTimerPage extends StatelessWidget {
  const TaskTimerPage({super.key, required this.task, required this.categories, required this.onUpdated, required this.onFinished});
  final Task task;
  final List<String> categories;
  final ValueChanged<Task> onUpdated;
  final VoidCallback onFinished;

  void _openTaskSettings(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailPage(
      task: task,
      categories: categories,
      onUpdated: onUpdated,
      onFinished: onFinished,
    )));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const SizedBox.shrink(),
          actions: [IconButton(onPressed: () => _openTaskSettings(context), icon: const Icon(Icons.tune), tooltip: 'タスク詳細を変更')],
        ),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Column(children: [
              Text(task.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('${task.category} ・ ${formatDuration(task.seconds)}', style: const TextStyle(color: Color(0xff89534a), fontWeight: FontWeight.w700)),
              if (task.detail.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(task.detail, textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Colors.grey.shade700)),
              ],
            ]),
          ),
          Expanded(child: Align(alignment: Alignment.bottomCenter, child: TimerPage(task: task, compact: true, showTaskDetails: false, largeTimer: true, onFinished: onFinished))),
        ]),
      );
}

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
  void dispose() {
    _titleController.dispose();
    _detailController.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    super.dispose();
  }

  void _createTask() {
    final title = _titleController.text.trim();
    final hours = int.tryParse(_hoursController.text.trim()) ?? 0;
    final minutes = int.tryParse(_minutesController.text.trim()) ?? 0;
    final secondsPart = int.tryParse(_secondsController.text.trim()) ?? 0;
    if (title.isEmpty || hours < 0 || minutes < 0 || minutes > 59 || secondsPart < 0 || secondsPart > 59) return;
    final seconds = hours * 3600 + minutes * 60 + secondsPart;
    if (seconds <= 0) return;
    widget.onCreated(Task(title, _category, seconds, detail: _detailController.text.trim()));
    Navigator.pop(context);
  }

  Future<void> _addCategory() async {
    final controller = TextEditingController();
    final category = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ジャンルを追加'),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(labelText: 'ジャンル名', border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('追加')),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || category == null || category.isEmpty || _categories.contains(category)) return;
    setState(() {
      _categories.add(category);
      _category = category;
    });
    widget.onCategoryAdded(category);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('新しい習慣をつくる', style: TextStyle(fontWeight: FontWeight.w800))),
        body: ListView(padding: const EdgeInsets.all(24), children: [
          TextField(controller: _titleController, autofocus: true, decoration: const InputDecoration(labelText: 'タイトル', hintText: '例：朝の水分補給', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: _detailController, maxLines: 4, decoration: const InputDecoration(labelText: '詳細', hintText: 'やることや目標を入力', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(initialValue: _category, decoration: const InputDecoration(labelText: 'ジャンル', border: OutlineInputBorder()), items: [
            ..._categories.map((category) => DropdownMenuItem(value: category, child: Text(category))),
            const DropdownMenuItem(value: '__add_category__', child: Text('＋ ジャンルを追加')),
          ], onChanged: (value) {
            if (value == '__add_category__') {
              _addCategory();
            } else if (value != null) {
              setState(() => _category = value);
            }
          }),
          const SizedBox(height: 16),
          const Text('タイマー時間', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextField(controller: _hoursController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '時間', suffixText: '時間', border: OutlineInputBorder()))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: _minutesController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '分', suffixText: '分', border: OutlineInputBorder()))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: _secondsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '秒', suffixText: '秒', border: OutlineInputBorder()))),
          ]),
          const SizedBox(height: 24),
          FilledButton.icon(onPressed: _createTask, icon: const Icon(Icons.ac_unit), label: const Text('習慣を追加')),
        ]),
      );
}

class TaskDetailPage extends StatefulWidget {
  const TaskDetailPage({super.key, required this.task, required this.categories, required this.onUpdated, required this.onFinished});
  final Task task;
  final List<String> categories;
  final ValueChanged<Task> onUpdated;
  final VoidCallback onFinished;

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  late final TextEditingController _titleController = TextEditingController(text: widget.task.title);
  late final TextEditingController _detailController = TextEditingController(text: widget.task.detail);
  late final TextEditingController _hoursController = TextEditingController(text: '${widget.task.seconds ~/ 3600}');
  late final TextEditingController _minutesController = TextEditingController(text: '${(widget.task.seconds % 3600) ~/ 60}');
  late final TextEditingController _secondsController = TextEditingController(text: '${widget.task.seconds % 60}');
  late String _category = widget.task.category;

  @override
  void dispose() {
    _titleController.dispose();
    _detailController.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    super.dispose();
  }

  void _save() {
    final hours = int.tryParse(_hoursController.text.trim()) ?? 0;
    final minutes = int.tryParse(_minutesController.text.trim()) ?? 0;
    final secondsPart = int.tryParse(_secondsController.text.trim()) ?? 0;
    final seconds = hours * 3600 + minutes * 60 + secondsPart;
    if (_titleController.text.trim().isEmpty || hours < 0 || minutes < 0 || minutes > 59 || secondsPart < 0 || secondsPart > 59 || seconds <= 0) return;
    widget.onUpdated(Task(_titleController.text.trim(), _category, seconds, detail: _detailController.text.trim(), ghost: widget.task.ghost));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('習慣の詳細', style: TextStyle(fontWeight: FontWeight.w800))),
        body: ListView(padding: const EdgeInsets.all(24), children: [
          TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'タイトル', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: _detailController, maxLines: 4, decoration: const InputDecoration(labelText: '詳細', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(initialValue: _category, decoration: const InputDecoration(labelText: 'ジャンル', border: OutlineInputBorder()), items: widget.categories.map((category) => DropdownMenuItem(value: category, child: Text(category))).toList(), onChanged: (value) => setState(() => _category = value ?? _category)),
          const SizedBox(height: 16),
          const Text('タイマー時間', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextField(controller: _hoursController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '時間', suffixText: '時間', border: OutlineInputBorder()))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: _minutesController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '分', suffixText: '分', border: OutlineInputBorder()))),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: _secondsController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '秒', suffixText: '秒', border: OutlineInputBorder()))),
          ]),
          const SizedBox(height: 24),
          FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('変更を保存')),
          const SizedBox(height: 28),
          TimerPage(task: widget.task, onFinished: () { widget.onFinished(); Navigator.pop(context); }),
        ]),
      );
}

class TimerPage extends StatefulWidget {
  const TimerPage({super.key, required this.task, required this.onFinished, this.compact = false, this.showTaskDetails = true, this.largeTimer = false});
  final Task task; final VoidCallback onFinished;
  final bool compact;
  final bool showTaskDetails;
  final bool largeTimer;
  @override State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> with WidgetsBindingObserver {
  late int _seconds = widget.task.seconds;
  Timer? _timer;
  late final Ticker _ticker = Ticker((_) => _onTick());
  StreamSubscription<UserAccelerometerEvent>? _accelerometerSubscription;
  DateTime? _endsAt;
  DateTime? _lastShakeAt;
  double? _lastAcceleration;
  bool _running = false;
  bool _waitingForShake = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _ticker.dispose();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  void _startShakeDetection() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = userAccelerometerEventStream().listen(
      (event) {
        final acceleration = math.sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
        final previousAcceleration = _lastAcceleration;
        _lastAcceleration = acceleration;
        if (previousAcceleration == null) return;
        final shakeStrength = (acceleration - previousAcceleration).abs();
        final now = DateTime.now();
        if (!_waitingForShake || shakeStrength < 4 || _lastShakeAt != null && now.difference(_lastShakeAt!) < const Duration(milliseconds: 1200)) return;
        _lastShakeAt = now;
        _waitingForShake = false;
        _accelerometerSubscription?.cancel();
        if (mounted) Navigator.of(context, rootNavigator: true).pop();
        widget.onFinished();
      },
      onError: (_) {},
      cancelOnError: false,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_running) {
        _refreshRemaining();
        if (!_ticker.isActive) _ticker.start();
      }
      if (_waitingForShake) _startShakeDetection();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _ticker.stop();
      _accelerometerSubscription?.cancel();
      _accelerometerSubscription = null;
      _lastAcceleration = null;
    }
  }

  void _refreshRemaining() {
    if (!mounted || _endsAt == null) return;
    final remaining = _endsAt!.difference(DateTime.now()).inSeconds;
    if (remaining <= 0) {
      _timer?.cancel();
      _ticker.stop();
      setState(() { _seconds = 0; _running = false; });
    } else {
      setState(() => _seconds = remaining);
    }
  }

  void _onTick() {
    if (!mounted || !_running || _endsAt == null) return;
    final remaining = _endsAt!.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      _timer?.cancel();
      _ticker.stop();
      setState(() { _seconds = 0; _running = false; });
      return;
    }
    final seconds = remaining.inSeconds;
    if (seconds != _seconds) {
      setState(() => _seconds = seconds);
    } else {
      setState(() {});
    }
  }

  void _toggle() {
    if (_running) return;
    if (_seconds <= 0) return;
    _endsAt = DateTime.now().add(Duration(seconds: _seconds));
    setState(() => _running = true);
    if (!_ticker.isActive) _ticker.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _refreshRemaining());
  }

  Future<void> _prepareToShake() async {
    setState(() {
      _waitingForShake = true;
      _lastAcceleration = null;
      _lastShakeAt = null;
    });
    _startShakeDetection();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('かき氷を完成させよう'),
        content: const Text('端末を振ってください。\n振ると完成画面が表示されます。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
        ],
      ),
    );
    if (!mounted || !_waitingForShake) return;
    setState(() => _waitingForShake = false);
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    _lastAcceleration = null;
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_running && _endsAt != null
      ? _endsAt!.difference(DateTime.now()).inMilliseconds / (widget.task.seconds * 1000)
      : _seconds / widget.task.seconds).clamp(0.0, 1.0);
    final content = Card(
      elevation: 0, color: const Color(0xfffff0e8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        if (widget.largeTimer) const Spacer(),
        if (widget.largeTimer)
          Expanded(child: Center(child: _MeltingIceTimer(progress: progress, label: formatClock(_seconds))))
        else Row(children: [
          Expanded(child: widget.showTaskDetails ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.compact ? 'いま取り組む習慣' : 'とりかかる', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xff89534a))),
            const SizedBox(height: 4), Text(widget.task.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('${widget.task.category} ・ ${formatDuration(widget.task.seconds)}', style: const TextStyle(fontSize: 12, color: Color(0xff89534a), fontWeight: FontWeight.w600)),
            if (widget.task.detail.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(widget.task.detail, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ]) : const SizedBox.shrink()),
          Text('${_seconds ~/ 60}:${(_seconds % 60).toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: 1)),
        ]),
        if (widget.largeTimer) const Spacer(),
        const SizedBox(height: 12),
        if (!widget.largeTimer) LinearProgressIndicator(value: progress, minHeight: 8, borderRadius: BorderRadius.circular(8), color: const Color(0xffef7d68), backgroundColor: Colors.white),
        if (widget.compact) const Spacer(),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: _toggle, icon: Icon(_running ? Icons.timelapse : Icons.play_arrow), label: Text(_running ? '稼働中' : 'タイマー開始'))),
          const SizedBox(width: 10), Expanded(child: FilledButton.icon(onPressed: _prepareToShake, icon: const Icon(Icons.vibration), label: Text(_waitingForShake ? '振ってください' : '振って完成'))),
        ]),
      ])),
    );
    if (widget.compact) return content;
    return Scaffold(appBar: AppBar(title: const Text('とりかかる', style: TextStyle(fontWeight: FontWeight.w800))), body: Padding(padding: const EdgeInsets.all(24), child: content));
  }
}

class _MeltingIceTimer extends StatefulWidget {
  const _MeltingIceTimer({required this.progress, required this.label});
  final double progress;
  final String label;

  @override State<_MeltingIceTimer> createState() => _MeltingIceTimerState();
}

class _MeltingIceTimerState extends State<_MeltingIceTimer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  late double _fromProgress;

  @override
  void initState() {
    super.initState();
    _fromProgress = widget.progress;
  }

  @override
  void didUpdateWidget(covariant _MeltingIceTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress == widget.progress) return;
    _fromProgress = _currentProgress;
    _controller
      ..reset()
      ..forward();
  }

  double get _currentProgress => Tween<double>(begin: _fromProgress, end: widget.progress).transform(_controller.value);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (_, child) {
          final progress = _currentProgress;
          return SizedBox.expand(
            child: CustomPaint(
              painter: _MeltingIcePainter(progress),
              child: Center(child: Text(widget.label, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: Color(0xff263238), letterSpacing: 1))),
            ),
          );
        },
      );
}

class _MeltingIcePainter extends CustomPainter {
  _MeltingIcePainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final iceHeight = size.height * (.25 + progress * .75);
    final bottom = size.height * .82;
    final top = bottom - iceHeight;
    final center = size.width / 2;
    final iceWidth = size.width * .62;
    final left = center - iceWidth / 2;
    final right = center + iceWidth / 2;
    final corner = size.width * .035;
    final meltWave = size.height * (.008 + (1 - progress) * .018);
    final ice = Path()
      ..moveTo(left + corner, bottom)
      ..lineTo(left, bottom - corner)
      ..lineTo(left, top + corner)
      ..quadraticBezierTo(left, top, left + corner, top)
      ..cubicTo(left + iceWidth * .18, top + meltWave, left + iceWidth * .3, top - meltWave, left + iceWidth * .45, top + meltWave * .4)
      ..cubicTo(left + iceWidth * .6, top + meltWave * 1.2, left + iceWidth * .76, top - meltWave * .5, right - corner, top)
      ..quadraticBezierTo(right, top, right, top + corner)
      ..lineTo(right, bottom - corner)
      ..quadraticBezierTo(right, bottom, right - corner, bottom)
      ..close();

    final icePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withAlpha(215),
          const Color(0xffb6edf2).withAlpha(205),
          const Color(0xff59bdcf).withAlpha(175),
        ],
      ).createShader(Rect.fromLTWH(0, top, size.width, iceHeight));
    canvas.drawShadow(ice, const Color(0xff398c99), 12, true);
    canvas.drawPath(ice, icePaint);
    canvas.drawPath(ice, Paint()..style = PaintingStyle.stroke..strokeWidth = 2.5..color = const Color(0xff55b9c7).withAlpha(190));

    final meltLine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withAlpha(70);
    final waterline = Path()
      ..moveTo(left + iceWidth * .06, top + meltWave * .5)
      ..cubicTo(left + iceWidth * .2, top - meltWave, left + iceWidth * .35, top + meltWave, left + iceWidth * .5, top)
      ..cubicTo(left + iceWidth * .65, top - meltWave, left + iceWidth * .8, top + meltWave, right - iceWidth * .06, top + meltWave * .3);
    canvas.drawPath(waterline, meltLine);

    final facet = Path()
      ..moveTo(center - iceWidth * .42, top + iceHeight * .06)
      ..lineTo(center - iceWidth * .12, top + iceHeight * .42)
      ..lineTo(center - iceWidth * .08, bottom - 3)
      ..lineTo(center + iceWidth * .18, top + iceHeight * .5)
      ..close();
    canvas.drawPath(facet, Paint()..color = Colors.white.withAlpha(48));

    final crackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xff3f9eae).withAlpha((110 * progress).round());
    final crack = Path()
      ..moveTo(center - iceWidth * .28, top + iceHeight * .24)
      ..lineTo(center - iceWidth * .12, top + iceHeight * .36)
      ..lineTo(center - iceWidth * .2, top + iceHeight * .48)
      ..moveTo(center + iceWidth * .28, top + iceHeight * .2)
      ..lineTo(center + iceWidth * .14, top + iceHeight * .34)
      ..lineTo(center + iceWidth * .24, top + iceHeight * .45);
    canvas.drawPath(crack, crackPaint);

    final highlightPaint = Paint()..color = Colors.white.withAlpha((190 * progress).round());
    canvas.drawOval(Rect.fromCenter(center: Offset(center - iceWidth * .25, top + iceHeight * .28), width: size.width * .08, height: iceHeight * .17), highlightPaint);
    canvas.drawCircle(Offset(center + iceWidth * .25, top + iceHeight * .36), size.width * .025, highlightPaint);

    final puddleWidth = size.width * (.25 + (1 - progress) * .35);
    canvas.drawOval(Rect.fromCenter(center: Offset(center, bottom + 12), width: puddleWidth, height: 18), Paint()..color = const Color(0xff62c7d5).withAlpha(145));
    if (progress < .7) {
      canvas.drawCircle(Offset(size.width * .75, bottom - 18), 5, Paint()..color = const Color(0xff62c7d5).withAlpha(175));
      canvas.drawCircle(Offset(size.width * .27, bottom + 5), 3, Paint()..color = const Color(0xff62c7d5).withAlpha(155));
    }
  }

  @override bool shouldRepaint(covariant _MeltingIcePainter old) => old.progress != progress;
}

class _IceSundae extends StatelessWidget { const _IceSundae({required this.color, this.small = false}); final Color color; final bool small; @override Widget build(BuildContext context) { final size = small ? 78.0 : 190.0; return SizedBox(width: size, height: size * .95, child: CustomPaint(painter: _IcePainter(color))); } }
class _IcePainter extends CustomPainter { _IcePainter(this.color); final Color color; @override void paint(Canvas canvas, Size size) { final cx = size.width / 2; final top = size.height * .12; final path = Path()..moveTo(cx, top)..cubicTo(size.width * .12, top + size.height * .12, size.width * .12, size.height * .5, size.width * .25, size.height * .7)..lineTo(size.width * .75, size.height * .7)..cubicTo(size.width * .88, size.height * .5, size.width * .88, top + size.height * .12, cx, top)..close(); canvas.drawPath(path, Paint()..color = color.withAlpha(210)); canvas.drawOval(Rect.fromLTWH(size.width * .18, size.height * .65, size.width * .64, size.height * .18), Paint()..color = const Color(0xffb96a50)); canvas.drawCircle(Offset(size.width * .33, size.height * .35), size.width * .06, Paint()..color = Colors.white.withAlpha(110)); } @override bool shouldRepaint(covariant _IcePainter old) => old.color != color; }
