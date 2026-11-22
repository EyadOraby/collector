import 'package:material_ui/material_ui.dart';

import 'data/identifier.dart';
import 'data/store.dart';
import 'ui/home_page.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await HiveStorage.open();
  runApp(CollectorApp(store: CollectionStore(storage)));
}

/// Shared objects for every screen.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.store,
    required this.identifier,
    required super.child,
  });

  final CollectionStore store;
  final Identifier identifier;

  static AppScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!;

  @override
  bool updateShouldNotify(AppScope old) =>
      store != old.store || identifier != old.identifier;
}

class CollectorApp extends StatelessWidget {
  const CollectorApp({super.key, required this.store, this.identifier});

  final CollectionStore store;
  final Identifier? identifier;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      store: store,
      identifier: identifier ?? Identifier(),
      child: MaterialApp(
        title: 'Collector',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const HomePage(),
      ),
    );
  }
}
