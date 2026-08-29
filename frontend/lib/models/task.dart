class Task {
  Task(this.title, this.category, this.seconds, {this.id, this.detail = '', this.ghost = false, this.startedAt});

  final String? id;
  final String title;
  final String category;
  final int seconds;
  final String detail;
  final bool ghost;
  final DateTime? startedAt;

  // Editing a task (e.g. starting the timer, saving changes) replaces it
  // with a new Task instance sharing the same id. Without this, list
  // lookups like _active.remove(task) fall back to reference equality and
  // silently fail to find the (now-replaced) instance, leaving finished
  // tasks stuck on the corkboard and re-triggering the expiry prompt.
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Task && id != null && other.id == id);

  @override
  int get hashCode => id?.hashCode ?? identityHashCode(this);
}
