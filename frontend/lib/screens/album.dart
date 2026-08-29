import 'package:flutter/material.dart';

import '../models/task.dart';
import '../widgets/ice_painters.dart';

class Album extends StatelessWidget {
  const Album({super.key, required this.tasks, required this.categoryColor, this.onBack});

  final List<Task> tasks;
  final Color Function(String category) categoryColor;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      SliverAppBar(
        automaticallyImplyLeading: false,
        pinned: true,
        leading: onBack == null
            ? null
            : IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)),
        title: const Text('アルバム', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      SliverPadding(
        padding: const EdgeInsets.all(20),
        sliver: SliverGrid.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: .82,
          ),
          itemCount: tasks.length,
          itemBuilder: (_, index) => _AlbumCard(
            task: tasks[index],
            color: categoryColor(tasks[index].category),
          ),
        ),
      ),
    ],
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
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
