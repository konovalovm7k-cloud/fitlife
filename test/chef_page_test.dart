import 'dart:async';
import 'dart:convert';
import 'package:fitlife/features/chef/chef_catalogue.dart';
import 'package:fitlife/features/chef/chef_page.dart';
import 'package:fitlife/features/meal_ideas/meal_ideas_page.dart';
import 'package:fitlife/features/photo_analysis/photo_diary.dart';
import 'package:fitlife/features/photo_analysis/photo_models.dart';
import 'package:fitlife/features/photo_analysis/photo_service.dart';
import 'package:fitlife/features/photo_analysis/photo_settings_page.dart';
import 'package:fitlife/data/repositories/local_fitlife_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'photo_page_test.dart' show MemoryPhotoConnection;
import 'diary_repository_test.dart' show DiaryDisk;
import 'diary_flow_test.dart' show launch;
import 'support/chef_fixture.dart';
import 'support/source_flow.dart' show reveal;

class PendingChefService extends PhotoService {
  final pending = Completer<PhotoAnalysis>();
  int closes = 0;
  @override
  Future<PhotoAnalysis> suggestMeal(
    PhotoConnection connection,
    String text,
    ChefCatalogue catalogue,
  ) => pending.future;
  @override
  void close() {
    closes++;
    super.close();
  }
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final catalogue = chefFixture();
  final connection = PhotoConnection('https://chef.example.com', 'a' * 43);
  final day = DateTime(2026, 10, 28);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    for (final path in [
      'assets/data/food_catalog.json',
      'shared/chef_catalogue.json',
    ]) {
      rootBundle.evict(path);
    }
    binding.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', (
      message,
    ) async {
      final path = utf8.decode(
        message!.buffer.asUint8List(
          message.offsetInBytes,
          message.lengthInBytes,
        ),
      );
      final text = {
        'assets/data/food_catalog.json': chefFoodsAsset,
        'shared/chef_catalogue.json': chefAsset,
      }[path];
      return text == null
          ? null
          : ByteData.sublistView(Uint8List.fromList(utf8.encode(text)));
    });
  });

  Widget page({
    required Future<void> Function(PhotoMeal) save,
    PhotoService Function()? factory,
    PhotoConnectionStore? store,
    Future<ChefCatalogue> Function()? loader,
  }) => MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => ChefPage(
                day: day,
                meal: 'Обед',
                onSave: save,
                store: store ?? MemoryPhotoConnection(connection),
                createService: factory,
                loadCatalogue: loader ?? () async => catalogue,
              ),
            ),
          ),
          child: const Text('Open Chef'),
        ),
      ),
    ),
  );

  Future<void> start(WidgetTester tester) async {
    await tester.tap(find.text('Open Chef'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('chef-pantry')),
      'Яблоко и йогурт',
    );
    await reveal(tester, find.byKey(const Key('chef-suggest')));
    await tester.tap(find.byKey(const Key('chef-suggest')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> consent(WidgetTester tester) async {
    await tester.tap(find.text('Отправить'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets(
    'consent refusal makes no service/network request and retains pantry',
    (tester) async {
      var created = 0;
      await tester.pumpWidget(
        page(
          loader: loadChefCatalogue,
          save: (_) async {},
          factory: () {
            created++;
            return PhotoService();
          },
        ),
      );
      await start(tester);
      expect(find.textContaining('chef.example.com'), findsOneWidget);
      expect(find.textContaining('В бесплатном режиме Google'), findsOneWidget);
      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();
      expect(created, 0);
      expect(find.text('Яблоко и йогурт'), findsOneWidget);
    },
  );

  testWidgets(
    'accepted request still needs save; failed write and route rebuild retain batch and source',
    (tester) async {
      final disk = DiaryDisk();
      SharedPreferencesStorePlatform.instance = disk;
      var requests = 0;
      final ids = <String>[];
      Future<void> save(PhotoMeal meal) async {
        ids.add(meal.id);
        await savePhotoMeal(meal);
      }

      PhotoService service() => PhotoService(
        client: MockClient((request) async {
          requests++;
          return http.Response(
            jsonEncode(
              chefReply(
                request.headers['X-Request-Id']!,
                items: [
                  {'recordId': chefApple, 'grams': 150.5},
                  {'recordId': chefYogurt, 'grams': 100},
                ],
              ),
            ),
            200,
          );
        }),
      );
      await tester.pumpWidget(page(save: save, factory: service));
      await start(tester);
      await consent(tester);
      await tester.pumpAndSettle();
      expect(requests, 1);
      expect(ids, isEmpty);
      expect(find.text('ИДЕЯ AI · ИСТОЧНИКИ СОСТАВА'), findsOneWidget);
      expect(find.text('134 ккал'), findsOneWidget);
      expect(find.text('Клетчатка: состав неполный'), findsOneWidget);
      disk.fail = true;
      final button = find.byKey(const Key('photo-save'));
      await reveal(tester, button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.textContaining('Ваши правки остались'), findsOneWidget);
      await tester.pumpWidget(page(save: save, factory: service));
      await tester.pumpAndSettle();
      disk.fail = false;
      await reveal(tester, button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(ids.toSet(), hasLength(1));
      expect(requests, 1);
      final saved = await LocalFitLifeRepository().loadDay(day, today: day);
      expect(saved.diary, hasLength(2));
      expect(saved.diary.every((e) => e.food.isChefSuggestion), isTrue);
      expect(saved.diary.first.food.provenance!.recordId, chefApple);
      expect(saved.diary.last.food.hasKnownFiber, isFalse);
    },
  );

  testWidgets(
    'cancel closes request; late completion cannot open review or overwrite retry',
    (tester) async {
      final first = PendingChefService();
      final second = PendingChefService();
      var created = 0;
      await tester.pumpWidget(
        page(
          save: (_) async {},
          factory: () => created++ == 0 ? first : second,
        ),
      );
      await start(tester);
      await consent(tester);
      await revealWithoutSettle(tester, find.text('Отменить ожидание'));
      await tester.tap(find.text('Отменить ожидание'));
      await tester.pumpAndSettle();
      expect(first.closes, greaterThan(0));
      await tester.tap(find.byKey(const Key('chef-suggest')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await consent(tester);
      first.pending.complete(catalogue.resolve(chefReply('a' * 32), 'a' * 32));
      await tester.pump();
      expect(find.text('ИДЕЯ AI · ИСТОЧНИКИ СОСТАВА'), findsNothing);
      second.pending.complete(catalogue.resolve(chefReply('b' * 32), 'b' * 32));
      await tester.pumpAndSettle();
      expect(find.text('ИДЕЯ AI · ИСТОЧНИКИ СОСТАВА'), findsOneWidget);
      expect(created, 2);
    },
  );

  testWidgets(
    'missing connection exposes shared settings and retains pantry without request',
    (tester) async {
      var created = 0;
      await tester.pumpWidget(
        page(
          save: (_) async {},
          store: MemoryPhotoConnection(null),
          factory: () {
            created++;
            return PhotoService();
          },
        ),
      );
      await start(tester);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Подключение AI не настроено'),
        findsOneWidget,
      );
      expect(created, 0);
      final settings = find.widgetWithText(TextButton, 'Подключение AI');
      await reveal(tester, settings);
      await tester.tap(settings);
      await tester.pumpAndSettle();
      expect(find.byType(PhotoSettingsPage), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Яблоко и йогурт'), findsOneWidget);
    },
  );

  testWidgets(
    'empty match and local catalogue failure preserve input and never save',
    (tester) async {
      var writes = 0;
      await tester.pumpWidget(
        page(
          save: (_) async {
            writes++;
          },
          factory: () => PhotoService(
            client: MockClient(
              (request) async => http.Response(
                jsonEncode(
                  chefReply(
                    request.headers['X-Request-Id']!,
                    items: [],
                    warnings: ['no_match'],
                  ),
                ),
                200,
              ),
            ),
          ),
        ),
      );
      await start(tester);
      await consent(tester);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Не нашлось подходящего сочетания'),
        findsOneWidget,
      );
      expect(find.text('Яблоко и йогурт'), findsOneWidget);
      expect(writes, 0);
      await tester.pumpWidget(const SizedBox.shrink());
      var created = 0;
      await tester.pumpWidget(
        page(
          save: (_) async {
            writes++;
          },
          factory: () {
            created++;
            return PhotoService();
          },
          loader: () => Future.error(StateError('catalogue')),
        ),
      );
      await start(tester);
      await tester.pumpAndSettle();
      expect(find.textContaining('Список остался в форме'), findsOneWidget);
      expect(created, 0);
      expect(writes, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'local ideas open Chef and return without automatic AI or diary write',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MealIdeasPage(
            day: day,
            initialMeal: 'Обед',
            onSave: (_) async {},
            loadFoods: () async => chefRecords,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('AI Chef: подобрать из моих продуктов'));
      await tester.pumpAndSettle();
      expect(find.byType(ChefPage), findsOneWidget);
      expect(find.text('Что есть под рукой?'), findsOneWidget);
      await reveal(tester, find.text('Вернуться к локальным идеям'));
      await tester.tap(find.text('Вернуться к локальным идеям'));
      await tester.pumpAndSettle();
      expect(find.text('Простые варианты без запроса AI'), findsOneWidget);
    },
  );

  testWidgets(
    'source correction retains Chef origin, entry ID and chosen mass',
    (tester) async {
      final today = DateTime.now();
      final id = 'e' * 32;
      final analysis = catalogue.resolve(chefReply(id), id);
      await savePhotoMeal(
        PhotoMeal(
          id: id,
          day: today,
          meal: 'Обед',
          items: analysis.items,
          source: analysis.source,
        ),
      );
      await launch(tester);
      await tester.tap(find.text('Питание').last);
      await tester.pumpAndSettle();
      final edit = find.byTooltip(
        'Источник состава: Яблоко с кожурой, сырое (CoFID)',
      );
      await reveal(tester, edit);
      await tester.tap(edit);
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('source-grams')), '175.5');
      await reveal(tester, find.byKey(const Key('source-confirm')));
      await tester.tap(find.byKey(const Key('source-confirm')));
      await tester.pumpAndSettle();
      final saved = await LocalFitLifeRepository().loadDay(today, today: today);
      expect(saved.diary.single.id, 'chef_${id}_0');
      expect(saved.diary.single.grams, 175.5);
      expect(saved.diary.single.food.isChefSuggestion, isTrue);
    },
  );
}

Future<void> revealWithoutSettle(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 300));
}
