import 'package:flutter_test/flutter_test.dart';
import 'package:fitlife/app/app.dart';

void main() {
  testWidgets('FitLife launches', (tester) async {
    await tester.pumpWidget(const FitLifeApp());
    expect(find.text('FitLife'), findsOneWidget);
    expect(find.text('Умный дневник похудения'), findsOneWidget);
  });
}
