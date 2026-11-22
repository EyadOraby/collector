import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Saves [text] as a download in the browser.
Future<void> saveTextFile(String name, String text) async {
  final blob = web.Blob(
    [text.toJS].toJS,
    web.BlobPropertyBag(type: 'application/json'),
  );
  final url = web.URL.createObjectURL(blob);
  final link = web.HTMLAnchorElement()
    ..href = url
    ..download = name;
  link.click();
  web.URL.revokeObjectURL(url);
}
