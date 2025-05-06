import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../env.dart';
import '../model/user.dart';
import '../services/db_helper.dart';

class UserRepoitory {
  static const String apiUrl1 = '$baseUrl/api/user';
  final DBHelper _dbHelper = DBHelper();
  Future<User> createUser(String? name, String? email, String? phone,
      String? password, int? role) async {
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
    print("email length :${email.length}");
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


  Future<User> updateUserProfilePicture(
      int userId, String newBase64Image, String mimeType) async {
    final response = await http.post(
      Uri.parse('$apiUrl1/update/picture'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'id': userId,
        'image': newBase64Image, // match DTO
        'imageType': mimeType, // match DTO
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
    try {
      final response = await http.get(
        Uri.parse('$apiUrl1/get-all-by-role-id/$id'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      ).timeout(Duration(seconds: 3));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final db = await _dbHelper.database;
        await db!.transaction((txn) async {
          for (var wf in data) {
           final existing = await txn.rawQuery(
              'SELECT connected FROM user WHERE id = ?',
              [wf['id']],
            );
            final connected = existing.isNotEmpty && existing.first['connected'] == 1 ? 1 : 0;

            await txn.rawInsert('''
              INSERT OR REPLACE INTO user
              (id,name,email,phone,password,role,image,imageType,is_synced,connected)
              VALUES(?,?,?,?,?,?,?,?,1,?)
            ''', [
              wf['id'],
              wf['name'],
              wf['email'],
              wf['phone'],
              wf['password'],
              wf['role'],
              wf['image'],
              wf['imageType'],
              connected,
            ]);

          }
        });
        return data.map((json) => User.fromJson(json)).toList();
      }
    } catch (e) {}
        final List<Map<String, dynamic>> raw = await _dbHelper
        .readData("SELECT * FROM user WHERE role=$id");
    return raw.map<User>((row) => User.fromJson(row)).toList();
  }

Future<bool> _isConnected() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<void> syncUser() async {
  if (!await _isConnected()) return;

  final currentUser = await _dbHelper.getUser();

  final unsynced = await _dbHelper.readData('''
    SELECT * FROM user
    WHERE is_synced = 0
    AND (created_locally != 1 OR id != ${currentUser?.id ?? -1})
  ''');

  for (var wf in unsynced) {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl1/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': wf['name'],
          'email': wf['email'],
          'phone': wf['phone'],
          'password': wf['password'],
          'role': wf['role'],
          'image': wf['image'],
          'imageType': wf['imageType'],
        }),
      );

      if (response.statusCode == 201) {
        final serverWf = User.fromJson(jsonDecode(response.body));
        await _dbHelper.updateData('''
          UPDATE user SET id = ${serverWf.id}, is_synced = 1, created_locally = 0
          WHERE id = ${wf['id']}
        ''');
      }
    } catch (e) {
      print('Sync error: $e');
    }
  }
}


}
