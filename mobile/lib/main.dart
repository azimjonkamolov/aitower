import 'package:flutter/material.dart';
import 'l10n/strings.dart';
import 'screens/shell.dart';
import 'services/local_store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Lang.load();
  await LocalStore.i.load();
  LocalStore.i.recordSession();
  runApp(const TourismApp());
}

class TourismApp extends StatelessWidget {
  const TourismApp({super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String>(
        valueListenable: Lang.current,
        builder: (_, __, ___) => MaterialApp(
          title: 'AI Smart Tourism',
          debugShowCheckedModeBanner: false,
          theme: appTheme(),
          home: Shell(),
        ),
      );
}
