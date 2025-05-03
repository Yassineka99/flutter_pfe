import 'dart:convert';
import 'dart:html';
import 'package:http/http.dart' as http;
import '../env.dart';
import '../model/role.dart';
import '../model/status.dart';
class StatusRepository {
  static const apiUrl = '$baseUrl/api/status';
    Future<Status> getStatusByUserId(String id) async {
    final response = await http.get(
      Uri.parse('$apiUrl/byid/$id'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    if (response.statusCode == 200) {
      return Status.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load client.');
    }
  }
}