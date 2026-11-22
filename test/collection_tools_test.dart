import 'dart:io';

import 'package:collector/data/store.dart';
import 'package:collector/data/world.dart';
import 'package:collector/main.dart';
import 'package:collector/models/entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';

Entry _entry(
  String id,
  String country, {
  String kind = 'coin',
  String notes = '',
  String year = '',
}) => Entry(
  id: id,
  kind: kind,
  country: country,
  denomination: '1 $id',
  year: year,
  notes: notes,
  addedAt: DateTime(2026, 11, 1).add(Duration(days: id.codeUnitAt(0))),
);

void main() {
  test('an export imports into another device, photos included', () async {
    final from = CollectionStore(MemoryStorage());
    await from.save(
      _entry('a', 'Egypt'),
      photo: img.encodeJpg(img.Image(width: 600, height: 600)),
    );
    await from.save(_entry('b', 'Spain', kind: 'banknote'));

    final to = CollectionStore(MemoryStorage());
    await to.save(_entry('a', 'Egypt'));
    final added = await to.importJson(from.exportJson());

    expect(added, 1, reason: 'a is already there');
    expect(to.entries.map((e) => e.id).toSet(), {'a', 'b'});
    expect(await to.importJson(from.exportJson()), 0);

    final fresh = CollectionStore(MemoryStorage());
    await fresh.importJson(from.exportJson());
    expect(fresh.photo('a'), isNotNull);
    expect(img.decodeJpg(fresh.photo('a')!)!.width, 320);
  });

  test('a file that is not an export is refused', () async {
    final store = CollectionStore(MemoryStorage());
    expect(() => store.importJson('nope'), throwsFormatException);
    expect(() => store.importJson('{"x": 1}'), throwsFormatException);
    expect(await store.importJson('{"entries": [1, {"no": "id"}]}'), 0);
  });

  test('search looks at names, countries, years and notes', () async {
    final store = CollectionStore(MemoryStorage());
    await store.save(_entry('a', 'Egypt', year: '1998'));
    await store.save(
      _entry('b', 'Spain', notes: 'From the Madrid flea market'),
    );
    await store.save(_entry('c', 'egypt'));

    expect(store.search('').length, 3);
    expect(store.search('EGYPT').map((e) => e.id).toSet(), {'a', 'c'});
    expect(store.search('1998').single.id, 'a');
    expect(store.search('madrid').single.id, 'b');
    expect(store.search('zzz'), isEmpty);
  });

  test('countries are counted case-insensitively, most first', () async {
    final store = CollectionStore(MemoryStorage());
    await store.save(_entry('a', 'Egypt'));
    await store.save(_entry('b', 'egypt'));
    await store.save(_entry('c', 'Spain'));
    await store.save(_entry('d', ''));
    final counts = store.countryCounts();
    expect(counts.map((c) => c.value), [2, 1]);
    expect(counts.first.key.toLowerCase(), 'egypt');
  });

  test('the map knows the usual ways of writing a country', () {
    final map = WorldMap.parse(File('assets/world.json').readAsStringSync());
    for (final name in [
      'Egypt',
      'Spain',
      'England',
      'UK',
      'USA',
      'United States',
      'UAE',
      'Czech Republic',
      'Ivory Coast',
      'Turkey',
      'Saudi Arabia',
    ]) {
      expect(map.lookup(name), isNotNull, reason: name);
    }
    expect(map.lookup('Atlantis'), isNull);
  });

  testWidgets('picking a country filters the collection', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final store = CollectionStore(MemoryStorage());
    await store.save(_entry('a', 'Egypt'));
    await store.save(_entry('b', 'Spain'));
    await tester.pumpWidget(CollectorApp(store: store));

    expect(find.text('1 a · Egypt'), findsOneWidget);
    expect(find.text('1 b · Spain'), findsOneWidget);

    await tester.tap(find.byTooltip('Countries'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Spain'));
    await tester.pumpAndSettle();

    expect(find.text('1 a · Egypt'), findsNothing);
    expect(find.text('1 b · Spain'), findsOneWidget);
    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('1 a · Egypt'), findsOneWidget);
  });
}
