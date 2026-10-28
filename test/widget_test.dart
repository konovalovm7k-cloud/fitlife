import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitlife/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('FitLife launches and navigation responds to taps', (
    tester,
  ) async {
    await tester.pumpWidget(const FitLifeRoot());
    await tester.pumpAndSettle();

    expect(find.text('Сегодня'), findsWidgets);
    await tester.scrollUntilVisible(find.text('Твой помощник'), 200);
    expect(find.text('Твой помощник'), findsOneWidget);

    await tester.tap(find.text('Питание').last);
    await tester.pumpAndSettle();
    expect(find.text('Поиск, избранное и последние продукты'), findsOneWidget);

    await tester.tap(find.text('Камера').last);
    await tester.pumpAndSettle();
    expect(find.text('Фото блюда → подтверждение'), findsOneWidget);

    await tester.tap(find.text('Прогресс').last);
    await tester.pumpAndSettle();
    expect(find.text('Прогресс'), findsWidgets);

    await tester.tap(find.text('Профиль').last);
    await tester.pumpAndSettle();
    expect(find.text('Профиль'), findsWidgets);
  });

  testWidgets('Nutrition database button opens catalog', (tester) async {
    await tester.pumpWidget(const FitLifeRoot());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('База продуктов'));
    await tester.pumpAndSettle();

    expect(find.text('База продуктов'), findsOneWidget);
    expect(find.text('Поиск продуктов'), findsOneWidget);
    expect(find.text('Жир говяжий, сырой'), findsOneWidget);
  });
}
