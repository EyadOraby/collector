import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../main.dart';
import '../models/entry.dart';
import 'editor_page.dart';
import 'entry_page.dart';
import 'pieces.dart';
import 'settings_page.dart';
import 'theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _kind;

  Future<void> _scan() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose a photo'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1400,
      maxHeight: 1400,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => EditorPage(photo: bytes)));
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context).store;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final all = store.entries;
        final shown = _kind == null
            ? all
            : all.where((e) => e.kind == _kind).toList();
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _Header(onSettings: _openSettings)),
              if (all.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        for (final (label, kind) in [
                          ('All', null),
                          ('Coins', 'coin'),
                          ('Banknotes', 'banknote'),
                        ])
                          ChoiceChip(
                            label: Text(label),
                            selected: _kind == kind,
                            onSelected: (_) => setState(() => _kind = kind),
                          ),
                      ],
                    ),
                  ),
                ),
              if (all.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                  sliver: SliverGrid.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 220,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.78,
                        ),
                    itemCount: shown.length,
                    itemBuilder: (context, i) => _PieceCard(entry: shown[i]),
                  ),
                ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _scan,
            icon: const Icon(Icons.center_focus_strong_outlined),
            label: const Text('Scan a piece'),
          ),
        );
      },
    );
  }

  void _openSettings() =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => const SettingsPage()));
}

class _Header extends StatelessWidget {
  const _Header({required this.onSettings});
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context).store;
    final text = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [felt, feltDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 8, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Collector',
                    style: text.headlineMedium?.copyWith(
                      color: paper,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Settings',
                    onPressed: onSettings,
                    icon: const Icon(Icons.tune, color: paper),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Coins and banknotes, with a note for every piece.',
                style: text.bodyMedium?.copyWith(
                  color: paper.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _Stat(value: store.coins, label: 'coins'),
                  _Stat(value: store.banknotes, label: 'banknotes'),
                  _Stat(value: store.countries, label: 'countries'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: text.headlineSmall?.copyWith(
              color: brass,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(label, style: text.labelMedium?.copyWith(color: paper)),
        ],
      ),
    );
  }
}

class _PieceCard extends StatelessWidget {
  const _PieceCard({required this.entry});
  final Entry entry;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context).store;
    final text = Theme.of(context).textTheme;
    return Material(
      color: card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => EntryPage(id: entry.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Center(
                  child: FittedBox(
                    child: Hero(
                      tag: 'photo-${entry.id}',
                      child: PiecePhoto(
                        kind: entry.kind,
                        bytes: store.photo(entry.id),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                entry.title.isEmpty ? 'Unnamed piece' : entry.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (entry.year.isNotEmpty)
                Text(entry.year, style: text.bodySmall?.copyWith(color: muted)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const PiecePhoto(kind: 'coin', size: 96),
          const SizedBox(height: 20),
          Text(
            'Start the collection',
            style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Scan a coin or banknote. With an API key in Settings, the app '
            'reads the country, denomination and year from the photo; without '
            'one, you fill them in yourself.',
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: muted, height: 1.45),
          ),
        ],
      ),
    );
  }
}
