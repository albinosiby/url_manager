import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_manager/models/url_model.dart';
import 'package:url_manager/widgets/neon_text_field.dart';

void main() {
  test('UrlModel serialization with category and isFavorite works', () {
    final now = DateTime.now();
    final model = UrlModel(
      id: 'doc123',
      name: 'GitHub',
      url: 'https://github.com',
      description: 'Code repository',
      createdAt: now,
      isFavorite: true,
      category: 'Dev',
    );

    final map = model.toMap();
    expect(map['name'], 'GitHub');
    expect(map['isFavorite'], true);
    expect(map['category'], 'Dev');

    final copy = model.copyWith(isFavorite: false, category: 'Work');
    expect(copy.isFavorite, false);
    expect(copy.category, 'Work');
    expect(copy.name, 'GitHub');
  });

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
