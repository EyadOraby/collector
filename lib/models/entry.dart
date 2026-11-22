/// One coin or banknote in the collection.
class Entry {
  const Entry({
    required this.id,
    required this.kind,
    required this.country,
    required this.denomination,
    this.currency = '',
    this.year = '',
    this.material = '',
    this.description = '',
    this.notes = '',
    this.confidence = '',
    required this.addedAt,
  });

  final String id;

  /// `coin` or `banknote`.
  final String kind;
  final String country;
  final String denomination;
  final String currency;

  /// A year, a range or an era, as written on the piece or estimated.
  final String year;
  final String material;

  /// What the piece shows, usually filled in by the identifier.
  final String description;

  /// Eyad's own notes: where it came from, condition, the story.
  final String notes;

  /// `high`, `medium` or `low` when identified from a photo; empty when typed in.
  final String confidence;
  final DateTime addedAt;

  String get title =>
      [denomination, country].where((s) => s.trim().isNotEmpty).join(' · ');

  Entry copyWith({
    String? kind,
    String? country,
    String? denomination,
    String? currency,
    String? year,
    String? material,
    String? description,
    String? notes,
    String? confidence,
  }) => Entry(
    id: id,
    kind: kind ?? this.kind,
    country: country ?? this.country,
    denomination: denomination ?? this.denomination,
    currency: currency ?? this.currency,
    year: year ?? this.year,
    material: material ?? this.material,
    description: description ?? this.description,
    notes: notes ?? this.notes,
    confidence: confidence ?? this.confidence,
    addedAt: addedAt,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind,
    'country': country,
    'denomination': denomination,
    'currency': currency,
    'year': year,
    'material': material,
    'description': description,
    'notes': notes,
    'confidence': confidence,
    'addedAt': addedAt.toIso8601String(),
  };

  factory Entry.fromJson(Map<String, Object?> json) => Entry(
    id: json['id']! as String,
    kind: (json['kind'] as String?) ?? 'coin',
    country: (json['country'] as String?) ?? '',
    denomination: (json['denomination'] as String?) ?? '',
    currency: (json['currency'] as String?) ?? '',
    year: (json['year'] as String?) ?? '',
    material: (json['material'] as String?) ?? '',
    description: (json['description'] as String?) ?? '',
    notes: (json['notes'] as String?) ?? '',
    confidence: (json['confidence'] as String?) ?? '',
    addedAt:
        DateTime.tryParse((json['addedAt'] as String?) ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );
}
