import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:idearest/features/configuration/configuration.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('未配置时回退到默认字号', () async {
    SharedPreferences.setMockInitialValues({});

    final configuration = await Configuration.load();

    expect(configuration.clock.value.secondSize, isNull);
    expect(
      configuration.clock.value.effectiveSecondSize,
      ClockConfig.defaultSecondSize,
    );
  });

  test('启动时从磁盘恢复已保存的值', () async {
    SharedPreferences.setMockInitialValues({
      'settings.clock.secondSize': 100.0,
    });

    final configuration = await Configuration.load();

    expect(configuration.clock.value.effectiveSecondSize, 100.0);
  });

  test('setSecondSize 同时更新内存并落盘', () async {
    SharedPreferences.setMockInitialValues({});
    final configuration = await Configuration.load();

    var notifications = 0;
    configuration.clock.addListener(() => notifications++);

    await configuration.setSecondSize(96);

    expect(configuration.clock.value.secondSize, 96.0);
    expect(notifications, 1);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getDouble('settings.clock.secondSize'), 96.0);
  });

  test('previewSecondSize 只更新内存，不写磁盘', () async {
    SharedPreferences.setMockInitialValues({});
    final configuration = await Configuration.load();

    configuration.previewSecondSize(88);

    expect(configuration.clock.value.secondSize, 88.0);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getDouble('settings.clock.secondSize'), isNull);
  });

  test('超出范围的值会被夹紧', () async {
    SharedPreferences.setMockInitialValues({
      'settings.clock.secondSize': 999.0,
    });

    final configuration = await Configuration.load();

    expect(
      configuration.clock.value.effectiveSecondSize,
      ClockConfig.maxSecondSize,
    );

    configuration.previewSecondSize(-10);

    expect(
      configuration.clock.value.effectiveSecondSize,
      ClockConfig.minSecondSize,
    );
  });

  test('写入相同的值不会触发多余通知', () async {
    SharedPreferences.setMockInitialValues({});
    final configuration = await Configuration.load();
    await configuration.setSecondSize(96);

    var notifications = 0;
    configuration.clock.addListener(() => notifications++);

    await configuration.setSecondSize(96);

    // ClockConfig 覆写了 ==，值没变时 ValueNotifier 不通知。
    expect(notifications, 0);
  });
}
