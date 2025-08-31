import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:calculator/main.dart'; // Make sure this path is correct

void main() {
  testWidgets('Calculator widget test', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const GlassCalculatorApp());

    // Step 1: Initial display shows '0'
    final displayFinder = find.byKey(const Key('calculator_display'));
    expect(displayFinder, findsOneWidget);
    Text displayText = tester.widget(displayFinder);
    expect(displayText.data, '0');

    // Step 2: Tap 1
    await tester.tap(find.text('1'));
    await tester.pump();
    displayText = tester.widget(displayFinder);
    expect(displayText.data, '1');

    // Step 3: Tap + button
    await tester.tap(find.text('+'));
    await tester.pump();
    displayText = tester.widget(displayFinder);
    expect(displayText.data, '1+');

    // Step 4: Tap 2
    await tester.tap(find.text('2'));
    await tester.pump();
    displayText = tester.widget(displayFinder);
    expect(displayText.data, '1+2');

    // Step 5: Tap = button
    await tester.tap(find.text('='));
    await tester.pump();
    displayText = tester.widget(displayFinder);
    expect(displayText.data, '3'); // 1 + 2 = 3

    // Step 6: Test DEL button
    await tester.tap(find.text('DEL'));
    await tester.pump();
    displayText = tester.widget(displayFinder);
    expect(displayText.data, '0'); // All deleted, resets to 0

    // Step 7: Test C button
    await tester.tap(find.text('1'));
    await tester.tap(find.text('+'));
    await tester.tap(find.text('2'));
    await tester.tap(find.text('C'));
    await tester.pump();
    displayText = tester.widget(displayFinder);
    expect(displayText.data, '0'); // Reset
  });
}
