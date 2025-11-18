import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ranger/screens/routine_form_screen.dart';

void main() {
  testWidgets('routine form validation requires title', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RoutineFormScreen()));
    // Trigger save via the AppBar save IconButton (avoids ambiguity with body button)
    final appBarSave = find.descendant(
      of: find.byType(AppBar),
      matching: find.byType(IconButton),
    );
    expect(appBarSave, findsOneWidget);
    await tester.tap(appBarSave);
    await tester.pump();
    expect(find.text('Title is required'), findsOneWidget);
  });
}
