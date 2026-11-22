import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

import '../data/identifier.dart';
import '../data/store.dart';
import '../main.dart';
import '../models/entry.dart';
import 'pieces.dart';
import 'theme.dart';

/// Adds a new piece from a photo (identifying it when a key is set) or edits
/// an existing one.
class EditorPage extends StatefulWidget {
  const EditorPage({super.key, this.photo, this.entry});

  final Uint8List? photo;
  final Entry? entry;

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  late String _kind = widget.entry?.kind ?? 'coin';
  late final _denomination = TextEditingController(
    text: widget.entry?.denomination,
  );
  late final _country = TextEditingController(text: widget.entry?.country);
  late final _currency = TextEditingController(text: widget.entry?.currency);
  late final _year = TextEditingController(text: widget.entry?.year);
  late final _material = TextEditingController(text: widget.entry?.material);
  late final _description = TextEditingController(
    text: widget.entry?.description,
  );
  late final _notes = TextEditingController(text: widget.entry?.notes);
  late String _confidence = widget.entry?.confidence ?? '';

  bool _busy = false;
  String? _message;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final key = AppScope.of(context).store.apiKey;
    if (widget.entry == null && widget.photo != null) {
      if (key == null) {
        _message =
            'Add an API key in Settings to identify pieces from the photo. '
            'For now, fill in what you know.';
      } else {
        _identify(key);
      }
    }
  }

  Future<void> _identify(String key) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final r = await AppScope.of(context).identifier
          .identify(widget.photo!, key);
      if (!mounted) return;
      setState(() {
        if (!r.isCurrency) {
          _message =
              'This does not look like a coin or banknote. Try a closer photo '
              'or fill in the details yourself.';
          return;
        }
        _kind = r.kind == 'banknote' ? 'banknote' : 'coin';
        _denomination.text = r.denomination;
        _country.text = r.country;
        _currency.text = r.currency;
        _year.text = r.year;
        _material.text = r.material;
        _description.text = r.description;
        _confidence = r.confidence;
        _message = r.confidence == 'high'
            ? null
            : 'Identified with ${r.confidence} confidence. Check the details.';
      });
    } on IdentifyException catch (e) {
      if (mounted) setState(() => _message = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final store = AppScope.of(context).store;
    final base =
        widget.entry ??
        Entry(
          id: newEntryId(),
          kind: _kind,
          country: '',
          denomination: '',
          addedAt: DateTime.now(),
        );
    final entry = base.copyWith(
      kind: _kind,
      denomination: _denomination.text.trim(),
      country: _country.text.trim(),
      currency: _currency.text.trim(),
      year: _year.text.trim(),
      material: _material.text.trim(),
      description: _description.text.trim(),
      notes: _notes.text.trim(),
      confidence: _confidence,
    );
    await store.save(entry, photo: widget.photo);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    for (final c in [
      _denomination,
      _country,
      _currency,
      _year,
      _material,
      _description,
      _notes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context).store;
    final photo =
        widget.photo ??
        (widget.entry == null ? null : store.photo(widget.entry!.id));
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry == null ? 'New piece' : 'Edit piece'),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: FilledButton(
              onPressed: _busy ? null : _save,
              child: const Text('Save'),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PiecePhoto(kind: _kind, bytes: photo, size: 180),
                    if (_busy) const _ScanSweep(size: 180),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_busy)
                Text(
                  'Reading the piece…',
                  textAlign: TextAlign.center,
                  style: text.titleSmall?.copyWith(color: felt),
                ),
              if (_message != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: brass.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_message!, style: text.bodyMedium),
                ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'coin', label: Text('Coin')),
                  ButtonSegment(value: 'banknote', label: Text('Banknote')),
                ],
                selected: {_kind},
                onSelectionChanged: (s) => setState(() => _kind = s.first),
              ),
              const SizedBox(height: 16),
              _Field('Denomination', _denomination, hint: 'e.g. 1 pound'),
              _Field('Country', _country),
              _Field('Currency', _currency, hint: 'e.g. Egyptian pound'),
              Row(
                children: [
                  Expanded(child: _Field('Year or era', _year)),
                  const SizedBox(width: 12),
                  Expanded(child: _Field('Material', _material)),
                ],
              ),
              _Field('What it shows', _description, lines: 3),
              _Field(
                'My notes',
                _notes,
                lines: 4,
                hint: 'Where it came from, its condition, the story behind it',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field(this.label, this.controller, {this.hint, this.lines = 1});

  final String label;
  final TextEditingController controller;
  final String? hint;
  final int lines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        minLines: lines,
        maxLines: lines == 1 ? 1 : lines + 4,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(labelText: label, hintText: hint),
      ),
    );
  }
}

/// A brass line sweeping over the photo while it is being read.
class _ScanSweep extends StatefulWidget {
  const _ScanSweep({required this.size});
  final double size;

  @override
  State<_ScanSweep> createState() => _ScanSweepState();
}

class _ScanSweepState extends State<_ScanSweep>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => SizedBox(
          width: widget.size * 1.6,
          height: widget.size,
          child: Align(
            alignment: Alignment(0, -1 + 2 * _c.value),
            child: Container(
              height: 3,
              decoration: const BoxDecoration(
                color: brass,
                boxShadow: [BoxShadow(color: brass, blurRadius: 12)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
