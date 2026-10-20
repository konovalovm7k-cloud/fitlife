import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:fitlife/main.dart';
import 'package:fitlife/modern_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Run explicitly with: flutter test test/support/preview_ui.dart
// Demo records exist only in this preview process, never in the installed app.
void main() {
  testWidgets('render mobile previews using bundled production fonts', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 920);
    tester.view.devicePixelRatio = 1;
    debugDisableShadows = false;
    addTearDown(() => debugDisableShadows = true);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final now = DateTime.now();
    final dayKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final entries = [
      DiaryItem(
        id: 'preview-1',
        meal: 'Завтрак',
        food: builtInFoods.firstWhere((food) => food.id == 'oats'),
        grams: 60,
        time: '08:30',
      ),
      DiaryItem(
        id: 'preview-2',
        meal: 'Завтрак',
        food: builtInFoods.firstWhere((food) => food.id == 'yogurt'),
        grams: 150,
        time: '08:30',
      ),
      DiaryItem(
        id: 'preview-3',
        meal: 'Обед',
        food: builtInFoods.firstWhere((food) => food.id == 'chicken'),
        grams: 180,
        time: '13:00',
      ),
      DiaryItem(
        id: 'preview-4',
        meal: 'Обед',
        food: builtInFoods.firstWhere((food) => food.id == 'buckwheat'),
        grams: 70,
        time: '13:00',
      ),
    ];
    SharedPreferences.setMockInitialValues({
      'diary_$dayKey': jsonEncode(entries.map((e) => e.toJson()).toList()),
      'water_$dayKey': 0.75,
      'water_migrated': true,
      'favorites': ['oats', 'yogurt'],
      'recent': ['chicken', 'buckwheat'],
    });
    await tester.runAsync(() async {
      await (FontLoader(
        'Manrope',
      )..addFont(rootBundle.load('assets/fonts/Manrope.ttf'))).load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    });
    final boundary = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(key: boundary, child: const FitLifeRoot()),
    );
    await tester.pumpAndSettle();
    Future<void> capture(String name) async {
      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await render.toImage(pixelRatio: 2);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory('dist').create(recursive: true);
        await File(
          'dist/preview-$name.png',
        ).writeAsBytes(png!.buffer.asUint8List());
        image.dispose();
      });
      expect(tester.takeException(), isNull);
    }

    await capture('today');
    for (final tab in {
      'Питание': 'nutrition',
      'Камера': 'camera',
      'Прогресс': 'progress',
      'Профиль': 'profile',
    }.entries) {
      await tester.tap(find.text(tab.key).last);
      await tester.pumpAndSettle();
      await capture(tab.value);
    }
    await tester.tap(find.text('Сегодня').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Добавить еду'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Яйцо'));
    await tester.pumpAndSettle();
    await capture('add-food');
    debugDisableShadows = true;
  });
}
