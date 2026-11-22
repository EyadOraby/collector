import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// What Claude reads from a photo of a coin or banknote.
class Identification {
  const Identification({
    required this.isCurrency,
    required this.kind,
    required this.country,
    required this.denomination,
    required this.currency,
    required this.year,
    required this.material,
    required this.description,
    required this.confidence,
  });

  final bool isCurrency;
  final String kind;
  final String country;
  final String denomination;
  final String currency;
  final String year;
  final String material;
  final String description;
  final String confidence;

  factory Identification.fromJson(Map<String, Object?> j) => Identification(
    isCurrency: j['is_currency'] == true,
    kind: (j['kind'] as String?) ?? 'other',
    country: (j['country'] as String?) ?? '',
    denomination: (j['denomination'] as String?) ?? '',
    currency: (j['currency'] as String?) ?? '',
    year: (j['year'] as String?) ?? '',
    material: (j['material'] as String?) ?? '',
    description: (j['description'] as String?) ?? '',
    confidence: (j['confidence'] as String?) ?? 'low',
  );
}

class IdentifyException implements Exception {
  const IdentifyException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Calls the Claude Messages API straight from the device with the owner's
/// own key. The key never leaves the device except to api.anthropic.com.
class Identifier {
  Identifier({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static final _endpoint = Uri.parse('https://api.anthropic.com/v1/messages');
  static const model = 'claude-opus-5-5';

  static const _prompt =
      'This photo should show one coin or banknote. Identify it as precisely '
      'as the photo allows: issuing country, denomination, currency, year or '
      'era, and material. Describe what the side in the photo shows in one or '
      'two plain sentences. If you are unsure about a field, give your best '
      'estimate and lower the confidence; leave a field empty only if there '
      'is nothing to go on. If the photo shows no coin or banknote, set '
      'is_currency to false and kind to "other".';

  /// Structured output: the reply is guaranteed to match this schema.
  static const Map<String, Object> schema = {
    'type': 'object',
    'properties': {
      'is_currency': {'type': 'boolean'},
      'kind': {
        'type': 'string',
        'enum': ['coin', 'banknote', 'other'],
      },
      'country': {'type': 'string'},
      'denomination': {'type': 'string'},
      'currency': {'type': 'string'},
      'year': {'type': 'string'},
      'material': {'type': 'string'},
      'description': {'type': 'string'},
      'confidence': {
        'type': 'string',
        'enum': ['high', 'medium', 'low'],
      },
    },
    'required': [
      'is_currency',
      'kind',
      'country',
      'denomination',
      'currency',
      'year',
      'material',
      'description',
      'confidence',
    ],
    'additionalProperties': false,
  };

  Future<Identification> identify(Uint8List jpeg, String apiKey) async {
    final http.Response res;
    try {
      res = await _client.post(
        _endpoint,
        headers: {
          'content-type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2026-10-21',
          // Needed for calls made from a web page; the key is the owner's own.
          'anthropic-dangerous-direct-browser-access': 'true',
          // If the model declines, the API retries on a fallback model.
          'anthropic-beta': 'server-side-fallback-2026-07-01',
        },
        body: jsonEncode({
          'model': model,
          'max_tokens': 16000,
          'fallbacks': 'default',
          'output_config': {
            'effort': 'medium',
            'format': {'type': 'json_schema', 'schema': schema},
          },
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'image',
                  'source': {
                    'type': 'base64',
                    'media_type': 'image/jpeg',
                    'data': base64Encode(jpeg),
                  },
                },
                {'type': 'text', 'text': _prompt},
              ],
            },
          ],
        }),
      );
    } catch (_) {
      throw const IdentifyException(
        'Could not reach the identifier. Check the connection and try again.',
      );
    }

    final body = _decode(res.body);
    if (res.statusCode != 200) {
      final error = body?['error'];
      final message = error is Map ? error['message'] : null;
      throw IdentifyException(switch (res.statusCode) {
        401 => 'The API key was not accepted. Check it in Settings.',
        429 => 'Too many requests right now. Wait a moment and try again.',
        _ =>
          'The identifier returned an error (${res.statusCode})'
              '${message is String ? ': $message' : '.'}',
      });
    }
    if (body == null) {
      throw const IdentifyException('The identifier sent an unreadable reply.');
    }
    final stop = body['stop_reason'];
    if (stop == 'refusal') {
      throw const IdentifyException(
        'The identifier declined this photo. Fill in the details by hand.',
      );
    }
    if (stop == 'max_tokens') {
      throw const IdentifyException(
        'The reply was cut short. Try again with a clearer photo.',
      );
    }
    final content = body['content'];
    if (content is! List) {
      throw const IdentifyException('The identifier sent no result.');
    }
    for (final block in content) {
      if (block is Map && block['type'] == 'text') {
        final json = _decode(block['text'] as String? ?? '');
        if (json != null) return Identification.fromJson(json);
      }
    }
    throw const IdentifyException('The identifier sent no result.');
  }

  static Map<String, Object?>? _decode(String text) {
    try {
      final v = jsonDecode(text);
      return v is Map<String, Object?> ? v : null;
    } catch (_) {
      return null;
    }
  }
}
