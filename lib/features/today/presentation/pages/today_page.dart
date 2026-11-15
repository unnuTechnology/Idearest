import 'package:m3e_core/m3e_core.dart';
import 'package:material_ui/material_ui.dart';

import 'package:idearest/features/configuration/configuration.dart';
import 'package:idearest/features/today/presentation/widgets/seconds_clock.dart';

/// Today 页。
class TodayPage extends StatelessWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context) {
    final configuration = ConfigurationScope.of(context);

    // 时钟和滑块依赖同一份配置，放在同一个 builder 里，避免重复订阅。
    return Center(
      child: ValueListenableBuilder<ClockConfig>(
        valueListenable: configuration.clock,
        builder: (context, config, _) {
          final secondSize = config.effectiveSecondSize;

          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // 窗口变窄时整体等比缩小，避免 Row 溢出。
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Clock(
                  secondSize: secondSize,
                  secondStyle: const TextStyle(
                    fontVariations: [
                      FontVariation('wght', 500), // 秒数比小时/分钟更轻
                      FontVariation('wdth', 50),
                      FontVariation('ROND', 100),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 24,
                ),
                child: M3ESlider(
                  // 受控：值必须来自配置，否则松手后滑块会弹回原处。
                  value: secondSize,
                  min: ClockConfig.minSecondSize,
                  max: ClockConfig.maxSecondSize,
                  label: secondSize.toStringAsFixed(0),
                  // 拖动中只改内存（界面实时跟手），松手才落盘。
                  onChanged: configuration.previewSecondSize,
                  // 传参不可信（可能是上一次构建的旧值），这里忽略它，
                  // 直接把内存中的当前值写入磁盘。
                  onChangeEnd: (_) => configuration.persistSecondSize(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
