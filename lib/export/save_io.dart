import 'dart:convert';

import 'package:share_plus/share_plus.dart';

/// Opens the share sheet with [text] as a file.
Future<void> saveTextFile(String name, String text) async {
  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile.fromData(
          utf8.encode(text),
          name: name,
          mimeType: 'application/json',
        ),
      ],
      fileNameOverrides: [name],
    ),
  );
}
