import 'package:flutter/material.dart';

class MeltingIceTimer extends _MeltingIceTimer {
  const MeltingIceTimer({super.key, required super.progress, required super.label});
}

class IceSundae extends _IceSundae {
  const IceSundae({super.key, required super.color, super.small});
}

class _MeltingIceTimer extends StatefulWidget {
  const _MeltingIceTimer({super.key, required this.progress, required this.label});
  final double progress; final String label;
  @override State<_MeltingIceTimer> createState() => _MeltingIceTimerState();
}

class _MeltingIceTimerState extends State<_MeltingIceTimer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  late double _fromProgress;
  @override void initState() { super.initState(); _fromProgress = widget.progress; }
  @override void didUpdateWidget(covariant _MeltingIceTimer oldWidget) { super.didUpdateWidget(oldWidget); if (oldWidget.progress == widget.progress) return; _fromProgress = _currentProgress; _controller..reset()..forward(); }
  double get _currentProgress => Tween<double>(begin: _fromProgress, end: widget.progress).transform(_controller.value);
  @override void dispose() { _controller.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AnimatedBuilder(animation: _controller, builder: (_, child) => SizedBox.expand(child: CustomPaint(painter: _MeltingIcePainter(_currentProgress), child: Center(child: Text(widget.label, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: Color(0xff263238), letterSpacing: 1))))));
}

class _MeltingIcePainter extends CustomPainter {
  _MeltingIcePainter(this.progress); final double progress;
  @override void paint(Canvas canvas, Size size) {
    final iceHeight = size.height * (.25 + progress * .75); final bottom = size.height * .82; final top = bottom - iceHeight; final center = size.width / 2; final iceWidth = size.width * .62; final left = center - iceWidth / 2; final right = center + iceWidth / 2; final corner = size.width * .035; final meltWave = size.height * (.008 + (1 - progress) * .018);
    final ice = Path()..moveTo(left + corner, bottom)..lineTo(left, bottom - corner)..lineTo(left, top + corner)..quadraticBezierTo(left, top, left + corner, top)..cubicTo(left + iceWidth * .18, top + meltWave, left + iceWidth * .3, top - meltWave, left + iceWidth * .45, top + meltWave * .4)..cubicTo(left + iceWidth * .6, top + meltWave * 1.2, left + iceWidth * .76, top - meltWave * .5, right - corner, top)..quadraticBezierTo(right, top, right, top + corner)..lineTo(right, bottom - corner)..quadraticBezierTo(right, bottom, right - corner, bottom)..close();
    final icePaint = Paint()..shader = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white.withAlpha(215), const Color(0xffb6edf2).withAlpha(205), const Color(0xff59bdcf).withAlpha(175)]).createShader(Rect.fromLTWH(0, top, size.width, iceHeight));
    canvas.drawShadow(ice, const Color(0xff398c99), 12, true); canvas.drawPath(ice, icePaint); canvas.drawPath(ice, Paint()..style = PaintingStyle.stroke..strokeWidth = 2.5..color = const Color(0xff55b9c7).withAlpha(190));
    final meltLine = Paint()..style = PaintingStyle.stroke..strokeWidth = 2..strokeCap = StrokeCap.round..color = Colors.white.withAlpha(70); final waterline = Path()..moveTo(left + iceWidth * .06, top + meltWave * .5)..cubicTo(left + iceWidth * .2, top - meltWave, left + iceWidth * .35, top + meltWave, left + iceWidth * .5, top)..cubicTo(left + iceWidth * .65, top - meltWave, left + iceWidth * .8, top + meltWave, right - iceWidth * .06, top + meltWave * .3); canvas.drawPath(waterline, meltLine);
    final facet = Path()..moveTo(center - iceWidth * .42, top + iceHeight * .06)..lineTo(center - iceWidth * .12, top + iceHeight * .42)..lineTo(center - iceWidth * .08, bottom - 3)..lineTo(center + iceWidth * .18, top + iceHeight * .5)..close(); canvas.drawPath(facet, Paint()..color = Colors.white.withAlpha(48));
    final crackPaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.3..strokeCap = StrokeCap.round..color = const Color(0xff3f9eae).withAlpha((110 * progress).round()); final crack = Path()..moveTo(center - iceWidth * .28, top + iceHeight * .24)..lineTo(center - iceWidth * .12, top + iceHeight * .36)..lineTo(center - iceWidth * .2, top + iceHeight * .48)..moveTo(center + iceWidth * .28, top + iceHeight * .2)..lineTo(center + iceWidth * .14, top + iceHeight * .34)..lineTo(center + iceWidth * .24, top + iceHeight * .45); canvas.drawPath(crack, crackPaint);
    final highlightPaint = Paint()..color = Colors.white.withAlpha((190 * progress).round()); canvas.drawOval(Rect.fromCenter(center: Offset(center - iceWidth * .25, top + iceHeight * .28), width: size.width * .08, height: iceHeight * .17), highlightPaint); canvas.drawCircle(Offset(center + iceWidth * .25, top + iceHeight * .36), size.width * .025, highlightPaint);
    final puddleWidth = size.width * (.25 + (1 - progress) * .35); canvas.drawOval(Rect.fromCenter(center: Offset(center, bottom + 12), width: puddleWidth, height: 18), Paint()..color = const Color(0xff62c7d5).withAlpha(145)); if (progress < .7) { canvas.drawCircle(Offset(size.width * .75, bottom - 18), 5, Paint()..color = const Color(0xff62c7d5).withAlpha(175)); canvas.drawCircle(Offset(size.width * .27, bottom + 5), 3, Paint()..color = const Color(0xff62c7d5).withAlpha(155)); }
  }
  @override bool shouldRepaint(covariant _MeltingIcePainter old) => old.progress != progress;
}

class _IceSundae extends StatelessWidget { const _IceSundae({super.key, required this.color, this.small = false}); final Color color; final bool small; @override Widget build(BuildContext context) { final size = small ? 78.0 : 190.0; return SizedBox(width: size, height: size * .95, child: CustomPaint(painter: _IcePainter(color))); } }
class _IcePainter extends CustomPainter { _IcePainter(this.color); final Color color; @override void paint(Canvas canvas, Size size) { final cx = size.width / 2; final top = size.height * .12; final path = Path()..moveTo(cx, top)..cubicTo(size.width * .12, top + size.height * .12, size.width * .12, size.height * .5, size.width * .25, size.height * .7)..lineTo(size.width * .75, size.height * .7)..cubicTo(size.width * .88, size.height * .5, size.width * .88, top + size.height * .12, cx, top)..close(); canvas.drawPath(path, Paint()..color = color.withAlpha(210)); canvas.drawOval(Rect.fromLTWH(size.width * .18, size.height * .65, size.width * .64, size.height * .18), Paint()..color = const Color(0xffb96a50)); canvas.drawCircle(Offset(size.width * .33, size.height * .35), size.width * .06, Paint()..color = Colors.white.withAlpha(110)); } @override bool shouldRepaint(covariant _IcePainter old) => old.color != color; }