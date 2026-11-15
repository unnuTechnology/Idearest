import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:idearest/app/app.dart';
import 'package:idearest/core/ui/responsive/responsive_shell.dart';
import 'package:idearest/features/configuration/configuration.dart';
import 'package:idearest/features/fragments/presentation/pages/fragments_page.dart';
import 'package:idearest/features/loops/presentation/pages/loops_page.dart';
import 'package:idearest/features/today/presentation/pages/today_page.dart';

/// 页内有无限循环动画（M3ELoadingIndicator），pumpAndSettle 永远等不到静止，
/// 因此这里只用有界的 pump：一次处理点击 + 一次越过 300ms 的翻页动画。
Future<void> _settleNavigation(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('ResponsiveShell 默认展示 Today，并可切换到其他页面', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final configuration = await Configuration.load();

    // 窄屏：使用 NavigationBar 分支
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MyApp(configuration: configuration));
    await tester.pump();

    expect(find.byType(ResponsiveShell), findsOneWidget);
    expect(find.byType(TodayPage), findsOneWidget);
    expect(find.text('Idearest'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.widgets_outlined));
    await _settleNavigation(tester);
    expect(find.byType(FragmentsPage), findsOneWidget);

    await tester.tap(find.byIcon(Icons.refresh));
    await _settleNavigation(tester);
    expect(find.byType(LoopsPage), findsOneWidget);
  });
}
