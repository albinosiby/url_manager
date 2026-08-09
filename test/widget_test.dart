import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_manager/models/url_model.dart';
import 'package:url_manager/services/encryption_service.dart';
import 'package:url_manager/services/password_generator_service.dart';
import 'package:url_manager/widgets/neon_text_field.dart';

void main() {
  test('EncryptionService encrypts and decrypts correctly', () {
    const plainText = 'MySecretP@ssw0rd!';
    final cipherText = EncryptionService.encrypt(plainText);
    expect(cipherText, isNot(equals(plainText)));
    expect(cipherText.isNotEmpty, isTrue);

    final decrypted = EncryptionService.decrypt(cipherText);
    expect(decrypted, equals(plainText));
  });

  test('PasswordGeneratorService generates secure password and evaluates strength', () {
    final password = PasswordGeneratorService.generatePassword(length: 16);
    expect(password.length, equals(16));

    final strength = PasswordGeneratorService.calculateStrength(password);
    expect(strength.score, greaterThan(0.5));
    expect(strength.label, equals('Ultra-Secure'));
  });

  test('UrlModel serialization with credentials, category and isFavorite works', () {
    final now = DateTime.now();
    final model = UrlModel(
      id: 'doc123',
      name: 'GitHub',
      url: 'https://github.com',
      description: 'Code repository',
      createdAt: now,
      isFavorite: true,
      category: 'Dev',
      username: 'user@example.com',
      password: 'EncryptedPasswordString',
    );

    final map = model.toMap();
    expect(map['name'], 'GitHub');
    expect(map['isFavorite'], true);
    expect(map['category'], 'Dev');
    expect(map['username'], 'user@example.com');
    expect(model.hasCredentials, isTrue);

    final copy = model.copyWith(isFavorite: false, category: 'Work');
    expect(copy.isFavorite, false);
    expect(copy.category, 'Work');
    expect(copy.username, 'user@example.com');
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
