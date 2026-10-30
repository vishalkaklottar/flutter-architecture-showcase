import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_architecture_showcase/app/app.dart';

void main() {
  testWidgets('App displays the application title', (tester) async {
    await tester.pumpWidget(const App());

    expect(find.text('Flutter Architecture Showcase'), findsOneWidget);
  });
}
