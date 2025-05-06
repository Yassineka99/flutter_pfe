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
    final response = await http.post(
      Uri.parse('$apiUrl1/create'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'name': name!,
        'workflow_id': workflowId!.toString(),
        'status_id': statusId!.toString(),
        'order': order!.toString(),
        'created_by': createdBy!.toString(),
      }),
    );
    if (response.statusCode == 201) {
      return Process.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create client.');
    }
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
          .timeout(Duration(seconds: 5));
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
            ''', [xx['id'], xx['name'], xx['workflow_id'], xx['created_by']]);
          }
        });
        return data.map((item) => Process.fromJson(item)).toList();
      }
    } catch (e) {
      // TODO
    }
        final List<Map<String, dynamic>> raw =
        await _dbHelper.readData("SELECT * FROM process");
    return raw.map<Process>((row) => Process.fromJson(row)).toList();
  }

  Future<List<Process>> getByStatusId(int userId) async {
    try {
      final response = await http
          .get(Uri.parse('$apiUrl1/get-all-by-status-id/$userId'))
          .timeout(Duration(seconds: 5));
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        final db = await _dbHelper.database;
        await db!.transaction((txn) async {
          for (var xx in data) {
            await txn.rawInsert('''
            INSERT OR REPLACE INTO process
            (id,name,workflow_id,status_id,created_by,is_synced)
            VALUES(?,?,?,?,?,1)
            ''', [xx['id'], xx['name'], xx['workflow_id'], xx['created_by']]);
          }
        });
        return data.map((item) => Process.fromJson(item)).toList();
      }
    } catch (e) {
      // TODO
    }
    final List<Map<String, dynamic>> raw =
        await _dbHelper.readData("SELECT * FROM process");
    return raw.map<Process>((row) => Process.fromJson(row)).toList();
  }

  Future<List<Process>> getByWorkflowId(int workflowId) async {
    try {
      final response = await http
          .get(Uri.parse('$apiUrl1/get-all-by-workflow-id/$workflowId'))
          .timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        final db = await _dbHelper.database;
        await db!.transaction((txn) async {
          for (var wf in data) {
            await txn.rawInsert('''
              INSERT OR REPLACE INTO process
              (id,name,workflow_id,status_id,created_by,is_synced)
              VALUES(?,?,?,?,?,1)
              ''', [wf['id'], wf['name'], wf['workflow_id'], wf['created_by']]);
          }
        });
        return data.map((item) => Process.fromJson(item)).toList();
      }
    } catch (e) {
      print(
          'Server fetch failed process , will use local process table data :$e');
    }
    final List<Map<String, dynamic>> raw =
        await _dbHelper.readData("SELECT * FROM process");
    return raw.map<Process>((row) => Process.fromJson(row)).toList();
  }

  Future<Process> updateProcess(Process process) async {
    final response = await http.post(
      Uri.parse('$apiUrl1/update'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(process.toJson()),
    );

    if (response.statusCode == 200) {
      return Process.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update process');
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

    final unsynced =
        await _dbHelper.readData("SELECT * FROM process WHERE is_synced = 0");

    for (var wf in unsynced) {
      try {
        final response = await http.post(
          Uri.parse('$apiUrl1/create'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': wf['name'],
            'workflow_id': wf['workflow_id'],
            'status_id': wf['status_id'],
            'created_by': wf['created_by']
          }),
        );

        if (response.statusCode == 201) {
          final serverWf = Process.fromJson(jsonDecode(response.body));
          // Update local ID and mark as synced
          await _dbHelper.updateData(
              "UPDATE process SET id = ${serverWf.id}, is_synced = 1 "
              "WHERE id = ${wf['id']}");
        }
      } catch (e) {
        print('Sync error: $e');
      }
    }
  }
}
