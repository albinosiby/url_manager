import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isBiometricAvailable() async {
    try {
      final canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canAuthenticateWithBiometrics && isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate({String reason = 'Authenticate to access URL Vault'}) async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) return true;

      return await _auth.authenticate(
        localizedReason: reason,
      );
    } on PlatformException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }
}
