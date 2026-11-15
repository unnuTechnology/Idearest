import 'package:material_ui/material_ui.dart';

import 'package:idearest/app/app.dart';
import 'package:idearest/features/configuration/configuration.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final configuration = await Configuration.load();

  runApp(MyApp(configuration: configuration));
}
