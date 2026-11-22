import 'package:material_ui/material_ui.dart';

import '../main.dart';
import 'editor_page.dart';
import 'pieces.dart';
import 'theme.dart';

class EntryPage extends StatelessWidget {
  const EntryPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context).store;
    final text = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final e = store.byId(id);
        if (e == null) return const Scaffold();
        final facts = [
          ('Country', e.country),
          ('Denomination', e.denomination),
          ('Currency', e.currency),
          ('Year or era', e.year),
          ('Material', e.material),
        ].where((f) => f.$2.isNotEmpty);
        return Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => EditorPage(entry: e)),
                ),
              ),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete this piece?'),
                      content: const Text(
                        'Its photo and notes are removed too.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Keep'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true && context.mounted) {
                    Navigator.of(context).pop();
                    await store.delete(id);
                  }
                },
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                children: [
                  Center(
                    child: Hero(
                      tag: 'photo-$id',
                      child: PiecePhoto(
                        kind: e.kind,
                        bytes: store.photo(id),
                        size: 200,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    e.title.isEmpty ? 'Unnamed piece' : e.title,
                    style: text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        label: Text(e.kind == 'banknote' ? 'Banknote' : 'Coin'),
                      ),
                      if (e.confidence.isNotEmpty)
                        Chip(
                          label: Text(
                            'Identified · ${e.confidence} confidence',
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  for (final (label, value) in facts)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 120,
                            child: Text(
                              label,
                              style: text.bodyMedium?.copyWith(color: muted),
                            ),
                          ),
                          Expanded(child: Text(value, style: text.bodyLarge)),
                        ],
                      ),
                    ),
                  if (e.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      e.description,
                      style: text.bodyLarge?.copyWith(height: 1.5),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My notes',
                          style: text.labelLarge?.copyWith(color: felt),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          e.notes.isEmpty
                              ? 'No notes yet. Tap edit to add some.'
                              : e.notes,
                          style: text.bodyLarge?.copyWith(
                            height: 1.5,
                            color: e.notes.isEmpty ? muted : ink,
                          ),
                        ),
                      ],
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
