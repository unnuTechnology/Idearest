import 'package:material_ui/material_ui.dart';

import 'package:mexy_laziness/app/theme/app_theme.dart';
import 'package:mexy_laziness/core/ui/responsive/responsive_shell.dart';
import 'package:mexy_laziness/features/configuration/configuration.dart';

/// 应用根组件：只做「装配」——配置、主题、壳、路由。
///
/// 业务页面不要从这里直接引用，页面由 [ResponsiveShell] 及各 feature 负责。
class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.configuration});

  final Configuration configuration;

  @override
  Widget build(BuildContext context) {
    // 放在 MaterialApp 外层：任何页面的 context 都能拿到配置。
    return ConfigurationScope(
      configuration: configuration,
      child: MaterialApp(
        title: 'MexyLaziness',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: const ResponsiveShell(),
      ),
    );
  }
}
