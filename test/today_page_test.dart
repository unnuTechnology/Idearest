import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:idearest/app/app.dart';
import 'package:idearest/features/configuration/configuration.dart';

void main() {
  testWidgets('拖动滑块后，滑块位置与配置保持同步', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final configuration = await Configuration.load();

    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MyApp(configuration: configuration));
    await tester.pump();

    final slider = find.byType(M3ESlider);
    expect(slider, findsOneWidget);
    expect(
      tester.widget<M3ESlider>(slider).value,
      ClockConfig.defaultSecondSize,
    );

    await tester.drag(slider, const Offset(60, 0));
    await tester.pump();

    final size = configuration.clock.value.effectiveSecondSize;
    expect(size, greaterThan(ClockConfig.defaultSecondSize));

    // 关键断言：滑块是受控组件，它的 value 必须跟着配置走，
    // 否则拖动时滑块会卡在原处（旧实现把 value 写死成了 64）。
    expect(tester.widget<M3ESlider>(slider).value, size);
  });
}
