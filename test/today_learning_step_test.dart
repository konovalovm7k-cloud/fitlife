import 'package:fitlife/data/repositories/diary_repository.dart';
import 'package:fitlife/features/learning/learning_pages.dart';
import 'package:fitlife/features/learning/nutrition_lessons.dart';
import 'package:fitlife/features/learning/today_learning_step.dart';
import 'package:fitlife/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'diary_flow_test.dart' show launch;
import 'parallel_storage_test.dart' show ControlledDisk;
import 'support/source_flow.dart' show reveal;

class TwiceFailingLearning extends LearningRepository {
  TwiceFailingLearning(super.diary);
  int attempts = 0;
  @override
  Future<LearningProgress> load() {
    if (++attempts <= 2) throw StateError('temporary synchronous read failure');
    return super.load();
  }
}

void main() {
  late ControlledDisk disk;
  late LearningRepository repository;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    disk = ControlledDisk();
    SharedPreferencesStorePlatform.instance = disk;
    repository = LearningRepository(DiaryRepository.withLoader());
  });

  testWidgets(
    'next task refreshes after marking, cold launch and profile undo',
    (tester) async {
      await repository.mark('portions_v1', true);
      await launch(tester, size: const Size(360, 780));
      final before = {...await disk.getAll()}
        ..remove('flutter.$lessonProgressKey');
      await reveal(tester, find.byKey(const Key('today-open-task')));
      expect(find.text('Зачем нужны нутриенты'), findsOneWidget);
      await tester.tap(find.byKey(const Key('today-open-task')));
      await tester.pumpAndSettle();
      expect(find.byType(LessonPage), findsOneWidget);
      await reveal(tester, find.byKey(const Key('lesson-mark')));
      disk.failKey = 'flutter.$lessonProgressKey';
      await tester.tap(find.byKey(const Key('lesson-mark')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Не удалось сохранить отметку'),
        findsOneWidget,
      );
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const Key('today-learning-topic')));
      expect(find.text('Зачем нужны нутриенты'), findsOneWidget);
      expect((await repository.load()).count, 1);
      disk.failKey = null;
      await reveal(tester, find.byKey(const Key('today-open-task')));
      await tester.tap(find.byKey(const Key('today-open-task')));
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const Key('lesson-mark')));
      await tester.tap(find.byKey(const Key('lesson-mark')));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const Key('today-learning-topic')));
      expect(find.text('Что известно о составе'), findsOneWidget);
      expect((await repository.load()).count, 2);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(const FitLifeRoot());
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const Key('today-learning-topic')));
      expect(find.text('Что известно о составе'), findsOneWidget);
      await tester.tap(find.text('Профиль').last);
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Короткие уроки'));
      await tester.tap(find.text('Короткие уроки'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('nutrients_v1')));
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const Key('lesson-mark')));
      await tester.tap(find.byKey(const Key('lesson-mark')));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Сегодня').last);
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const Key('today-learning-topic')));
      expect(find.text('Зачем нужны нутриенты'), findsOneWidget);
      expect((await repository.load()).count, 1);
      final after = {...await disk.getAll()}
        ..remove('flutter.$lessonProgressKey');
      expect(after, before);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'direct task opens real diary without inserting or marking food',
    (tester) async {
      await launch(tester, size: const Size(360, 780));
      final before = {...await disk.getAll()};
      await reveal(tester, find.byKey(const Key('today-open-task')));
      await tester.tap(find.byKey(const Key('today-open-task')));
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const Key('lesson-open-diary')));
      await tester.tap(find.byKey(const Key('lesson-open-diary')));
      await tester.pumpAndSettle();
      expect(find.byType(LessonPage), findsNothing);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        1,
      );
      expect({...await disk.getAll()}, before);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'completed topics remain optional and preserve later-version IDs',
    (tester) async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setStringList(lessonProgressKey, [
        ...nutritionLessons.map((lesson) => lesson.id),
        'future_topic_v2',
      ]);
      await launch(tester);
      final before = {...await disk.getAll()};
      await reveal(tester, find.text('Открыть короткие уроки'));
      expect(
        find.textContaining('Все темы отмечены как понятные.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('today-open-task')), findsNothing);
      await tester.tap(find.text('Открыть короткие уроки'));
      await tester.pumpAndSettle();
      expect(find.byType(LearningPage), findsOneWidget);
      expect(find.text('Понятно: 3 из 3'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect({...await disk.getAll()}, before);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'step read fails twice then recovers without marks on large text',
    (tester) async {
      await repository.mark('portions_v1', true);
      final before = {...await disk.getAll()};
      final failing = TwiceFailingLearning(DiaryRepository.withLoader());
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.8)),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: TodayLearningStep(repository: failing, onOpenDiary: () {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (var attempt = 0; attempt < 2; attempt++) {
        expect(find.textContaining('Дневник доступен.'), findsOneWidget);
        await reveal(tester, find.text('Повторить загрузку шага'));
        await tester.tap(find.text('Повторить загрузку шага'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      expect(failing.attempts, 3);
      await reveal(tester, find.byKey(const Key('today-open-task')));
      expect(find.text('Зачем нужны нутриенты'), findsOneWidget);
      expect({...await disk.getAll()}, before);
      expect(tester.takeException(), isNull);
    },
  );
}
