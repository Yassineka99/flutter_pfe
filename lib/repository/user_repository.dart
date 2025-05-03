import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../env.dart';
import '../model/user.dart';

class UserRepoitory {
  static const String apiUrl1 = '$baseUrl/api/user';
  Future<User> createUser(
    String? name,
    String? email,
    String? phone,
    String? password,
    int? role
  ) async {
    final response = await http.post(
      Uri.parse('$apiUrl1/create'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'name': name!,
        'email': email!,
        'phone': phone!,
        'password': password!,
        'role': role!.toString(),
      }),
    );
    if (response.statusCode == 201) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create client.');
    }
  }

  Future<User> getUser(String id) async {
    final response = await http.get(
      Uri.parse('$apiUrl1/getUserById/$id'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load client.');
    }
  }

  Future<User> getUserbyEmail(String email) async {
    final response = await http.get(
      Uri.parse(('$apiUrl1/getUserByEmail/$email')),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
      print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load client.');
    }
  }

  Future<List<User>> getByStatusId(int userId) async {
  final response = await http.get(Uri.parse('$apiUrl1/get-all-by-status-id/$userId'));
  if (response.statusCode == 200) {
    List<dynamic> data = jsonDecode(response.body);
    return data.map((item) => User.fromJson(item)).toList();
  } else {
    throw Exception('Failed to load by user ID');
  }
}

Future<User> updateUserProfilePicture(int userId, String newBase64Image, String mimeType) async {
  final response = await http.post(
    Uri.parse('$apiUrl1/update/picture'),
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: jsonEncode({
      'id':        userId,
      'image':     newBase64Image,   // match DTO
      'imageType': mimeType,         // match DTO
    }),
  );
  if (response.statusCode == 200) {
    return User.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to update profile picture.');
  }
}

Future<Uint8List?> getUserImage(int userId) async {
  final response = await http.get(
    Uri.parse('$apiUrl1/get/$userId/image'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
  );
  if (response.statusCode == 200) {
    return response.bodyBytes; // Return raw image bytes
  } else {
    print('Failed to fetch image. Status: ${response.statusCode}');
    return null;
  }
}
Future<List<User>> getUsersByRoleId(int id) async {
  final response = await http.get(
    Uri.parse('$apiUrl1/get-all-by-role-id/$id'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
  );

  print('Response status: ${response.statusCode}');
  print('Response body: ${response.body}');

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => User.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load users by role id.');
  }
}

}
