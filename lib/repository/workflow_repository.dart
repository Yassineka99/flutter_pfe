import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:front/services/db_helper.dart';

import '../env.dart';
import '../model/workflow.dart';
import 'package:http/http.dart' as http;

class WorkflowRepository {
  static const String apiUrl1 = '$baseUrl/api/workflow';
  final DBHelper _dbHelper = DBHelper();
  Future<Workflow> createWorkflow(String name, int createdBy) async {
  try {
    // Attempt the server call with a timeout:
    final response = await http
      .post(
        Uri.parse('$apiUrl1/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'createdBy': createdBy}),
      )
      .timeout(const Duration(seconds: 5));

    if (response.statusCode == 201) {
      final serverWf = Workflow.fromJson(jsonDecode(response.body));
      // Mirror in SQLite as synced…
      await _dbHelper.insertData('''
        INSERT OR REPLACE INTO workflow
          (id, name, created_by, is_synced, is_deleted, needs_update)
        VALUES
          (?, ?, ?, 1, 0, 0)
      ''', [serverWf.id, serverWf.name, serverWf.createdBy]);
      return serverWf;
    }
    // Non-201 status is treated like an offline failure:
    throw Exception('Server returned ${response.statusCode}');
  } catch (e) {
  print('createWorkflow: server failed, falling back offline: $e');
  final localId = await _dbHelper.insertData('''
    INSERT INTO workflow
      (name, created_by, is_synced, is_deleted, needs_update)
    VALUES
      (?, ?, 0, 0, 0)
  ''', [name, createdBy]);
  print('Offline workflow created with local ID: $localId');
  return Workflow(id: localId, name: name, createdBy: createdBy);
}
}


  Future<Workflow> getWorkflowById(String id) async {
    final response = await http.get(
      Uri.parse('$apiUrl1/id/$id'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    if (response.statusCode == 200) {
      return Workflow.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load client.');
    }
  }

  Future<Workflow> getWorkflowByName(String id) async {
    final response = await http.get(
      Uri.parse('$apiUrl1/workflow-name/$id'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    if (response.statusCode == 200) {
      return Workflow.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load client.');
    }
  }

Future<List<Workflow>> getAllWorkflows() async {
  try {
    // try remote fetch
    final response = await http
      .get(Uri.parse('$apiUrl1/get-all'))
      .timeout(Duration(seconds: 5));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      // write into sqlite
      final db = await _dbHelper.database;
      await db!.transaction((txn) async {
        for (var wf in data) {
          await txn.rawInsert('''
            INSERT OR REPLACE INTO workflow 
            (id, name, created_by, is_synced)
            VALUES (?, ?, ?, 1)
          ''', [wf['id'], wf['name'], wf['createdBy']]);
        }
      });
      // map JSON → Workflow
      return data
        .map<Workflow>((json) => Workflow.fromJson(json as Map<String, dynamic>))
        .toList();
    }
  } catch (e) {
    // if remote fails, fall through to offline branch
    print('Server fetch failed, using local data: $e');
  }

  // ‣ OFFLINE: read raw rows from sqflite
  final List<Map<String, dynamic>> raw = 
      await _dbHelper.readData("SELECT * FROM workflow");
  // map to Workflow and return
  return raw
    .map<Workflow>((row) => Workflow.fromJson(row))
    .toList();
}

  Future<Workflow> updateWorkflow(Workflow subProcess) async {
    final response = await http.post(
      Uri.parse('$apiUrl1/update'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(subProcess.toJson()),
    );
    if (response.statusCode == 200) {
      return Workflow.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update subprocess');
    }
  }

// Delete
  Future<void> deleteWorkflow(int id) async {
    final response = await http.post(Uri.parse('$apiUrl1/delete/$id'));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete subprocess');
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

Future<void> syncWorkflows() async {
  if (!await _isConnected()) return;

  final db = await _dbHelper.database;

  // ── 1) New rows (is_synced = 0 && needs_update = 0 && is_deleted = 0)
  final newRows = await _dbHelper.readData(
    "SELECT * FROM workflow WHERE is_synced = 0 AND needs_update = 0 AND is_deleted = 0"
  );
  // ... your POST-create logic, then mark is_synced = 1 ...

  // ── 2) Updated rows (needs_update = 1 && is_deleted = 0)
  final updatedRows = await _dbHelper.readData(
    "SELECT * FROM workflow WHERE needs_update = 1 AND is_deleted = 0"
  );
  for (var row in updatedRows) {
    final wf = Workflow.fromJson(row);
    final response = await http.post(
      Uri.parse('$apiUrl1/update'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(wf.toJson()),
    );
    if (response.statusCode == 200) {
      await _dbHelper.updateData(
        "UPDATE workflow SET is_synced = 1, needs_update = 0 WHERE id = ${wf.id}"
      );
    }
  }

  // ── 3) Deleted rows (is_deleted = 1)
  final deletedRows = await _dbHelper.readData(
    "SELECT * FROM workflow WHERE is_deleted = 1"
  );
  for (var row in deletedRows) {
    final id = row['id'];
    final response = await http.post(Uri.parse('$apiUrl1/delete/$id'));
    if (response.statusCode == 200) {
      await _dbHelper.deleteData("DELETE FROM workflow WHERE id = $id");
    }
  }
}

}
