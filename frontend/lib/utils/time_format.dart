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
