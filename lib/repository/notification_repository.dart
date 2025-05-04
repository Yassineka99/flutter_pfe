import 'dart:convert';
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
Future<List<Notification>> getByUserId(int userid) async {
  final response = await http.get(Uri.parse('$apiUrl/userid/$userid'));
  if (response.statusCode == 200) {
    List<dynamic> data = jsonDecode(response.body);
    return data.map((item) => Notification.fromJson(item)).toList();
  } else {
    throw Exception('Failed to load Notifications ');
  }
}

Future<void> markAllAsRead(int userId) async {
  final response = await http.post(
    Uri.parse('$apiUrl/read/$userId'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to mark notifications as read');
  }
}


Future<List<Notification>> getUnreadNotifications(int userid) async {
  final response = await http.get(Uri.parse('$apiUrl/unread-notification/$userid'));
  if (response.statusCode == 200) {
    List<dynamic> data = jsonDecode(response.body);
    return data.map((item) => Notification.fromJson(item)).toList();
  } else {
    throw Exception('Failed to load Notifications ');
  }
}
}