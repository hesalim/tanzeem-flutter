import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthSession {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static String? token;

  static int? userId;
  static int? businessId;
  static int? staffId;

  static String? firstName;
  static String? lastName;
  static String? email;
  static String? role;

  static bool get isLoggedIn => token != null;

  static Future<void> saveSession({
    required String newToken,
    int? newUserId,
    int? newBusinessId,
    int? newStaffId,
    String? newFirstName,
    String? newLastName,
    String? newEmail,
    String? newRole,
  }) async {
    token = newToken;

    userId = newUserId;
    businessId = newBusinessId;
    staffId = newStaffId;

    firstName = newFirstName;
    lastName = newLastName;
    email = newEmail;
    role = newRole;

    await _storage.write(key: 'token', value: newToken);

    await _storage.write(key: 'userId', value: newUserId?.toString());

    await _storage.write(key: 'businessId', value: newBusinessId?.toString());

    await _storage.write(key: 'staffId', value: newStaffId?.toString());

    await _storage.write(key: 'firstName', value: newFirstName);

    await _storage.write(key: 'lastName', value: newLastName);

    await _storage.write(key: 'email', value: newEmail);

    await _storage.write(key: 'role', value: newRole);
  }

  static Future<bool> restoreSession() async {
    token = await _storage.read(key: 'token');

    if (token == null) {
      return false;
    }

    final storedUserId = await _storage.read(key: 'userId');

    final storedBusinessId = await _storage.read(key: 'businessId');

    final storedStaffId = await _storage.read(key: 'staffId');

    userId = storedUserId == null ? null : int.tryParse(storedUserId);

    businessId = storedBusinessId == null
        ? null
        : int.tryParse(storedBusinessId);

    staffId = storedStaffId == null ? null : int.tryParse(storedStaffId);

    firstName = await _storage.read(key: 'firstName');

    lastName = await _storage.read(key: 'lastName');

    email = await _storage.read(key: 'email');

    role = await _storage.read(key: 'role');

    return true;
  }

  static Future<void> clear() async {
    token = null;

    userId = null;
    businessId = null;
    staffId = null;

    firstName = null;
    lastName = null;
    email = null;
    role = null;

    await _storage.deleteAll();
  }
}
