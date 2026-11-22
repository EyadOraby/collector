import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

import '../models/entry.dart';

/// Where entries, photos and settings live. Hive on the device (IndexedDB on
/// the web); an in-memory version for tests.
abstract class CollectionStorage {
  Iterable<String> entries();
  Future<void> putEntry(String id, String json);
  Future<void> deleteEntry(String id);
  Uint8List? photo(String id);
  Future<void> putPhoto(String id, Uint8List bytes);
  String? setting(String key);
  Future<void> setSetting(String key, String? value);
}

class HiveStorage implements CollectionStorage {
  HiveStorage._(this._entries, this._photos, this._settings);

  final Box<String> _entries;
  final Box<Uint8List> _photos;
  final Box<String> _settings;

  static Future<HiveStorage> open() async {
    // On the web Hive uses IndexedDB and needs no folder.
    if (!kIsWeb) {
      Hive.init((await getApplicationDocumentsDirectory()).path);
    }
    return HiveStorage._(
      await Hive.openBox<String>('entries'),
      await Hive.openBox<Uint8List>('photos'),
      await Hive.openBox<String>('settings'),
    );
  }

  @override
  Iterable<String> entries() => _entries.values;
  @override
  Future<void> putEntry(String id, String json) => _entries.put(id, json);
  @override
  Future<void> deleteEntry(String id) async {
    await _entries.delete(id);
    await _photos.delete(id);
  }

  @override
  Uint8List? photo(String id) => _photos.get(id);
  @override
  Future<void> putPhoto(String id, Uint8List bytes) => _photos.put(id, bytes);
  @override
  String? setting(String key) => _settings.get(key);
  @override
  Future<void> setSetting(String key, String? value) =>
      value == null ? _settings.delete(key) : _settings.put(key, value);
}

class MemoryStorage implements CollectionStorage {
  final _entries = <String, String>{};
  final _photos = <String, Uint8List>{};
  final _settings = <String, String>{};

  @override
  Iterable<String> entries() => _entries.values;
  @override
  Future<void> putEntry(String id, String json) async => _entries[id] = json;
  @override
  Future<void> deleteEntry(String id) async {
    _entries.remove(id);
    _photos.remove(id);
  }

  @override
  Uint8List? photo(String id) => _photos[id];
  @override
  Future<void> putPhoto(String id, Uint8List bytes) async =>
      _photos[id] = bytes;
  @override
  String? setting(String key) => _settings[key];
  @override
  Future<void> setSetting(String key, String? value) async =>
      value == null ? _settings.remove(key) : _settings[key] = value;
}

class CollectionStore extends ChangeNotifier {
  CollectionStore(this._storage) {
    _entries = [
      for (final raw in _storage.entries())
        Entry.fromJson(jsonDecode(raw) as Map<String, Object?>),
    ]..sort((a, b) => b.addedAt.compareTo(a.addedAt));
  }

  final CollectionStorage _storage;
  late List<Entry> _entries;

  /// Newest first.
  List<Entry> get entries => List.unmodifiable(_entries);
  int get coins => _entries.where((e) => e.kind == 'coin').length;
  int get banknotes => _entries.where((e) => e.kind == 'banknote').length;
  int get countries => _entries
      .map((e) => e.country.trim().toLowerCase())
      .where((c) => c.isNotEmpty)
      .toSet()
      .length;

  Entry? byId(String id) {
    for (final e in _entries) {
      if (e.id == id) return e;
    }
    return null;
  }

  Uint8List? photo(String id) => _storage.photo(id);

  String? get apiKey {
    final k = _storage.setting('apiKey');
    return k == null || k.isEmpty ? null : k;
  }

  Future<void> setApiKey(String? key) async {
    await _storage.setSetting('apiKey', key?.trim());
    notifyListeners();
  }

  Future<void> save(Entry entry, {Uint8List? photo}) async {
    if (photo != null) await _storage.putPhoto(entry.id, photo);
    await _storage.putEntry(entry.id, jsonEncode(entry.toJson()));
    _entries
      ..removeWhere((e) => e.id == entry.id)
      ..add(entry)
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await _storage.deleteEntry(id);
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  /// The whole collection as JSON, each entry with a small JPEG thumbnail, in
  /// the shape the portfolio reads from `public/collection.json`.
  String exportJson({int thumbWidth = 320}) {
    final items = <Map<String, Object?>>[];
    for (final e in _entries) {
      final json = e.toJson();
      final bytes = _storage.photo(e.id);
      if (bytes != null) {
        final decoded = img.decodeImage(bytes);
        if (decoded != null) {
          final small = decoded.width > thumbWidth
              ? img.copyResize(decoded, width: thumbWidth)
              : decoded;
          json['thumb'] =
              'data:image/jpeg;base64,${base64Encode(img.encodeJpg(small, quality: 78))}';
        }
      }
      items.add(json);
    }
    return const JsonEncoder.withIndent('  ').convert({
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'entries': items,
    });
  }
}

/// A short, sortable, unique-enough id.
String newEntryId() {
  final now = DateTime.now().microsecondsSinceEpoch;
  return now.toRadixString(36);
}
