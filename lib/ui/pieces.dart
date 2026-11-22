import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

import 'theme.dart';

/// A piece's photo: round for coins, a note-shaped rectangle for banknotes,
/// and a drawn coin when there is no photo yet.
class PiecePhoto extends StatelessWidget {
  const PiecePhoto({
    super.key,
    required this.kind,
    this.bytes,
    this.size = 120,
  });

  final String kind;
  final Uint8List? bytes;
  final double size;

  @override
  Widget build(BuildContext context) {
    final note = kind == 'banknote';
    final width = note ? size * 1.6 : size;
    final image = bytes == null
        ? CustomPaint(painter: _CoinPainter(note: note))
        : Image.memory(bytes!, fit: BoxFit.cover, gaplessPlayback: true);
    return SizedBox(
      width: width,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: note ? BoxShape.rectangle : BoxShape.circle,
          borderRadius: note ? BorderRadius.circular(8) : null,
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: note
            ? ClipRRect(borderRadius: BorderRadius.circular(8), child: image)
            : ClipOval(child: image),
      ),
    );
  }
}

class _CoinPainter extends CustomPainter {
  _CoinPainter({required this.note});
  final bool note;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final fill = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFE2BE6A), brass, Color(0xFF8F6A22)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.04
      ..color = const Color(0x66FFFFFF);
    if (note) {
      canvas.drawRect(rect, Paint()..color = const Color(0xFF6E8F6A));
      canvas.drawRect(rect.deflate(size.height * 0.1), edge);
      canvas.drawCircle(rect.center, size.height * 0.22, fill);
    } else {
      canvas.drawOval(rect, fill);
      canvas.drawOval(rect.deflate(size.shortestSide * 0.1), edge);
    }
  }

  @override
  bool shouldRepaint(_CoinPainter old) => old.note != note;
}
