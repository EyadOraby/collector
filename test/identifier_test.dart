import 'dart:convert';
import 'dart:typed_data';

import 'package:collector/data/identifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _reply(Map<String, Object?> body, [int status = 200]) =>
    http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json'},
    );

const _coin = {
  'is_currency': true,
  'kind': 'coin',
  'country': 'Egypt',
  'denomination': '1 pound',
  'currency': 'Egyptian pound',
  'year': '2019',
  'material': 'Bimetallic',
  'description': 'King Tutankhamun on one side.',
  'confidence': 'high',
};

void main() {
  final photo = Uint8List.fromList([1, 2, 3]);

  test('sends the photo with the right headers and schema', () async {
    late http.Request sent;
    final id = Identifier(
      client: MockClient((req) async {
        sent = req;
        return _reply({
          'stop_reason': 'end_turn',
          'content': [
            {'type': 'text', 'text': jsonEncode(_coin)},
          ],
        });
      }),
    );
    final r = await id.identify(photo, 'test-key');

    expect(sent.url.toString(), 'https://api.anthropic.com/v1/messages');
    expect(sent.headers['x-api-key'], 'test-key');
    expect(sent.headers['anthropic-version'], '2026-10-21');
    expect(sent.headers['anthropic-dangerous-direct-browser-access'], 'true');
    final body = jsonDecode(sent.body) as Map<String, Object?>;
    expect(body['model'], 'claude-opus-5-5');
    expect(body['fallbacks'], 'default');
    final format = (body['output_config']! as Map)['format'] as Map;
    expect(format['type'], 'json_schema');
    final content =
        ((body['messages']! as List).first as Map)['content'] as List;
    final image = content.first as Map;
    expect(image['type'], 'image');
    expect((image['source'] as Map)['data'], base64Encode(photo));

    expect(r.isCurrency, isTrue);
    expect(r.country, 'Egypt');
    expect(r.denomination, '1 pound');
    expect(r.confidence, 'high');
  });

  test('a rejected key gives a clear message', () async {
    final id = Identifier(
      client: MockClient(
        (_) async => _reply({
          'type': 'error',
          'error': {
            'type': 'authentication_error',
            'message': 'invalid x-api-key',
          },
        }, 401),
      ),
    );
    expect(
      () => id.identify(photo, 'bad'),
      throwsA(
        isA<IdentifyException>().having(
          (e) => e.message,
          'message',
          contains('Settings'),
        ),
      ),
    );
  });

  test('a refusal is reported, not parsed', () async {
    final id = Identifier(
      client: MockClient(
        (_) async => _reply({'stop_reason': 'refusal', 'content': <Object>[]}),
      ),
    );
    expect(() => id.identify(photo, 'k'), throwsA(isA<IdentifyException>()));
  });

  test('a network failure is reported', () async {
    final id = Identifier(
      client: MockClient((_) async => throw http.ClientException('offline')),
    );
    expect(() => id.identify(photo, 'k'), throwsA(isA<IdentifyException>()));
  });
}
