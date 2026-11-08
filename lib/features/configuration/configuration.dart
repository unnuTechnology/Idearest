import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 应用配置的读写入口。
///
/// 职责只有两件：
/// 1. 启动时把磁盘上的值读进内存（通过 [ValueNotifier] 可监听）；
/// 2. 修改时先更新内存、再写回磁盘。
///
/// 页面不要直接碰 [SharedPreferences]，一律通过这里，方便日后换存储。
class Configuration {
  // settings.colorMode
  static const _kSecondSize = 'settings.clock.secondSize';

  final SharedPreferences _prefs;

  /// 时钟相关配置。订阅它即可在配置变化时重建对应 UI。
  final ValueNotifier<ClockConfig> clock;

  Configuration._(this._prefs)
    : clock = ValueNotifier(ClockConfig.fromPrefs(_prefs));

  /// 在 `main()` 里调用一次，随后通过 [ConfigurationScope] 注入组件树。
  static Future<Configuration> load() async =>
      Configuration._(await SharedPreferences.getInstance());

  Future<void> setSecondSize(double value) async {
    previewSecondSize(value);
    await persistSecondSize();
  }

  /// 拖动过程中只更新内存，不写磁盘。
  ///
  /// 滑块每秒会产生几十次回调，逐帧写盘没有意义；
  /// 松手时再用 [persistSecondSize] 落盘即可。
  void previewSecondSize(double value) {
    final next = ClockConfig.clampSecondSize(value);
    if (clock.value.secondSize == next) return;
    clock.value = clock.value.copyWith(secondSize: next);
  }

  /// 把内存中的当前字号写入磁盘。
  ///
  /// 不要改成从回调参数取值：`M3ESlider` 的 `onChangeEnd` 传的是它上一次构建
  /// 时的 `value`，快速拖动时可能是旧值，会把刚拖到的结果覆盖掉。
  Future<void> persistSecondSize() async {
    await _prefs.setDouble(_kSecondSize, clock.value.effectiveSecondSize);
  }
}

/// 时钟配置。
///
/// 刻意做成不可变：`ValueNotifier` 靠 `==` 判断是否需要通知，
/// 可变对象直接改字段会让界面「改了但不刷新」，且极难排查。
@immutable
class ClockConfig {
  const ClockConfig({this.secondSize});

  /// 秒数字号；`null` 表示未配置，使用 [defaultSecondSize]。
  final double? secondSize;

  /// 秒数字号的默认值，与 [Clock.secondSize] 的默认值保持一致。
  static const double defaultSecondSize = 64;

  /// 秒数字号的可调范围，UI（如滑块）和夹紧逻辑共用这一份。
  static const double minSecondSize = 32;
  static const double maxSecondSize = 128;

  /// 实际生效的字号：已兜底默认值，并夹紧到合法区间。
  ///
  /// UI 直接用这个值即可，不必再各自写 `??` 或 `clamp`。
  double get effectiveSecondSize =>
      clampSecondSize(secondSize ?? defaultSecondSize);

  /// 把任意值夹紧到 [minSecondSize] ~ [maxSecondSize]。
  static double clampSecondSize(double value) =>
      value.clamp(minSecondSize, maxSecondSize).toDouble();

  ClockConfig.fromPrefs(SharedPreferences prefs)
    : secondSize = prefs.getDouble(Configuration._kSecondSize);

  ClockConfig copyWith({double? secondSize}) =>
      ClockConfig(secondSize: secondSize ?? this.secondSize);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClockConfig && other.secondSize == secondSize;

  @override
  int get hashCode => secondSize.hashCode;
}

/// 把 [Configuration] 注入组件树。
///
/// 注意：拿到 [Configuration] 本身不会因为配置变化而重建，
/// 读具体配置时请配合 [ValueListenableBuilder] 订阅对应字段，
/// 这样只有真正依赖该字段的那一小块 UI 会重建。
class ConfigurationScope extends InheritedWidget {
  const ConfigurationScope({
    super.key,
    required this.configuration,
    required super.child,
  });

  final Configuration configuration;

  static Configuration of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ConfigurationScope>();
    if (scope == null) {
      throw FlutterError(
        'ConfigurationScope.of() 找不到上层节点。\n'
        '请确认 MyApp 里把 ConfigurationScope 包在了 MaterialApp 外层。',
      );
    }
    return scope.configuration;
  }

  @override
  bool updateShouldNotify(ConfigurationScope oldWidget) =>
      !identical(configuration, oldWidget.configuration);
}
