import 'package:encrypt/encrypt.dart' as encrypt_pkg;

class EncryptionService {
  // 32-byte secret key and 16-byte initialization vector for AES-256-CBC
  static const String _keyString = 'URLVaultSecretEncryptionKey32Bytes!';
  static const String _ivString = 'URLVaultInitVect!';

  static final _key = encrypt_pkg.Key.fromUtf8(_keyString);
  static final _iv = encrypt_pkg.IV.fromUtf8(_ivString);
  static final _encrypter = encrypt_pkg.Encrypter(encrypt_pkg.AES(_key));

  static String encrypt(String plainText) {
    if (plainText.isEmpty) return '';
    try {
      final encrypted = _encrypter.encrypt(plainText, iv: _iv);
      return encrypted.base64;
    } catch (_) {
      return plainText;
    }
  }

  static String decrypt(String cipherText) {
    if (cipherText.isEmpty) return '';
    try {
      final encrypted = encrypt_pkg.Encrypted.fromBase64(cipherText);
      return _encrypter.decrypt(encrypted, iv: _iv);
    } catch (_) {
      return cipherText;
    }
  }
}
