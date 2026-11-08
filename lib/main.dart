import 'package:material_ui/material_ui.dart';

import 'package:mexy_laziness/app/app.dart';
import 'package:mexy_laziness/features/configuration/configuration.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final configuration = await Configuration.load();

  runApp(MyApp(configuration: configuration));
}
