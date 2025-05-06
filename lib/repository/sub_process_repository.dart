import 'dart:convert';
import 'dart:io';

import '../env.dart';
import '../model/process.dart';
import 'package:http/http.dart' as http;

import '../model/sub_process.dart';
import '../services/db_helper.dart';

class SubProcessRepoitory {
  static const String apiUrl1 = '$baseUrl/api/subprocess';
  final DBHelper _dbHelper = DBHelper();
  Future<SubProcess> createSubProcess(
    String? name,
    int? processId,
    int? statusId,
    String? message,
    int? assignedTo,
    int? createdBy,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$apiUrl1/create'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode(<String, String>{
              'name': name!,
              'process_id': processId!.toString(),
              'status': statusId!.toString(),
              'created_by': createdBy!.toString(),
              'message': message!,
              'assigned_to': assignedTo!.toString(),
            }),
          )
          .timeout(Duration(seconds: 5));
      if (response.statusCode == 201) {
        final serverWf = SubProcess.fromJson(jsonDecode(response.body));
        // Mirror in SQLite as synced…
        await _dbHelper.insertData('''
        INSERT OR REPLACE INTO subprocess
          (id, name, process_id ,created_by, message , assigned_to , is_synced, is_deleted, needs_update)
        VALUES
          (?, ?, ?, ?,?,?, 1, 0, 0)
      ''', [
          serverWf.id,
          serverWf.name,
          serverWf.processId,
          serverWf.createdBy,
          serverWf.message,
          serverWf.assignedTo
        ]);
        return serverWf;
      }
    } catch (e) {
      final localId = await _dbHelper.insertData('''
    INSERT INTO workflow
      (name, process_id ,created_by, message , assigned_to,is_synced, is_deleted, needs_update)
    VALUES
      (?, ?,?,?,?,0, 0, 0)
  ''', [name, processId, createdBy, message, assignedTo]);
      print('Offline workflow created with local ID: $localId');
      return SubProcess(
          id: localId,
          name: name,
          createdBy: createdBy,
          processId: processId,
          message: message,
          assignedTo: assignedTo);
    }
    throw Exception('failed to create');
  }

  Future<SubProcess> getSubProcessById(String id) async {
    final response = await http.get(
      Uri.parse('$apiUrl1/get-by-id/$id'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    ).timeout(Duration(seconds: 3));
    if (response.statusCode == 200) {
      return SubProcess.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load client.');
    }
  }

  // Get all
  Future<List<SubProcess>> getAllSubProcesses() async {
    try {
      final response = await http
          .get(Uri.parse('$apiUrl1/get-all'))
          .timeout(Duration(seconds: 3));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        final db = await _dbHelper.database;
        await db!.transaction((txn) async {
          for (var wf in data) {
            await txn.rawInsert('''
            INSERT OR REPLACE INTO subprocess
            (id,name,process_id,status,assigned_to,is_synced)
            VALUES(?,?,?,?,?,1)
            ''', [
              wf['id'],
              wf['name'],
              wf['process_id'],
              wf['status'],
              wf['assigned_to']
            ]);
          }
        });

        return data.map((item) => SubProcess.fromJson(item)).toList();
      }
    } catch (e) {
      print("Not connected , getting data from subprocess local : $e");
    }
    final List<Map<String, dynamic>> raw =
        await _dbHelper.readData("SELECT * FROM subprocess");
    return raw.map<SubProcess>((row) => SubProcess.fromJson(row)).toList();
  }

// Get by process ID
  Future<List<SubProcess>> getByProcessId(int processId) async {
    try {
      final response = await http
          .get(Uri.parse('$apiUrl1/get-all-by-process-id/$processId'))
          .timeout(Duration(seconds: 3));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        final db = await _dbHelper.database;
        await db!.transaction((txn) async {
          for (var fx in data) {
            await txn.rawInsert('''
            INSERT OR REPLACE INTO subprocess
            (id,name,process_id,status,assigned_to,is_synced)
            VALUES(?,?,?,?,?,1)
            ''', [
              fx['id'],
              fx['name'],
              fx['process_id'],
              fx['status'],
              fx['assigned_to']
            ]);
          }
        });
        return data.map((item) => SubProcess.fromJson(item)).toList();
      }
    } catch (e) {
      print(
          "failed to get data , trying to get local sub process data (get process by id methode ) :$e");
    }

    final List<Map<String, dynamic>> raw = await _dbHelper
        .readData("SELECT * FROM subprocess WHERE process_id=$processId");
    return raw.map<SubProcess>((row) => SubProcess.fromJson(row)).toList();
  }

// Get by user ID
  Future<List<SubProcess>> getByUserId(int userId) async {
    try {
      final response = await http
          .get(Uri.parse('$apiUrl1/get-all-by-user-id/$userId'))
          .timeout(Duration(seconds: 3));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        final db = await _dbHelper.database;
        await db!.transaction((txn) async {
          for (var xx in data) {
            await txn.rawInsert('''
            INSERT OR REPLACE INTO subprocess
            (id,name,process_id,status,assigned_to,is_synced)
            VALUES(?,?,?,?,?,1)
            ''', [
              xx['id'],
              xx['name'],
              xx['process_id'],
              xx['status'],
              xx['assigned_to']
            ]);
          }
        });
        return data.map((item) => SubProcess.fromJson(item)).toList();
      }
    } catch (e) {
      print(
          "error fetching data , will fetch subprocess locally (get by user id  ) : $e");
    }

    final List<Map<String, dynamic>> raw = await _dbHelper
        .readData("SELECT * FROM subprocess WHERE assigned_to=$userId");
    return raw.map<SubProcess>((row) => SubProcess.fromJson(row)).toList();
  }

// Get by user and process ID
  Future<List<SubProcess>> getByUserAndProcessId(
      int userId, int processId) async {
    try {
      final response = await http
          .get(Uri.parse(
              '$apiUrl1/get-all-by-user-process-id/$userId/$processId'))
          .timeout(Duration(seconds: 3));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        final db = await _dbHelper.database;
        await db!.transaction((txn) async {
          for (var xx in data) {
            await txn.rawInsert('''
          INSERT OR REPLACE INTO subprocess
          (id,name,process_id,status,assigned_to,is_synced)
          VALUES(?,?,?,?,?,1)
          ''', [
              xx['id'],
              xx['name'],
              xx['process_id'],
              xx['status'],
              xx['assigned_to']
            ]);
          }
        });
        return data.map((item) => SubProcess.fromJson(item)).toList();
      }
    } catch (e) {
      print(
          "fetching data from subprocess locally (gyby user and process id) : $e");
    }
    final List<Map<String, dynamic>> raw = await _dbHelper.readData(
        "SELECT * FROM subprocess WHERE assigned_to=$userId AND process_id=$processId");
    return raw.map<SubProcess>((row) => SubProcess.fromJson(row)).toList();
  }

// Update
  Future<SubProcess> updateSubProcess(SubProcess subProcess) async {
    try {
      // Try the server, with a timeout
      final response = await http
          .post(
            Uri.parse('$apiUrl1/update'),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode(subProcess.toJson()),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final updated = SubProcess.fromJson(jsonDecode(response.body));
        // Mirror in SQLite as synced
        await _dbHelper.updateData(
          '''
        UPDATE subprocess
        SET name = ?, process_id = ?,status= ? ,created_by=?,message=?,assigned_to=?,is_synced = 1, needs_update = 0
        WHERE id = ?
        ''',
          [
            updated.name,
            updated.processId,
            updated.statusId,
            updated.createdBy,
            updated.message,
            updated.assignedTo,
            updated.id
          ],
        );
        return updated;
      }
      throw Exception('Server returned ${response.statusCode}');
    } catch (e) {
      // Offline or server error → queue for later sync
      print('updateWorkflow: server failed, queuing offline: $e');
      await _dbHelper.updateData(
        '''
      UPDATE subprocess
      SET name = ?, process_id = ?,status= ? ,created_by=?,message=?,assigned_to=? , needs_update = 1
      WHERE id = ?
      ''',
        [
          subProcess.name,
          subProcess.processId,
          subProcess.statusId,
          subProcess.createdBy,
          subProcess.message,
          subProcess.assignedTo,
          subProcess.id
        ],
      );
      return subProcess;
    }
  }

// Delete
  Future<void> deleteSubProcess(int id) async {
    try {
      final response = await http
          .post(Uri.parse('$apiUrl1/delete/$id'))
          .timeout(Duration(seconds: 5));
      if (response.statusCode == 200) {
        await _dbHelper.deleteData('''
    DELETE FROM subprocess WHERE id = ?
    ''', [id]);
        return;
      }
      throw Exception('server returned ${response.statusCode}');
    } catch (e) {
      // Offline or server error → flag for deletion
      print('delete subprocess: server failed, flagging offline: $e');
      await _dbHelper.updateData(
        '''
      UPDATE subprocess
      SET is_deleted = 1
      WHERE id = ?
      ''',
        [id],
      );
    }
  }

  Future<List<SubProcess>> getByStatusAndUserId(int status, int userid) async {
    try {
      final response = await http
          .get(Uri.parse(
              '$apiUrl1/get-all-by-status-and-user-id/$status/$userid'))
          .timeout(Duration(seconds: 3));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        final db = await _dbHelper.database;
        await db!.transaction((txn) async {
          for (var xx in data) {
            await txn.rawInsert('''
          INSERT OR REPLACE INTO subprocess
          (id,name,process_id,status,assigned_to,is_synced)
          VALUES(?,?,?,?,?,1)
          ''', [
              xx['id'],
              xx['name'],
              xx['process_id'],
              xx['status'],
              xx['assigned_to']
            ]);
          }
        });

        return data.map((item) => SubProcess.fromJson(item)).toList();
      }
    } catch (e) {}
    final List<Map<String, dynamic>> raw = await _dbHelper.readData(
        "SELECT * FROM subprocess WHERE status=$status AND assigned_to=$userid");
    return raw.map<SubProcess>((row) => SubProcess.fromJson(row)).toList();
  }

  Future<bool> _isConnected() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<void> syncSubProcess() async {
    if (!await _isConnected()) return;
    final db = await _dbHelper.database;
    final newRows = await _dbHelper.readData(
        "SELECT * FROM subprocess WHERE is_synced =0 AND needs_update = 0 AND is_deleted =0");
    for (var row in newRows) {
      try {
        final response = await http.post(
          Uri.parse('$apiUrl1/create'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': row['name'],
            'process_id': row['process_id'],
            'status': row['status'],
            'created_by': row['created_by'],
            'message': row['message'],
            'assigned_to': row['assigned_to']
          }),
        );
        if (response.statusCode == 201) {
          final servWf = SubProcess.fromJson(jsonDecode(response.body));
          await _dbHelper.updateData('''
          Update workflow
          SET id= ${servWf.id},
          is_synced = 1 ,
          WHERE id = ${row['id']}
          ''');
        }
      } catch (e) {}
    }
    final updatedRows = await _dbHelper.readData('''
    SELECT * FROM subprocess WHERE needs_update = 1 AND is_deleted = 0
    ''');
    for (var row in updatedRows) {
      final wf = SubProcess.fromJson(row);
      final response = await http.post(Uri.parse('$apiUrl1/update'),
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
          body: jsonEncode(wf.toJson()));
      if (response.statusCode == 200) {
        await _dbHelper.updateData('''
          UPDATE subprocess SET is_synced = 1 , need_update=0 WHERE id = ${wf.id}
        ''');
      }
    }
    // ── 3) Deleted rows (is_deleted = 1)
    final deletedRows = await _dbHelper
        .readData("SELECT * FROM subprocess WHERE is_deleted = 1");
    for (var row in deletedRows) {
      final id = row['id'];
      final response = await http.post(Uri.parse('$apiUrl1/delete/$id'));
      if (response.statusCode == 200) {
        await _dbHelper.deleteData("DELETE FROM subprocess WHERE id = $id");
      }
    }
  }
}
