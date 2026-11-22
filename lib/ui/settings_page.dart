import 'package:material_ui/material_ui.dart';

import '../data/identifier.dart';
import '../export/save_file.dart';
import '../main.dart';
import 'theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _key = TextEditingController();
  bool _show = false;

  @override
  void dispose() {
    _key.dispose();
    super.dispose();
  }

  void _toast(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context).store;
    final text = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final hasKey = store.apiKey != null;
        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                children: [
                  Text(
                    'Identify from photos',
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Scanning uses Claude (${Identifier.model}) with your own '
                    'Anthropic API key. The key stays on this device and is '
                    'only ever sent to api.anthropic.com.',
                    style: text.bodyMedium?.copyWith(
                      color: muted,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (hasKey)
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: felt),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text('A key is saved on this device.'),
                        ),
                        TextButton(
                          onPressed: () async {
                            await store.setApiKey(null);
                            _toast('Key removed');
                          },
                          child: const Text('Remove'),
                        ),
                      ],
                    )
                  else ...[
                    TextField(
                      controller: _key,
                      obscureText: !_show,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        labelText: 'Anthropic API key',
                        suffixIcon: IconButton(
                          tooltip: _show ? 'Hide' : 'Show',
                          icon: Icon(
                            _show ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () => setState(() => _show = !_show),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: FilledButton(
                        onPressed: () async {
                          if (_key.text.trim().isEmpty) return;
                          await store.setApiKey(_key.text);
                          _key.clear();
                          _toast('Key saved on this device');
                        },
                        child: const Text('Save key'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  const Divider(color: line),
                  const SizedBox(height: 20),
                  Text(
                    'Export',
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Saves the collection as collection.json, with small photos, '
                    'ready for the Coins and banknotes page on the portfolio.',
                    style: text.bodyMedium?.copyWith(
                      color: muted,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: OutlinedButton.icon(
                      onPressed: store.entries.isEmpty
                          ? null
                          : () async {
                              try {
                                await saveTextFile(
                                  'collection.json',
                                  store.exportJson(),
                                );
                              } catch (e) {
                                _toast('Could not export: $e');
                              }
                            },
                      icon: const Icon(Icons.ios_share),
                      label: Text('Export ${store.entries.length} pieces'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
