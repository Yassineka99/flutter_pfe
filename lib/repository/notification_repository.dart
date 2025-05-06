import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../env.dart';
import '../model/notification.dart';
import '../services/db_helper.dart';

class NotificationRepository {
  static const apiUrl = '$baseUrl/api/notifications';
  final DBHelper _dbHelper = DBHelper();
  Future<Notification> createNotification(
      String? message, int? userToNotify) async {
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
    final response = await http
        .get(Uri.parse('$apiUrl/userid/$userid'))
        .timeout(Duration(seconds: 3));
    try {
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        final db = await _dbHelper.database;
        await db!.transaction((txn) async {
          for (var wf in data) {
            await txn.rawInsert('''
              INSERT OR REPLACE INTO notification
              (id,user_to_notify,message,visiblity,is_synced)
              VALUES(?,?,?,?,1)
              ''', [
              wf['id'],
              wf['user_to_notify'],
              wf['message'],
              wf['visiblity']
            ]);
          }
        });
        return data.map((item) => Notification.fromJson(item)).toList();
      }
    } catch (e) {
      print(
          " couldn't connect  , getting data locally ( notification get by user id ) : $e");
    }
    final List<Map<String, dynamic>> raw = await _dbHelper
        .readData("SELECT * FROM notification WHERE user_to_notify=$userid");
    return raw.map<Notification>((row) => Notification.fromJson(row)).toList();
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
    try {
      final response = await http
          .get(Uri.parse('$apiUrl/unread-notification/$userid'))
          .timeout(Duration(seconds: 3));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        final db = await _dbHelper.database;
        await db!.transaction((txn) async {
            for (var wf in data) {
            await txn.rawInsert('''
              INSERT OR REPLACE INTO notification
              (id,user_to_notify,message,visiblity,is_synced)
              VALUES(?,?,?,?,1)
              ''', [
              wf['id'],
              wf['user_to_notify'],
              wf['message'],
              wf['visiblity']
            ]);
          }
        });
        return data.map((item) => Notification.fromJson(item)).toList();
      }
    } catch (e) {}
    final List<Map<String, dynamic>> raw = await _dbHelper
        .readData("SELECT * FROM notification WHERE user_to_notify=$userid");
    return raw.map<Notification>((row) => Notification.fromJson(row)).toList();
  }

  Future<bool> _isConnected() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<void> syncNotification() async {
    if (!await _isConnected()) return;

    final unsynced = await _dbHelper
        .readData("SELECT * FROM notification WHERE is_synced = 0");

    for (var wf in unsynced) {
      try {
        final response = await http.post(
          Uri.parse('$apiUrl/create'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': wf['name'],
            'user_to_notify': wf['user_to_notify'],
            'message': wf['message'],
            'visiblity': wf['visiblity']
          }),
        );

        if (response.statusCode == 201) {
          final serverWf = Notification.fromJson(jsonDecode(response.body));
          // Update local ID and mark as synced
          await _dbHelper.updateData(
              "UPDATE notification SET id = ${serverWf.id}, is_synced = 1 "
              "WHERE id = ${wf['id']}");
        }
      } catch (e) {
        print('Sync error: $e');
      }
    }
  }
}
