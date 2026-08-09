import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_manager/widgets/neon_text_field.dart';

void main() {
  testWidgets('NeonTextField renders correctly and handles user input',
      (WidgetTester tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NeonTextField(
            controller: controller,
            label: 'Test URL',
            icon: Icons.link,
          ),
        ),
      ),
    );

    expect(find.text('Test URL'), findsOneWidget);
    expect(find.byIcon(Icons.link), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'https://example.com');
    expect(controller.text, 'https://example.com');
  });
}

