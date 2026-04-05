// Smoke test: the app boots without throwing.
import 'package:flutter_test/flutter_test.dart';

import 'package:app/main.dart';

void main() {
  testWidgets('App renders without crashing', (tester) async {
    await tester.pumpWidget(const EventCalendarApp());
    // The router shows the placeholder screen at '/'.
    expect(find.text('EventCalendar — Flutter'), findsOneWidget);
  });
}
