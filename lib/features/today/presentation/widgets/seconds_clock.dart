import 'dart:async';

import 'package:material_3_expressive/material_3_expressive.dart' as m3e;
import 'package:material_ui/material_ui.dart';

/// 可变字轴：Google Sans Flex 的 wght / wdth / ROND。
///
/// 字体缺失某个轴时，该轴会被渲染器忽略，不会报错。
const List<FontVariation> _fontVariations = [
  FontVariation('wght', 900),
  FontVariation('wdth', 50),
  FontVariation('ROND', 100),
];

/// 等宽数字：秒数跳动时整行宽度不变，避免左右抖动。
const List<FontFeature> _fontFeatures = [FontFeature.tabularFigures()];

/// 秒级实时时钟。
///
/// 显示的是系统当前时间（[DateTime.now]），不是计时器 / 秒表。
///
/// - 小时、分钟：数字变化时向上滚动
/// - 秒：数字变化时淡入淡出
/// - 只在可见时计时（跟随 [TickerMode]），隐藏时停掉 timer
class Clock extends StatefulWidget {
  const Clock({
    super.key,
    this.hourMinuteSize = 80,
    this.secondSize = 64,
    this.style,
    this.secondStyle,
    this.now,
  });

  /// 小时、分钟的字号。
  final double hourMinuteSize;

  /// 秒数的字号，默认略小于 [hourMinuteSize]。
  final double secondSize;

  /// 全局附加样式（如颜色），对全部数字生效。
  final TextStyle? style;

  /// 秒数专属样式，优先级高于 [style]。
  ///
  /// 只改秒数的字重、可变字轴、颜色等时用这里，例如
  /// `secondStyle: TextStyle(fontWeight: FontWeight.w400)`。
  final TextStyle? secondStyle;

  /// 时间源，默认 [DateTime.now]。测试时可注入固定时间以获得确定性输出。
  final DateTime Function()? now;

  @override
  State<Clock> createState() => _ClockState();
}

class _ClockState extends State<Clock> {
  late DateTime _now = _readNow();
  Timer? _timer;
  bool _ticking = false;

  DateTime _readNow() => widget.now?.call() ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 所在页面被 TickerMode(enabled: false) 隐藏时暂停计时。
    if (TickerMode.valuesOf(context).enabled) {
      _start();
    } else {
      _stop();
    }
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  void _start() {
    if (_ticking) return;
    _ticking = true;
    // 重新开始瞬间先对齐一次，避免显示恢复前的旧时间。
    _now = _readNow();
    _schedule();
  }

  void _stop() {
    _ticking = false;
    _timer?.cancel();
    _timer = null;
  }

  void _schedule() {
    if (!_ticking) return;
    // 对齐到「下一个整秒」，而不是固定 1s 间隔 —— 否则每次回调的延迟会累积成漂移。
    final delay = 1000 - _readNow().millisecond;
    _timer = Timer(Duration(milliseconds: delay), () {
      if (!mounted || !_ticking) return;
      setState(() => _now = _readNow());
      _schedule();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final mainStyle = _styleFor(
      fontSize: widget.hourMinuteSize,
      color: colorScheme.onSurface,
    );
    final secondStyle = _styleFor(
      fontSize: widget.secondSize,
      color: colorScheme.onSurface,
      overrides: widget.secondStyle,
    );
    // 冒号弱化到 80% 不透明度，让视觉焦点落在数字上。
    final colonStyle = mainStyle.copyWith(
      color: (mainStyle.color ?? colorScheme.onSurface).withValues(alpha: 0.8),
    );

    return RepaintBoundary(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          _RollingNumber(text: _two(_now.hour), style: mainStyle),
          Text(':', style: colonStyle),
          _RollingNumber(text: _two(_now.minute), style: mainStyle),
          Text(':', style: colonStyle),
          _FadingNumber(text: _two(_now.second), style: secondStyle),
        ],
      ),
    );
  }

  /// 优先级从低到高：组件默认值 → [style]（全局）→ [overrides]（秒数专属）。
  ///
  /// 三者都没指定字号时，使用传入的 [fontSize]；
  /// 都没指定字重时，由 `wght` 轴推导（见 [_weightForVariations]）。
  TextStyle _styleFor({
    required double fontSize,
    required Color color,
    TextStyle? overrides,
  }) {
    final defaults = TextStyle(
      color: color,
      fontFeatures: _fontFeatures,
      fontVariations: _fontVariations,
    );
    final merged = defaults.merge(widget.style).merge(overrides);
    return merged.copyWith(
      fontSize: merged.fontSize ?? fontSize,
      fontWeight:
          merged.fontWeight ?? _weightForVariations(merged.fontVariations),
    );
  }

  /// 从 `wght` 轴推导出对应的 [FontWeight]。
  ///
  /// 两者必须一致：若 `fontWeight` 比 `wght` 轴更重（例如 style 想要 w900、
  /// 但秒数把轴设成 500），Skia 会在已加粗的字形上再叠加一次伪粗体，
  /// 同一笔画被画两遍 —— 细笔画字符（如 `1`）会出现明显的描边/空心感。
  static FontWeight _weightForVariations(List<FontVariation>? variations) {
    if (variations == null) return FontWeight.w400;
    for (final variation in variations) {
      if (variation.axis == 'wght') {
        final index = (variation.value / 100).round() - 1;
        return FontWeight.values[index.clamp(0, 8)];
      }
    }
    return FontWeight.w400;
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}

/// 数字变化时向上滚动的数字块（用于小时、分钟）。
class _RollingNumber extends StatefulWidget {
  const _RollingNumber({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  State<_RollingNumber> createState() => _RollingNumberState();
}

class _RollingNumberState extends State<_RollingNumber>
    with SingleTickerProviderStateMixin {
  // value: 1 表示动画已完成，即静止在「当前数字」上。
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: m3e.M3EMotion.medium3,
    value: 1,
  );

  late String _previous = widget.text;

  @override
  void didUpdateWidget(covariant _RollingNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) {
      _previous = oldWidget.text;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ClipRect 是必须的：FractionalTranslation 只影响绘制，不影响布局，
    // 因此 Stack 不会因为「溢出」而自动裁剪，滚动中的旧数字会画到框外。
    return ClipRect(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final progress = m3e.M3EMotion.emphasizedDecelerate.transform(
            _controller.value,
          );
          return Stack(
            alignment: Alignment.center,
            children: [
              if (progress < 1)
                FractionalTranslation(
                  translation: Offset(0, -progress), // 旧数字向上滚出
                  child: Text(_previous, style: widget.style),
                ),
              FractionalTranslation(
                translation: Offset(0, 1 - progress), // 新数字自下方滚入
                child: Text(widget.text, style: widget.style),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 数字变化时淡入淡出的数字块（用于秒）。
class _FadingNumber extends StatelessWidget {
  const _FadingNumber({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: m3e.M3EMotion.short4,
      switchInCurve: Curves.easeIn,
      switchOutCurve: Curves.easeOut,
      // 默认 transitionBuilder 就是 FadeTransition，正是这里需要的效果。
      child: Text(text, key: ValueKey<String>(text), style: style),
    );
  }
}
