import 'package:fitlife/data/repositories/diary_repository.dart';
import 'package:fitlife/features/learning/learning_pages.dart';
import 'package:fitlife/features/learning/nutrition_lessons.dart';
import 'package:fitlife/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'diary_flow_test.dart' show launch;
import 'parallel_storage_test.dart' show ControlledDisk;
import 'support/source_flow.dart' show reveal;

void main() {
  late ControlledDisk disk;
  late LearningRepository repo;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    disk = ControlledDisk();
    SharedPreferencesStorePlatform.instance = disk;
    repo = LearningRepository(DiaryRepository.withLoader());
  });
  testWidgets(
    'lesson task opens the real diary without inserting teaching food',
    (tester) async {
      await launch(tester, size: const Size(360, 780));
      final before = {...await disk.getAll()};
      await reveal(tester, find.text('Открыть короткие уроки'));
      await tester.tap(find.text('Открыть короткие уроки'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('sources_v1')));
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const Key('lesson-open-diary')));
      await tester.tap(find.byKey(const Key('lesson-open-diary')));
      await tester.pumpAndSettle();
      expect(find.byType(LearningPage), findsNothing);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        1,
      );
      expect({...await disk.getAll()}, before);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Today lesson, interactive portion and progress survive restart through profile',
    (tester) async {
      await launch(tester, size: const Size(360, 780));
      final before = {...await disk.getAll()};
      await reveal(tester, find.text('Открыть короткие уроки'));
      await tester.tap(find.text('Открыть короткие уроки'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('portions_v1')));
      await tester.pumpAndSettle();
      await reveal(tester, find.text('2 порции'));
      await tester.tap(find.text('2 порции'));
      await tester.pumpAndSettle();
      expect(find.text('454 г · 560 ккал'), findsOneWidget);
      await reveal(tester, find.byKey(const Key('lesson-mark')));
      await tester.tap(find.byKey(const Key('lesson-mark')));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Понятно: 1 из 3'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(const FitLifeRoot());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Профиль').last);
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Короткие уроки'));
      await tester.tap(find.text('Короткие уроки'));
      await tester.pumpAndSettle();
      expect(find.text('Понятно: 1 из 3'), findsOneWidget);
      final after = {...await disk.getAll()};
      after.remove('flutter.$lessonProgressKey');
      expect(after, before);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'failed mark keeps the selected portion and retry/undo are persisted',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LessonPage(lesson: nutritionLessons.first, repository: repo),
        ),
      );
      await reveal(tester, find.text('2 порции'));
      await tester.tap(find.text('2 порции'));
      await tester.pumpAndSettle();
      disk.failKey = 'flutter.$lessonProgressKey';
      await reveal(tester, find.byKey(const Key('lesson-mark')));
      await tester.tap(find.byKey(const Key('lesson-mark')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Не удалось сохранить'), findsOneWidget);
      expect((await repo.load()).count, 0);
      await reveal(tester, find.byKey(const Key('teaching-portion')));
      expect(
        tester.widget<Text>(find.byKey(const Key('teaching-portion'))).data,
        '454 г · 560 ккал',
      );
      disk.failKey = null;
      await reveal(tester, find.byKey(const Key('lesson-mark')));
      await tester.tap(find.byKey(const Key('lesson-mark')));
      await tester.pumpAndSettle();
      expect((await repo.load()).count, 1);
      expect(find.text('Отменить отметку'), findsOneWidget);
      await tester.tap(find.byKey(const Key('lesson-mark')));
      await tester.pumpAndSettle();
      expect((await repo.load()).count, 0);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'failed recovery read can retry and reveal preserved lesson progress',
    (tester) async {
      await disk.setValue('String', 'flutter.$lessonProgressKey', 'bad');
      disk.failKey = 'flutter.recovery_$lessonProgressKey';
      await tester.pumpWidget(
        MaterialApp(home: LearningPage(repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Не удалось загрузить отметки уроков.'), findsOneWidget);
      disk.failKey = null;
      await tester.tap(find.text('Повторить'));
      await tester.pumpAndSettle();
      expect(find.text('Понятно: 0 из 3'), findsOneWidget);
      expect(
        (await disk.getAll())['flutter.recovery_$lessonProgressKey'],
        'bad',
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('large text keeps lesson tasks and source URLs accessible', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: LessonPage(lesson: nutritionLessons[1], repository: repo),
      ),
    );
    await reveal(tester, find.byKey(const Key('lesson-mark')));
    expect(find.text('Понятно, отметить'), findsOneWidget);
    final source = find.byWidgetPredicate(
      (w) =>
          w is SelectableText &&
          (w.data ?? '').contains(
            'https://medlineplus.gov/ency/article/002467.htm',
          ),
    );
    await reveal(tester, source);
    expect(source, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
