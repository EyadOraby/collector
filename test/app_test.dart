import 'dart:convert';

import 'package:collector/data/identifier.dart';
import 'package:collector/data/store.dart';
import 'package:collector/main.dart';
import 'package:collector/ui/editor_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('an empty collection invites the first scan', (tester) async {
    await tester.pumpWidget(
      CollectorApp(store: CollectionStore(MemoryStorage())),
    );
    expect(find.text('Start the collection'), findsOneWidget);
    expect(find.text('Scan a piece'), findsOneWidget);
  });

  testWidgets('a scanned photo is identified, noted and saved', (tester) async {
    // A tall screen, so the whole form is built.
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final store = CollectionStore(MemoryStorage());
    await store.setApiKey('k');
    final reply = {
      'is_currency': true,
      'kind': 'banknote',
      'country': 'Spain',
      'denomination': '100 pesetas',
      'currency': 'Spanish peseta',
      'year': '1953',
      'material': 'Paper',
      'description': 'A portrait and a city view.',
      'confidence': 'medium',
    };
    final identifier = Identifier(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'stop_reason': 'end_turn',
            'content': [
              {'type': 'text', 'text': jsonEncode(reply)},
            ],
          }),
          200,
        ),
      ),
    );
    final photo = img.encodeJpg(img.Image(width: 40, height: 25));
    await tester.pumpWidget(CollectorApp(store: store, identifier: identifier));
    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    nav.push(MaterialPageRoute<void>(builder: (_) => EditorPage(photo: photo)));
    await tester.pumpAndSettle();

    expect(find.text('100 pesetas'), findsOneWidget);
    expect(find.textContaining('medium confidence'), findsOneWidget);
    final notes = find.widgetWithText(TextField, 'My notes');
    await tester.enterText(notes, 'Bought in Madrid');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(store.entries.single.denomination, '100 pesetas');
    expect(store.entries.single.notes, 'Bought in Madrid');
    expect(find.text('100 pesetas · Spain'), findsOneWidget);
  });
}
