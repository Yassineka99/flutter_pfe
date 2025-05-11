import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/user.dart';
import '../services/db_helper.dart';

class UserSession extends ChangeNotifier {
  User? _user;
  final DBHelper _db = DBHelper();
  bool _useFingerprint = false;

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get useFingerprint => _useFingerprint;

  /// Call this at startup:
  Future<void> loadFromDb() async {
    final prefs = await SharedPreferences.getInstance();
    _useFingerprint = prefs.getBool('useFingerprint') ?? false;
    final saved = await _db.getUser();
    if (saved != null) {
      _user = saved;
      notifyListeners();
    }
  }

  /// After a successful login:
  Future<void> logIn(User user) async {
    _user = user;
    await _db.saveUser(user);
    notifyListeners();
  }

  Future<void> toggleFingerprint(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useFingerprint', value);
    _useFingerprint = value;
    notifyListeners(); // This updates the UI
  }
  /// On logout:
  Future<void> logOut() async {
    _user = null;
    await _db.deleteUser();
    notifyListeners();
  }
}
