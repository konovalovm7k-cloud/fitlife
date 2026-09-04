import 'package:flutter_test/flutter_test.dart';
import 'package:fitlife/app/app.dart';

void main() {
  testWidgets('FitLife launches with diary dashboard', (tester) async {
    await tester.pumpWidget(const FitLifeApp());
    await tester.pumpAndSettle();
    expect(find.text('Сегодня'), findsWidgets);
    expect(find.text('Калории'), findsOneWidget);
    expect(find.text('Ежедневный чек-ин'), findsOneWidget);
  });
}
