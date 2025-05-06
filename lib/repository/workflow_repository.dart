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
    final isOnline = await _isConnected();

    if (isOnline) {
      // Online: Send to server and insert locally
      final response = await http.post(
        Uri.parse('$apiUrl1/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'createdBy': createdBy}),
      );

      if (response.statusCode == 201) {
        final serverWorkflow = Workflow.fromJson(jsonDecode(response.body));
        await _dbHelper.insertData(
            "INSERT INTO workflow (id, name, created_by, is_synced) "
            "VALUES (${serverWorkflow.id}, '$name', $createdBy, 1)");
        return serverWorkflow;
      }
      throw Exception('Failed to create workflow');
    } else {
      // Offline: Insert locally with is_synced=0
      final localId = await _dbHelper
          .insertData("INSERT INTO workflow (name, created_by, is_synced) "
              "VALUES ('$name', $createdBy, 0)");
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

    final unsynced =
        await _dbHelper.readData("SELECT * FROM workflow WHERE is_synced = 0");

    for (var wf in unsynced) {
      try {
        final response = await http.post(
          Uri.parse('$apiUrl1/create'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'name': wf['name'], 'createdBy': wf['created_by']}),
        );

        if (response.statusCode == 201) {
          final serverWf = Workflow.fromJson(jsonDecode(response.body));
          // Update local ID and mark as synced
          await _dbHelper.updateData(
              "UPDATE workflow SET id = ${serverWf.id}, is_synced = 1 "
              "WHERE id = ${wf['id']}");
        }
      } catch (e) {
        print('Sync error: $e');
      }
    }
  }
}
