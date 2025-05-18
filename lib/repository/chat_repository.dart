import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import '../env.dart';
import '../model/chat.dart';
import '../services/db_helper.dart';

class ChatRepository {
  static const String apiUrl1 = '$baseUrl/api/chat';
 final DBHelper _dbHelper = DBHelper();

  Future<Chat> createMessage(String? message, int? from_user, int? to_user) async {
    try {
      // Attempt the server call with a timeout
      final response = await http
          .post(
            Uri.parse('$apiUrl1/create'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(<String, dynamic>{
              'message': message,
              'from_user': from_user,
              'to_user': to_user,
            }),
          )
          .timeout(const Duration(milliseconds: 1200));

      if (response.statusCode == 201) {
        final serverChat = Chat.fromJson(jsonDecode(response.body));
        // Mirror in SQLite as synced
        await _dbHelper.insertData('''
        INSERT OR REPLACE INTO chat
          (id, message, from_user, to_user, from_user_date, 
          is_synced, is_deleted, needs_update)
        VALUES
          (?, ?, ?, ?, ?, 1, 0, 0)
      ''', [
          serverChat.id, 
          serverChat.message, 
          serverChat.from_user, 
          serverChat.to_user,
          serverChat.from_user_date?.toIso8601String()
        ]);
        return serverChat;
      }
      // Non-201 status is treated like an offline failure
      throw Exception('Server returned ${response.statusCode}');
    } catch (e) {
      print('createMessage: server failed, falling back offline: $e');
      final localId = await _dbHelper.insertData('''
        INSERT INTO chat
          (message, from_user, to_user, from_user_date,
          is_synced, is_deleted, needs_update)
        VALUES
          (?, ?, ?, ?, 0, 0, 0)
      ''', [
        message, 
        from_user, 
        to_user,
        DateTime.now().toIso8601String()
      ]);
      print('Offline message created with local ID: $localId');
      return Chat(
        id: localId, 
        message: message, 
        from_user: from_user, 
        to_user: to_user,
        from_user_date: DateTime.now()
      );
    }
  }

  Future<List<Chat>> GetAllbySenderid(int id) async {
    try {
      // try remote fetch
      final response = await http
          .get(Uri.parse('$apiUrl1/get-all-by-sender-id/$id'))
          .timeout(Duration(milliseconds: 1500));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        // write into sqlite
        final db = await _dbHelper.database;
        await db!.transaction((txn) async {
          for (var chat in data) {
            await txn.rawInsert('''
            INSERT OR REPLACE INTO chat 
            (id, message, from_user, to_user, from_user_date, is_synced)
            VALUES (?, ?, ?, ?, ?, 1)
          ''', [
              chat['id'], 
              chat['message'], 
              chat['from_user'], 
              chat['to_user'],
              chat['from_user_date']
            ]);
          }
        });
        return data.map<Chat>((json) => Chat.fromJson(json)).toList();
      }
    } catch (e) {
      print('Server fetch failed, using local data: $e');
    }

    // Offline: read from sqflite
    final List<Map<String, dynamic>> raw = await _dbHelper.readData(
      "SELECT * FROM chat WHERE from_user = ? AND is_deleted = 0",
      [id]
    );
    return raw.map<Chat>((row) => Chat.fromJson(row)).toList();
  }

  Future<List<Chat>> GetAllbyRecieverid(int id) async {
    try {
      // try remote fetch
      final response = await http
          .get(Uri.parse('$apiUrl1/get-all-by-reciever-id/$id'))
          .timeout(Duration(milliseconds: 1500));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        // write into sqlite
        final db = await _dbHelper.database;
        await db!.transaction((txn) async {
          for (var chat in data) {
            await txn.rawInsert('''
            INSERT OR REPLACE INTO chat 
            (id, message, from_user, to_user, from_user_date, is_synced)
            VALUES (?, ?, ?, ?, ?, 1)
          ''', [
              chat['id'], 
              chat['message'], 
              chat['from_user'], 
              chat['to_user'],
              chat['from_user_date']
            ]);
          }
        });
        return data.map<Chat>((json) => Chat.fromJson(json)).toList();
      }
    } catch (e) {
      print('Server fetch failed, using local data: $e');
    }

    // Offline: read from sqflite
    final List<Map<String, dynamic>> raw = await _dbHelper.readData(
      "SELECT * FROM chat WHERE to_user = ? AND is_deleted = 0",
      [id]
    );
    return raw.map<Chat>((row) => Chat.fromJson(row)).toList();
  }

  Future<Chat> updateSubProcess(Chat chat) async {
    try {
      // Try the server, with a timeout
      final response = await http
          .post(
            Uri.parse('$apiUrl1/update'),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode(chat.toJson()),
          )
          .timeout(const Duration(milliseconds: 1000));

      if (response.statusCode == 200) {
        final updated = Chat.fromJson(jsonDecode(response.body));
        // Mirror in SQLite as synced
        await _dbHelper.updateData(
          '''
          UPDATE chat
          SET message = ?, from_user = ?, to_user = ?, from_user_date = ?,
          is_synced = 1, needs_update = 0
          WHERE id = ?
          ''',
          [
            updated.message, 
            updated.from_user, 
            updated.to_user,
            updated.from_user_date?.toIso8601String(),
            updated.id
          ],
        );
        return updated;
      }
      throw Exception('Server returned ${response.statusCode}');
    } catch (e) {
      // Offline or server error → queue for later sync
      print('updateSubProcess: server failed, queuing offline: $e');
      await _dbHelper.updateData(
        '''
        UPDATE chat
        SET message = ?, from_user = ?, to_user = ?, from_user_date = ?,
        needs_update = 1
        WHERE id = ?
        ''',
        [
          chat.message, 
          chat.from_user, 
          chat.to_user,
          chat.from_user_date?.toIso8601String(),
          chat.id
        ],
      );
      return chat;
    }
  }

  Future<List<Chat>> GetAllbySenderAndRecieverid(int sender, int reciever) async {
    try {
      // try remote fetch
      final response = await http
          .get(Uri.parse('$apiUrl1/get-all-by-sender-and-reciever-id/$sender/$reciever'))
          .timeout(Duration(milliseconds: 1500));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        // write into sqlite
        final db = await _dbHelper.database;
        await db!.transaction((txn) async {
          for (var chat in data) {
            await txn.rawInsert('''
            INSERT OR REPLACE INTO chat 
            (id, message, from_user, to_user, from_user_date, is_synced)
            VALUES (?, ?, ?, ?, ?, 1)
          ''', [
              chat['id'], 
              chat['message'], 
              chat['from_user'], 
              chat['to_user'],
              chat['from_user_date']
            ]);
          }
        });
        return data.map<Chat>((json) => Chat.fromJson(json)).toList();
      }
    } catch (e) {
      print('Server fetch failed, using local data: $e');
    }

    // Offline: read from sqflite
    final List<Map<String, dynamic>> raw = await _dbHelper.readData(
      "SELECT * FROM chat WHERE (from_user = ? AND to_user = ?) OR (from_user = ? AND to_user = ?) AND is_deleted = 0",
      [sender, reciever, reciever, sender]
    );
    return raw.map<Chat>((row) => Chat.fromJson(row)).toList();
  }

  Future<void> deleteMessage(int id) async {
    try {
      // Try the server, with a timeout
      final response = await http
          .post(Uri.parse('$apiUrl1/delete/$id'))
          .timeout(const Duration(milliseconds: 1000));

      if (response.statusCode == 200) {
        // Remove locally immediately
        await _dbHelper.deleteData(
          'DELETE FROM chat WHERE id = ?',
          [id],
        );
        return;
      }
      throw Exception('Server returned ${response.statusCode}');
    } catch (e) {
      // Offline or server error → flag for deletion
      print('deleteMessage: server failed, flagging offline: $e');
      await _dbHelper.updateData(
        '''
        UPDATE chat
        SET is_deleted = 1
        WHERE id = ?
        ''',
        [id],
      );
    }
  }

  Future<bool> _isConnected() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<void> syncChats() async {
    if (!await _isConnected()) return;

    final db = await _dbHelper.database;

    // 1) New messages (is_synced = 0 && needs_update = 0 && is_deleted = 0)
    final newMessages = await _dbHelper.readData(
        "SELECT * FROM chat WHERE is_synced = 0 AND needs_update = 0 AND is_deleted = 0");

    for (var row in newMessages) {
      try {
        final response = await http.post(
          Uri.parse('$apiUrl1/create'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'message': row['message'],
            'from_user': row['from_user'],
            'to_user': row['to_user'],
          }),
        );

        if (response.statusCode == 201) {
          final serverChat = Chat.fromJson(jsonDecode(response.body));

          await db!.transaction((txn) async {
            await txn.insert('chat', {
              'id': serverChat.id,
              'message': serverChat.message,
              'from_user': serverChat.from_user,
              'to_user': serverChat.to_user,
              'from_user_date': serverChat.from_user_date?.toIso8601String(),
              'is_synced': 1,
              'is_deleted': 0,
              'needs_update': 0,
            });
            await txn.delete('chat', where: 'id = ?', whereArgs: [row['id']]);
          });
        }
      } catch (e) {
        print('Chat sync (create) error: $e');
      }
    }

    // 2) Updated messages (needs_update = 1 && is_deleted = 0)
    final updatedMessages = await _dbHelper.readData(
        "SELECT * FROM chat WHERE needs_update = 1 AND is_deleted = 0");
    for (var row in updatedMessages) {
      final chat = Chat.fromJson(row);
      final response = await http.post(
        Uri.parse('$apiUrl1/update'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(chat.toJson()),
      );
      if (response.statusCode == 200) {
        await _dbHelper.updateData(
            "UPDATE chat SET is_synced = 1, needs_update = 0 WHERE id = ${chat.id}");
      }
    }

    // 3) Deleted messages (is_deleted = 1)
    final deletedMessages =
        await _dbHelper.readData("SELECT * FROM chat WHERE is_deleted = 1");
    for (var row in deletedMessages) {
      final id = row['id'];
      final response = await http.post(Uri.parse('$apiUrl1/delete/$id'));
      if (response.statusCode == 200) {
        await _dbHelper.deleteData("DELETE FROM chat WHERE id = $id");
      }
    }
  }
}
