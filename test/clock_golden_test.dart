import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mexy_laziness/features/today/presentation/widgets/seconds_clock.dart';

/// 加载真实的可变字体——测试环境默认用占位字体，不加载的话字形没有意义。
Future<void> _loadFont(String family, String path) async {
  final bytes = File(path).readAsBytesSync();
  final loader = FontLoader(family)
    ..addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
  await loader.load();
}

void main() {
  testWidgets('Clock 渲染快照', (tester) async {
    await _loadFont('Google Sans Flex', 'fonts/GoogleSansFlex.ttf');

    tester.view.physicalSize = const Size(900, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: 'Google Sans Flex'),
        home: Scaffold(
          // 注入固定时间，否则每次跑图都是「当前时间」，快照永远对不上。
          // secondStyle 与 today_page 的实际用法保持一致，覆盖真实渲染路径。
          body: Center(
            child: Clock(
              now: () => DateTime(2026, 11, 7, 20, 11, 16),
              secondStyle: const TextStyle(
                fontVariations: [
                  FontVariation('wght', 500),
                  FontVariation('wdth', 50),
                  FontVariation('ROND', 100),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    // 不要用 pumpAndSettle：时钟每秒都会 setState，永远 settle 不下来。
    await tester.pump();

    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/clock.png'),
    );
  });
}
