import 'dart:convert';
import 'dart:io';

import '../env.dart';
import '../model/process.dart';
import 'package:http/http.dart' as http;

import '../services/db_helper.dart';

class ProcessRepoitory {
  static const String apiUrl1 = '$baseUrl/api/process';
  final DBHelper _dbHelper = DBHelper();
  Future<Process> createProcess(
    String? name,
    int? workflowId,
    int? statusId,
    int? order,
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
              'workflow_id': workflowId!.toString(),
              'status_id': statusId!.toString(),
              'order': order!.toString(),
              'created_by': createdBy!.toString()
            }),
          )
          .timeout(Duration(milliseconds: 1000));
      if (response.statusCode == 201) {
        final serverWf = Process.fromJson(jsonDecode(response.body));
        // Mirror in SQLite as synced…
        await _dbHelper.insertData('''
        INSERT OR REPLACE INTO process
          (id, name, workflow_id ,status_id, ordera , created_by , is_synced, is_deleted, needs_update)
        VALUES
          (?, ?, ?, ?,?,?, 1, 0, 0)
      ''', [
          serverWf.id,
          serverWf.name,
          serverWf.workflowId,
          serverWf.statusId,
          serverWf.order,
          serverWf.createdBy
        ]);
        return serverWf;
      }
    } catch (e) {
      final localId = await _dbHelper.insertData('''
    INSERT INTO process
      (name, workflow_id ,status_id, ordera , created_by,is_synced, is_deleted, needs_update)
    VALUES
      (?, ?,?,?,?,0, 0, 0)
  ''', [name, workflowId, statusId, order, createdBy]);
      print('Offline process created with local ID: $localId');
      return Process(
          id: localId,
          name: name,
          createdBy: createdBy,
          workflowId: workflowId,
          statusId: statusId,
          order: order);
    }
    throw Exception('failed to create');
  }

  Future<Process> getProcessById(String id) async {
    final response = await http.get(
      Uri.parse('$apiUrl1/get-process-by-id/$id'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    if (response.statusCode == 200) {
      return Process.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load client.');
    }
  }

  Future<List<Process>> getByUserId(int userId) async {
    try {
      final response = await http
          .get(Uri.parse('$apiUrl1/get-all-by-user-id/$userId'))
          .timeout(Duration(milliseconds: 1500));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        final db = await _dbHelper.database;
        await db!.transaction((txn) async {
          for (var xx in data)
          {
            await txn.rawInsert('''
            INSERT OR REPLACE INTO process
            (id,name,workflow_id,status_id,created_by,is_synced)
            VALUES(?,?,?,?,?,1)
            ''', [xx['id'], xx['name'], xx['workflow_id'],xx['status_id'], xx['created_by']]);
          }
        });
        return data.map((item) => Process.fromJson(item)).toList();
      }
    } catch (e) {
      // TODO
    }
        final List<Map<String, dynamic>> raw =
        await _dbHelper.readData("SELECT * FROM process WHERE created_by=$userId");
    return raw.map<Process>((row) => Process.fromJson(row)).toList();
  }

  Future<List<Process>> getByStatusId(int userId) async {
    try {
      final response = await http
          .get(Uri.parse('$apiUrl1/get-all-by-status-id/$userId'))
          .timeout(Duration(milliseconds: 1500));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        final db = await _dbHelper.database;
        await db!.transaction((txn) async {
          for (var xx in data) {
            await txn.rawInsert('''
            INSERT OR REPLACE INTO process
            (id,name,workflow_id,status_id,created_by,is_synced)
            VALUES(?,?,?,?,?,1)
            ''', [xx['id'], xx['name'], xx['workflow_id'],xx['status_id'], xx['created_by']]);
          }
        });
        return data.map((item) => Process.fromJson(item)).toList();
      }
    } catch (e) {
      // TODO
    }
    final List<Map<String, dynamic>> raw =
        await _dbHelper.readData("SELECT * FROM process WHERE status_id=$userId");
    return raw.map<Process>((row) => Process.fromJson(row)).toList();
  }

  Future<List<Process>> getByWorkflowId(int workflowId) async {
    try {
      final response = await http
          .get(Uri.parse('$apiUrl1/get-all-by-workflow-id/$workflowId'))
          .timeout(Duration(milliseconds: 1500));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        final db = await _dbHelper.database;
        await db!.transaction((txn) async {
          for (var wf in data) {
            await txn.rawInsert('''
              INSERT OR REPLACE INTO process
              (id,name,workflow_id,status_id,created_by,is_synced)
              VALUES(?,?,?,?,?,1)
              ''', [wf['id'], wf['name'], wf['workflow_id'],wf['status_id'] ,wf['created_by']]);
          }
        });
        return data.map<Process>((json)=>Process.fromJson(json as Map<String,dynamic>)).toList();
      }
    } catch (e) {
      print(
          'Server fetch failed process , will use local process table data :$e');
    }
    final List<Map<String, dynamic>> raw =
        await _dbHelper.readData("SELECT * FROM process WHERE workflow_id=$workflowId");
    return raw.map<Process>((row) => Process.fromJson(row)).toList();
  }

  Future<Process> updateProcess(Process subProcess) async {
    try {
      // Try the server, with a timeout
      final response = await http
          .post(
            Uri.parse('$apiUrl1/update'),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode(subProcess.toJson()),
          )
          .timeout(const Duration(milliseconds: 1000));

      if (response.statusCode == 200) {
        final updated = Process.fromJson(jsonDecode(response.body));
        // Mirror in SQLite as synced
        await _dbHelper.updateData(
          '''
        UPDATE process
        SET name = ?, workflow_id = ?,status_id= ? ,order=?,created_by=?,is_synced = 1, needs_update = 0
        WHERE id = ?
        ''',
          [
            updated.name,
            updated.workflowId,
            updated.statusId,
            updated.order,
            updated.createdBy,
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
      UPDATE process
      SET name = ?, workflow_id = ?,status_id= ? ,order=?,created_by=? , needs_update = 1
      WHERE id = ?
      ''',
          [
            subProcess.name,
            subProcess.workflowId,
            subProcess.statusId,
            subProcess.order,
            subProcess.createdBy,
            subProcess.id
          ],
      );
      return subProcess;
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

 Future<void> syncProcess() async {
  if (!await _isConnected()) return;
  final db = await _dbHelper.database;

  // CREATE (Insert new records from local to server)
  final newRows = await _dbHelper.readData('''
    SELECT * FROM process 
    WHERE is_synced = 0 AND needs_update = 0 AND is_deleted = 0
  ''');

  for (var row in newRows) {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl1/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': row['name'],
          'workflow_id': row['workflow_id'],
          'status_id': row['status_id'],
          'order': row['ordera'],
          'created_by': row['created_by'],
        }),
      );

      if (response.statusCode == 201) {
        final servWf = Process.fromJson(jsonDecode(response.body));

        // Insert new with real server ID and delete the old row
        await db!.transaction((txn) async {
          await txn.insert('process', {
            'id': servWf.id,
            'name': row['name'],
            'workflow_id': row['workflow_id'],
            'status_id': row['status_id'],
            'ordera': row['ordera'],
            'created_by': row['created_by'],
            'is_synced': 1,
            'is_deleted': 0,
            'needs_update': 0,
          });
          await txn.delete('process', where: 'id = ?', whereArgs: [row['id']]);
        });
      }
    } catch (e) {
      // Log the error if needed
    }
  }

  // UPDATE (Send changes to server)
  final updatedRows = await _dbHelper.readData('''
    SELECT * FROM process WHERE needs_update = 1 AND is_deleted = 0
  ''');

  for (var row in updatedRows) {
    try {
      final wf = Process.fromJson(row);
      final response = await http.post(
        Uri.parse('$apiUrl1/update'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(wf.toJson()),
      );

      if (response.statusCode == 200) {
        await _dbHelper.updateData('''
          UPDATE process SET is_synced = 1, needs_update = 0 WHERE id = ${wf.id}
        ''');
      }
    } catch (e) {
      // Log the error if needed
    }
  }

  // DELETE (Remove deleted rows from server and local)
  final deletedRows = await _dbHelper.readData('''
    SELECT * FROM process WHERE is_deleted = 1
  ''');

  for (var row in deletedRows) {
    try {
      final id = row['id'];
      final response = await http.post(Uri.parse('$apiUrl1/delete/$id'));
      if (response.statusCode == 200) {
        await _dbHelper.deleteData('DELETE FROM process WHERE id = $id');
      }
    } catch (e) {
      // Log the error if needed
    }
  }
}

}
