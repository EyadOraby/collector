import 'dart:convert';
import 'dart:ui';

import 'package:flutter/services.dart';

/// Country outlines from world-atlas 110m (Natural Earth, public domain),
/// already projected to a 1000-wide map.
class WorldMap {
  const WorldMap(this.width, this.height, this.countries);

  final double width;
  final double height;
  final Map<String, Path> countries;

  static Future<WorldMap>? _loading;

  static Future<WorldMap> load([AssetBundle? bundle]) => _loading ??=
      (bundle ?? rootBundle).loadString('assets/world.json').then(parse);

  static WorldMap parse(String text) {
    final json = jsonDecode(text) as Map<String, Object?>;
    final out = <String, Path>{};
    for (final c in json['countries']! as List) {
      final m = c as Map<String, Object?>;
      out[normalise(m['name']! as String)] = svgPath(m['d']! as String);
    }
    return WorldMap(
      (json['width']! as num).toDouble(),
      (json['height']! as num).toDouble(),
      out,
    );
  }

  /// Finds the outline for a country as typed on an entry, if the map has it.
  Path? lookup(String country) => countries[match(country)];
}

/// Parses the M/L/Z paths the map uses.
Path svgPath(String d) {
  final path = Path();
  final re = RegExp(r'([MLZ])([^MLZ]*)');
  for (final m in re.allMatches(d)) {
    final cmd = m.group(1)!;
    if (cmd == 'Z') {
      path.close();
      continue;
    }
    final xy = m.group(2)!.split(',');
    final x = double.parse(xy[0]);
    final y = double.parse(xy[1]);
    if (cmd == 'M') {
      path.moveTo(x, y);
    } else {
      path.lineTo(x, y);
    }
  }
  return path;
}

String normalise(String name) => name
    .toLowerCase()
    .replaceAll(RegExp(r'^the '), '')
    .replaceAll(RegExp(r'[^a-z0-9. ]'), '')
    .trim();

/// Common ways a country is written on an entry, mapped to the map's names.
const _aliases = {
  'usa': 'united states of america',
  'us': 'united states of america',
  'united states': 'united states of america',
  'america': 'united states of america',
  'uk': 'united kingdom',
  'england': 'united kingdom',
  'scotland': 'united kingdom',
  'wales': 'united kingdom',
  'great britain': 'united kingdom',
  'britain': 'united kingdom',
  'northern ireland': 'united kingdom',
  'uae': 'united arab emirates',
  'czech republic': 'czechia',
  'holland': 'netherlands',
  'the netherlands': 'netherlands',
  'ivory coast': 'cte divoire',
  'north macedonia': 'macedonia',
  'south sudan': 's. sudan',
  'democratic republic of the congo': 'dem. rep. congo',
  'dr congo': 'dem. rep. congo',
  'bosnia and herzegovina': 'bosnia and herz.',
  'bosnia': 'bosnia and herz.',
  'dominican republic': 'dominican rep.',
  'central african republic': 'central african rep.',
  'equatorial guinea': 'eq. guinea',
  'east timor': 'timorleste',
  'eswatini': 'eswatini',
  'swaziland': 'eswatini',
  'burma': 'myanmar',
  'korea': 'south korea',
  'republic of korea': 'south korea',
  'turkiye': 'turkey',
};

/// The map's key for a country name as typed, after aliases.
String match(String country) {
  final n = normalise(country);
  return _aliases[n] ?? n;
}
