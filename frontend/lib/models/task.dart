class Task {
  Task(this.title, this.category, this.seconds, {this.detail = '', this.ghost = false});

  final String title;
  final String category;
  final int seconds;
  final String detail;
  final bool ghost;
}
