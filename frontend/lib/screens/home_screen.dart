import 'package:flutter/material.dart';

import '../models/task.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.active,
    required this.categoryColor,
    required this.onOpenTask,
    required this.onNewTask,
    required this.onOpenAlbum,
  });
  final List<Task> active;
  final Color Function(String category) categoryColor;
  final ValueChanged<Task> onOpenTask;
  final VoidCallback onNewTask;
  final VoidCallback onOpenAlbum;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // "Design canvas" size — matches the source art board. Change these two
  // numbers when swapping in new artwork with a different resolution.
  static const double _designWidth = 768;
  static const double _designHeight = 1375;

  // Tap region for the whole bookshelf (pen cup, plant, all the books) —
  // tapping anywhere here opens the album, even though only the red book
  // visibly reacts.
  static const double _shelfLeft = 0.735;
  static const double _shelfTop = 0.505;
  static const double _shelfW = 0.265;
  static const double _shelfH = 0.21;

  // The animated red "album" book sprite (book1.png / book2.png) — drawn
  // at its native crop size (scale 1.0 = no scaling), positioned right next
  // to the pink "album" book that's already painted into the shelf artwork
  // — same bottom edge (sitting on the same shelf), just to its left.
  static const double _bookScale = 1.0;
  static const double _bookW = _bookNativeW;
  static const double _bookH = _bookNativeH;
  static const double _pinkBookLeft = 0.742;
  static const double _pinkBookBottom = 0.711;
  static const double _bookOverlap = 0.02; // slight touch into the pink book
  static const double _bookLeft = _pinkBookLeft - _bookW + _bookOverlap;
  static const double _bookTop = _pinkBookBottom - _bookH;

  // book1.png / book2.png share the same 768x1375 canvas as the rest of the
  // artwork but draw the book at a slightly different native position/size
  // in each file — this is the book's own tight bounding box within that
  // canvas (about 12% x 17.5% of it), used to crop out just the book before
  // scaling it up to the slot above.
  static const double _bookNativeW = 0.120;
  static const double _bookNativeH = 0.175;
  static const Alignment _book1Align = Alignment(0.432, 0.530);
  static const Alignment _book2Align = Alignment(0.502, 0.590);

  bool _bookOpening = false;
  bool _paperPressed = false;

  Future<void> _handleBookTap() async {
    setState(() => _bookOpening = true);
    await Future.delayed(const Duration(milliseconds: 260));
    if (!mounted) return;
    widget.onOpenAlbum();
    setState(() => _bookOpening = false);
  }

  Future<void> _handlePaperTap() async {
    setState(() => _paperPressed = true);
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    widget.onNewTask();
    setState(() => _paperPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return SizedBox(
        width: constraints.maxWidth,
        height: constraints.maxHeight,
        // Scales the whole design canvas to exactly fill the available
        // space (cropping evenly if the aspect ratio doesn't match) —
        // no scrolling, works for any screen size.
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _designWidth,
            height: _designHeight,
            child: Stack(children: [
              Image.asset('assets/images/background.png', width: _designWidth, height: _designHeight, fit: BoxFit.fill),
              // The red "album" book: shows book2.png normally, and swaps to
              // book1.png while the shelf is being tapped, like a little
              // flip animation. The rest of the shelf (pen cup, plant, the
              // other books) is just static background art.
              Positioned(
                left: _designWidth * _bookLeft, top: _designHeight * _bookTop,
                width: _designWidth * _bookW, height: _designHeight * _bookH,
                child: IgnorePointer(
                  child: Transform.scale(
                    scale: _bookScale,
                    child: ClipRect(
                      child: Image(
                        image: AssetImage(_bookOpening ? 'assets/images/book1.png' : 'assets/images/book2.png'),
                        width: _designWidth * _bookNativeW,
                        height: _designHeight * _bookNativeH,
                        fit: BoxFit.none,
                        alignment: _bookOpening ? _book1Align : _book2Align,
                      ),
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                child: AnimatedScale(
                  scale: _paperPressed ? 1.12 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  // Scales around roughly where the paper sits in the artwork,
                  // so only the paper visibly grows (the rest of this layer is transparent).
                  alignment: const Alignment(0.234, 0.569),
                  child: Image.asset('assets/images/paper.png', width: _designWidth, height: _designHeight, fit: BoxFit.fill),
                ),
              ),
              Positioned(
                left: _designWidth * 0.13, top: _designHeight * 0.16,
                width: _designWidth * 0.75, height: _designHeight * 0.32,
                child: _taskBoard(),
              ),
              Positioned(
                left: _designWidth * _shelfLeft, top: _designHeight * _shelfTop,
                width: _designWidth * _shelfW, height: _designHeight * _shelfH,
                child: GestureDetector(onTap: _handleBookTap, behavior: HitTestBehavior.translucent),
              ),
              Positioned(
                left: _designWidth * 0.38, top: _designHeight * 0.71,
                width: _designWidth * 0.475, height: _designHeight * 0.145,
                child: GestureDetector(onTap: _handlePaperTap, behavior: HitTestBehavior.translucent),
              ),
            ]),
          ),
        ),
      );
    });
  }

  Widget _taskBoard() {
    if (widget.active.isEmpty) {
      return const Center(
        child: Text('予定されている習慣は\nありません。', textAlign: TextAlign.center, style: TextStyle(color: Color(0xff8b7770), fontWeight: FontWeight.w600)),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1,
      ),
      itemCount: widget.active.length,
      itemBuilder: (_, index) => _taskCard(widget.active[index]),
    );
  }

  Widget _taskCard(Task task) {
    final color = widget.categoryColor(task.category);
    return Material(
      color: Colors.white.withAlpha(240),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: BorderSide(color: color.withAlpha(140), width: 1.5)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () => widget.onOpenTask(task),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
          child: Stack(clipBehavior: Clip.none, children: [
            Positioned(top: -18, left: 0, right: 0, child: Icon(Icons.push_pin, color: color, size: 20)),
            Center(
              child: Text(
                task.title, textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xff4a3a34)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
