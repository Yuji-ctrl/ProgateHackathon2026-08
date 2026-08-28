class Task {
  Task(this.title, this.category, this.seconds, {this.id, this.detail = '', this.ghost = false, this.startedAt});

  final String? id;
  final String title;
  final String category;
  final int seconds;
  final String detail;
  final bool ghost;
  final DateTime? startedAt;
}
