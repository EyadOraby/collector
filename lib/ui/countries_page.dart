import 'package:material_ui/material_ui.dart';

import '../data/world.dart';
import '../main.dart';
import 'theme.dart';

/// Where the pieces come from: a world map shaded by count, and the list.
/// Tapping a country returns it so the collection can be filtered.
class CountriesPage extends StatelessWidget {
  const CountriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context).store;
    final counts = store.countryCounts();
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Countries')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: felt,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: FutureBuilder<WorldMap>(
                    future: WorldMap.load(),
                    builder: (context, snap) => AspectRatio(
                      aspectRatio: 1000 / 435,
                      child: snap.hasData
                          ? CustomPaint(
                              painter: _MapPainter(snap.data!, counts),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                counts.isEmpty
                    ? 'Countries show up here once pieces have one.'
                    : '${counts.length} ${counts.length == 1 ? 'country' : 'countries'}',
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              for (final c in counts)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  title: Text(c.key),
                  trailing: Text(
                    '${c.value} ${c.value == 1 ? 'piece' : 'pieces'}',
                    style: text.bodyMedium?.copyWith(color: muted),
                  ),
                  onTap: () => Navigator.of(context).pop(c.key),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter(this.map, this.counts);

  final WorldMap map;
  final List<MapEntry<String, int>> counts;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / map.width;
    canvas.scale(scale);
    final land = Paint()..color = const Color(0x33FFFFFF);
    final edge = Paint()
      ..color = const Color(0x22000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6 / scale;
    for (final p in map.countries.values) {
      canvas.drawPath(p, land);
      canvas.drawPath(p, edge);
    }
    final most = counts.isEmpty ? 1 : counts.first.value;
    for (final c in counts) {
      final path = map.lookup(c.key);
      if (path == null) continue;
      final t = 0.45 + 0.55 * (c.value / most);
      canvas.drawPath(
        path,
        Paint()..color = Color.lerp(const Color(0xFF8F6A22), brass, t)!,
      );
    }
  }

  @override
  bool shouldRepaint(_MapPainter old) => old.counts != counts;
}
