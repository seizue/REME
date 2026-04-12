import 'package:flutter_test/flutter_test.dart';
import 'package:reme/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    final themeProvider = ThemeProvider(false);
    await tester.pumpWidget(RemeApp(themeProvider: themeProvider));
    expect(find.byType(RemeApp), findsOneWidget);
  });
}
