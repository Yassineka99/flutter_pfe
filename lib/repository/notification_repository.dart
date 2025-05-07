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
  try {
    // Attempt the server call with a timeout:
    final response = await http
      .post(
        Uri.parse('$apiUrl/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': message, 'user_to_notify': userToNotify}),
      )
      .timeout(const Duration(seconds: 5));

    if (response.statusCode == 201) {
      final serverWf = Notification.fromJson(jsonDecode(response.body));
      // Mirror in SQLite as synced…
      await _dbHelper.insertData('''
        INSERT OR REPLACE INTO notification
          (id, message, user_to_notify, is_synced, is_deleted, needs_update)
        VALUES
          (?, ?, ?, 1, 0, 0)
      ''', [serverWf.id, serverWf.message, serverWf.userToNotify]);
      return serverWf;
    }
    // Non-201 status is treated like an offline failure:
    throw Exception('Server returned ${response.statusCode}');
  } catch (e) {
  print('create notification : server failed, falling back offline: $e');
  final localId = await _dbHelper.insertData('''
    INSERT INTO notification
      (message, user_to_notify, is_synced, is_deleted, needs_update)
    VALUES
      (?, ?, 0, 0, 0)
  ''', [message, userToNotify]);
  print('Offline notification created with local ID: $localId');
  return Notification(id: localId, message: message, userToNotify: userToNotify);
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
    final db = await _dbHelper.database;
    //create
    final newRows = await _dbHelper.readData(
        "SELECT * FROM notification WHERE is_synced =0 AND needs_update = 0 AND is_deleted =0");
    for (var row in newRows) {
      try {
        final response = await http.post(
          Uri.parse('$apiUrl/create'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': row['name'],
            'user_to_notify': row['user_to_notify'],
          }),
        );
        if (response.statusCode == 201) {
          final servWf = Notification.fromJson(jsonDecode(response.body));
          await _dbHelper.updateData('''
          Update notification
          SET id= ${servWf.id},
          is_synced = 1 
          WHERE id = ${row['id']}
          ''');
        }
      } catch (e) {}
    }
  }
}
