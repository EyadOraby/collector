import 'dart:convert';

import 'package:collector/data/store.dart';
import 'package:collector/models/entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

Entry _entry(String id, String kind, String country, int day) => Entry(
  id: id,
  kind: kind,
  country: country,
  denomination: '1',
  addedAt: DateTime(2026, 11, day),
);

void main() {
  test('entries survive a reload, newest first', () async {
    final storage = MemoryStorage();
    final store = CollectionStore(storage);
    await store.save(_entry('a', 'coin', 'Egypt', 1));
    await store.save(_entry('b', 'banknote', 'Spain', 2));
    await store.save(_entry('c', 'coin', 'egypt', 3));

    final again = CollectionStore(storage);
    expect(again.entries.map((e) => e.id), ['c', 'b', 'a']);
    expect(again.coins, 2);
    expect(again.banknotes, 1);
    expect(again.countries, 2);
  });

  test('editing keeps one entry and delete removes the photo', () async {
    final store = CollectionStore(MemoryStorage());
    final photo = img.encodeJpg(img.Image(width: 10, height: 10));
    await store.save(_entry('a', 'coin', 'Egypt', 1), photo: photo);
    await store.save(store.byId('a')!.copyWith(notes: 'From my grandfather'));
    expect(store.entries, hasLength(1));
    expect(store.byId('a')!.notes, 'From my grandfather');
    expect(store.photo('a'), isNotNull);

    await store.delete('a');
    expect(store.entries, isEmpty);
    expect(store.photo('a'), isNull);
  });

  test('export carries every entry with a small JPEG thumbnail', () async {
    final store = CollectionStore(MemoryStorage());
    final big = img.encodeJpg(img.Image(width: 800, height: 600));
    await store.save(_entry('a', 'coin', 'Egypt', 1), photo: big);
    await store.save(_entry('b', 'banknote', 'Spain', 2));

    final json = jsonDecode(store.exportJson()) as Map<String, Object?>;
    final entries = (json['entries']! as List).cast<Map<String, Object?>>();
    expect(entries, hasLength(2));
    final thumb = entries.firstWhere((e) => e['id'] == 'a')['thumb']! as String;
    expect(thumb, startsWith('data:image/jpeg;base64,'));
    final decoded = img.decodeJpg(base64Decode(thumb.split(',').last))!;
    expect(decoded.width, 320);
    expect(
      entries.firstWhere((e) => e['id'] == 'b').containsKey('thumb'),
      isFalse,
    );
  });

  test('the API key is stored trimmed and can be removed', () async {
    final store = CollectionStore(MemoryStorage());
    expect(store.apiKey, isNull);
    await store.setApiKey('  key  ');
    expect(store.apiKey, 'key');
    await store.setApiKey(null);
    expect(store.apiKey, isNull);
  });
}
