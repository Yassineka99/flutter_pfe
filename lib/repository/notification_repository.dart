import 'dart:convert';
import 'dart:html';
import 'package:http/http.dart' as http;
import '../env.dart';
import '../model/notification.dart';
class NotificationRepository {
  static const apiUrl = '$baseUrl/api/notifications';
  Future<Notification> createNotification(
    String? message,
    int? userToNotify
  ) async {
    final response = await http.post(
      Uri.parse('$apiUrl/create'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'message': message!,
        'user_to_notify': userToNotify!.toString(),
      }),
    );
    if (response.statusCode == 201) {
      return Notification.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create client.');
    }
  }
    Future<Notification> getNotificationByUserId(String id) async {
    final response = await http.get(
      Uri.parse('$apiUrl/userid/$id'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    if (response.statusCode == 200) {
      return Notification.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load client.');
    }
  }
}