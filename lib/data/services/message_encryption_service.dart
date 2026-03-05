import 'package:encrypt/encrypt.dart' as encrypt;

class MessageEncryptionService {
  MessageEncryptionService({String? encryptionKey}) {
    _key = encrypt.Key.fromUtf8(
      _normalizeKey(encryptionKey ?? _defaultEncryptionKey),
    );
    _encrypter = encrypt.Encrypter(
      encrypt.AES(_key, mode: encrypt.AESMode.cbc),
    );
  }

  static const _defaultEncryptionKey =
      'chatapp-secure-message-key-32-bytes';
  static const _payloadPrefix = 'enc:v1';
  static const _payloadSeparator = ':';

  late final encrypt.Key _key;
  late final encrypt.Encrypter _encrypter;

  String encryptText(String plainText) {
    if (plainText.isEmpty) {
      return plainText;
    }

    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypted = _encrypter.encrypt(plainText, iv: iv);
    return [
      _payloadPrefix,
      iv.base64,
      encrypted.base64,
    ].join(_payloadSeparator);
  }

  bool isEncryptedPayload(String value) {
    return value.startsWith('$_payloadPrefix$_payloadSeparator');
  }

  String decryptText(String cipherText) {
    if (cipherText.isEmpty) {
      return cipherText;
    }

    final chunks = cipherText.split(_payloadSeparator);
    if (chunks.length != 4 ||
        '${chunks[0]}$_payloadSeparator${chunks[1]}' != _payloadPrefix) {
      return cipherText;
    }

    try {
      final iv = encrypt.IV.fromBase64(chunks[2]);
      final encrypted = encrypt.Encrypted.fromBase64(chunks[3]);
      return _encrypter.decrypt(encrypted, iv: iv);
    } catch (_) {
      // Backward compatibility for old plain text or malformed payloads.
      return cipherText;
    }
  }

  static String _normalizeKey(String key) {
    if (key.length == 32) {
      return key;
    }

    if (key.length > 32) {
      return key.substring(0, 32);
    }

    return key.padRight(32, '0');
  }
}
