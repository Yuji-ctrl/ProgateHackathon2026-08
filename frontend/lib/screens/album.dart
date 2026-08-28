import 'package:flutter/material.dart';

import '../models/task.dart';
import '../widgets/ice_painters.dart';

class Album extends StatefulWidget {
  const Album({super.key, required this.tasks, required this.categoryColor});

  final List<Task> tasks;
  final Color Function(String category) categoryColor;

  @override
  State<Album> createState() => _AlbumState();
}

class _AlbumState extends State<Album> {
  static const _pageSize = 4;
  late final PageController _pageController;
  int _page = 0;

  int get _pageCount => (widget.tasks.length / _pageSize).ceil();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _movePage(int page) {
    if (page < 0 || page >= _pageCount) return;
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pageCount;
    if (_page >= pages && pages > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _page = pages - 1);
      });
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xffffddbd), Color(0xffefbd9c)],
        ),
      ),
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            automaticallyImplyLeading: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            title: Row(
              children: [
                Container(
                  width: 38,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xfffff5dc),
                    border: Border.all(
                      color: const Color(0xffc46f83),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33c46f83),
                        offset: Offset(0, 2),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.home_rounded,
                    size: 21,
                    color: Color(0xff5796a0),
                  ),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(child: _AlbumIntro(count: widget.tasks.length)),
          if (widget.tasks.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyAlbum(),
            )
          else
            SliverToBoxAdapter(
              child: _AlbumBook(
                controller: _pageController,
                page: _page,
                pageCount: pages,
                tasks: widget.tasks,
                categoryColor: widget.categoryColor,
                onPageChanged: (page) => setState(() => _page = page),
                onPrevious: () => _movePage(_page - 1),
                onNext: () => _movePage(_page + 1),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 44)),
        ],
      ),
    );
  }
}

class _AlbumIntro extends StatelessWidget {
  const _AlbumIntro({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(22, 10, 22, 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'アルバム',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 3),
              Text(
                '溶けきる前に、確かな思い出へ',
                style: TextStyle(fontSize: 12, color: Color(0xff8b7770)),
              ),
            ],
          ),
        ),
        Text(
          '$count cup',
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xff9b7062),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _AlbumBook extends StatelessWidget {
  const _AlbumBook({
    required this.controller,
    required this.page,
    required this.pageCount,
    required this.tasks,
    required this.categoryColor,
    required this.onPageChanged,
    required this.onPrevious,
    required this.onNext,
  });
  final PageController controller;
  final int page;
  final int pageCount;
  final List<Task> tasks;
  final Color Function(String category) categoryColor;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final pages = [
      for (var start = 0; start < tasks.length; start += _AlbumState._pageSize)
        tasks.sublist(
          start,
          (start + _AlbumState._pageSize).clamp(0, tasks.length),
        ),
    ];

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
          padding: const EdgeInsets.fromLTRB(30, 16, 10, 10),
          decoration: BoxDecoration(
            color: const Color(0xfff2c1ca),
            border: Border.all(color: const Color(0xffb95770), width: 2.5),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x3db95770),
                offset: Offset(0, 7),
                blurRadius: 0,
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  SizedBox(
                    height: 440,
                    child: PageView.builder(
                      controller: controller,
                      itemCount: pages.length,
                      onPageChanged: onPageChanged,
                      itemBuilder: (_, index) => AnimatedBuilder(
                        animation: controller,
                        child: _AlbumPage(
                          tasks: pages[index],
                          categoryColor: categoryColor,
                        ),
                        builder: (_, child) {
                          final position = controller.hasClients
                              ? (controller.page ?? page.toDouble()) - index
                              : page.toDouble() - index;
                          final turn = position.clamp(-1.0, 1.0).toDouble();
                          return Transform(
                            alignment: turn <= 0
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.0012)
                              ..rotateY(turn * 0.22),
                            child: child,
                          );
                        },
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: page == 0 ? null : onPrevious,
                        icon: const Icon(Icons.chevron_left),
                        color: const Color(0xffa84963),
                        tooltip: '前のページ',
                      ),
                      Text(
                        '${page + 1} / $pageCount',
                        style: const TextStyle(
                          color: Color(0xffa84963),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      IconButton(
                        onPressed: page == pageCount - 1 ? null : onNext,
                        icon: const Icon(Icons.chevron_right),
                        color: const Color(0xffa84963),
                        tooltip: '次のページ',
                      ),
                    ],
                  ),
                ],
              ),
              const Positioned(
                left: -45,
                top: 48,
                bottom: 47,
                child: _AlbumRings(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          '左右にスワイプしてページをめくる',
          style: TextStyle(fontSize: 11, color: Color(0xffa18a82)),
        ),
      ],
    );
  }
}

class _AlbumPage extends StatelessWidget {
  const _AlbumPage({required this.tasks, required this.categoryColor});
  final List<Task> tasks;
  final Color Function(String category) categoryColor;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 2),
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
    decoration: BoxDecoration(
      color: const Color(0xfffff5dc),
      borderRadius: BorderRadius.circular(5),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33b95770),
          offset: Offset(2, 2),
          blurRadius: 2,
        ),
      ],
    ),
    child: Stack(
      children: [
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(4, 30, 4, 8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: .78,
          ),
          itemCount: tasks.length,
          itemBuilder: (_, index) => _AlbumCard(
            task: tasks[index],
            color: categoryColor(tasks[index].category),
          ),
        ),
        const Positioned(
          top: 2,
          left: 0,
          right: 0,
          child: Text(
            'こおり日和  •  memories',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.2,
              color: Color(0xffb95770),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Positioned(left: 0, top: 0, bottom: 0, child: _PageEdge()),
      ],
    ),
  );
}

class _AlbumRings extends StatelessWidget {
  const _AlbumRings();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 70,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(
        6,
        (_) => SizedBox(
          width: 70,
          height: 31,
          child: Align(
            alignment: Alignment.center,
            child: Container(
              width: 70,
              height: 7,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xffa96719),
                    Color(0xffffd477),
                    Color(0xffb97820),
                  ],
                ),
                border: Border.all(color: const Color(0xff8b5918), width: 1),
                borderRadius: BorderRadius.circular(5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x668b5a1c),
                    offset: Offset(1, 2),
                    blurRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _PageEdge extends StatelessWidget {
  const _PageEdge();

  @override
  Widget build(BuildContext context) => Container(
    width: 3,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0x22b95770), Color(0x88b95770), Color(0x22b95770)],
      ),
    ),
  );
}

class _EmptyAlbum extends StatelessWidget {
  const _EmptyAlbum();
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.photo_album_outlined,
            size: 54,
            color: Color(0xffd69a86),
          ),
          const SizedBox(height: 12),
          const Text(
            'まだ展示されていません',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            '習慣を完成させると、ここに飾られます。',
            style: TextStyle(fontSize: 12, color: Color(0xff8b7770)),
          ),
        ],
      ),
    ),
  );
}

class _AlbumCard extends StatelessWidget {
  const _AlbumCard({required this.task, required this.color});

  final Task task;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: const BorderSide(color: Color(0xffe6b9a5)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  IceSundae(color: color, small: true),
                  if (task.ghost)
                    const Positioned(
                      right: 0,
                      top: 0,
                      child: Text('👻', style: TextStyle(fontSize: 25)),
                    ),
                ],
              ),
            ),
          ),
          Text(
            task.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            task.ghost ? '亡霊のかき氷' : '完成 ・ ${task.category}',
            style: TextStyle(
              fontSize: 11,
              color: task.ghost ? const Color(0xff8e6aae) : color,
            ),
          ),
        ],
      ),
    ),
  );
}
