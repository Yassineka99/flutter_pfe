import 'dart:typed_data';
import '../model/user.dart';
import '../repository/user_repository.dart';

class UserViewModel {
  final UserRepoitory _clientRepository = UserRepoitory();
  User? _client;
  Future<void> createClient(String name, String email, String phone,
      String password, int role) async {
    try {
      _client = await _clientRepository.createUser(
          name, email, phone, password, role);
      await _clientRepository.syncUser();
      // You can also notifyListeners() if you're using Provider or State Management
    } catch (e) {
      print('Error creating client: $e');
    }
  }

  Future<User?> getClient(String id) async {
    try {
      _client = await _clientRepository.getUser(id);
      if (_client != null) {
        return _client!;
      } else {
        return null;
      }
      // You can also notifyListeners() if you're using Provider or State Management
    } catch (e) {
      print('Error fetching client: $e');
    }
  }

  Future<User?> getClientbyEmail(String email) async {
    print("Fetching client by email: $email");
    try {
      final encodedEmail = Uri.encodeComponent(email);
      print("Encoded email: $encodedEmail");
      _client = await _clientRepository.getUserbyEmail(encodedEmail);
      if (_client != null) {
        return _client!;
      } else {
        print('Client not found.');
        return null;
      }
    } catch (e) {
      print('Error fetching client: $e');
      return null;
    }
  }

  Future<User?> updateUserProfilePicture(
      int userId, String base64Image, String mimeType) async {
    try {
      _client = await _clientRepository.updateUserProfilePicture(
          userId, base64Image, mimeType);
      return _client;
    } catch (e) {
      print('Error updating profile picture: $e');
      return null;
    }
  }

  Future<Uint8List?> getUserImage(int userId) async {
    try {
      return await _clientRepository.getUserImage(userId);
    } catch (e) {
      print('Error fetching user image: $e');
      return null;
    }
  }

  Future<List<User>> getUsersByRoleId(int roleId) async {
    print("Fetching users by role ID: $roleId");
    try {
      _clientRepository.syncUser();
      final users = await _clientRepository.getUsersByRoleId(roleId);
      return users;
    } catch (e) {
      print('Error fetching users by role ID: $e');
      return [];
    }
  }
}
