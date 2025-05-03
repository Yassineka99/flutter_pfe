import 'package:flutter/foundation.dart';
import '../model/user.dart';
import '../services/db_helper.dart';

class UserSession extends ChangeNotifier {
  User? _user;
  final DBHelper _db = DBHelper();

  User? get user => _user;
  bool get isLoggedIn => _user != null;

  /// Call this at startup:
  Future<void> loadFromDb() async {
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

  /// On logout:
  Future<void> logOut() async {
    _user = null;
    await _db.deleteUser();
    notifyListeners();
  }
}
