import 'dart:convert';
import 'dart:html';
import 'package:http/http.dart' as http;
import '../env.dart';
import '../model/role.dart';
class RoleRepository {
  static const apiUrl = '$baseUrl/api/role';
    Future<Role> getNotificationByUserId(String id) async {
    final response = await http.get(
      Uri.parse('$apiUrl/byid/$id'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    if (response.statusCode == 200) {
      return Role.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load client.');
    }
  }
}