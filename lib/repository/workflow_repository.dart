import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:front/services/db_helper.dart';

import '../env.dart';
import '../model/workflow.dart';
import 'package:http/http.dart' as http;

class WorkflowRepository {
  static const String apiUrl1 = '$baseUrl/api/workflow';
  final DBHelper _dbHelper = DBHelper();
  Future<Workflow> createWorkflow(String name, int createdBy,int quantity , int status_id , String image , String imageType , int product_id) async {
    try {
      // Attempt the server call with a timeout:
      final response = await http
          .post(
            Uri.parse('$apiUrl1/create'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'name': name, 'createdBy': createdBy}),
          )
          .timeout(const Duration(milliseconds: 1200));

      if (response.statusCode == 201) {
        final serverWf = Workflow.fromJson(jsonDecode(response.body));
        // Mirror in SQLite as synced…
        await _dbHelper.insertData('''
        INSERT OR REPLACE INTO workflow
          (id, name, created_by, 
          quantity, status_id , image ,
          imageType , product_id
          is_synced, is_deleted, needs_update)
        VALUES
          (?, ?, ?,?,?,?,?,?, 1, 0, 0)
      ''', [serverWf.id, serverWf.name, 
      serverWf.createdBy,serverWf.quantity,
      serverWf.status_id,serverWf.image,
      serverWf.imageType,serverWf.product_id]);
        return serverWf;
      }
      // Non-201 status is treated like an offline failure:
      throw Exception('Server returned ${response.statusCode}');
    } catch (e) {
      print('createWorkflow: server failed, falling back offline: $e');
      final localId = await _dbHelper.insertData('''
    INSERT INTO workflow
      (name, created_by, 
      quantity , status_id , image , imageType , product_id ,
      is_synced, is_deleted, needs_update)
    VALUES
      (?, ?,?,?,?,?,?, 0, 0, 0)
  ''', [name, createdBy,quantity,status_id,
  image , imageType , product_id]);
      print('Offline workflow created with local ID: $localId');
      return Workflow(id: localId, name: name, createdBy: createdBy , quantity: quantity , status_id: status_id , image: image , imageType: imageType ,product_id: product_id);
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
          .timeout(Duration(milliseconds: 1500));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        // write into sqlite
        final db = await _dbHelper.database;
        await db!.transaction((txn) async {
          for (var wf in data) {
            await txn.rawInsert('''
            INSERT OR REPLACE INTO workflow 
            (id, name, created_by,quantity,status_id,image,imageType,
            product_id
            ,is_synced)
            VALUES (?, ?, ?,?,?,?,?,? ,1)
          ''', [wf['id'], wf['name'], wf['createdBy'],wf['quantity'],wf['status_id'],wf['image'],wf['imageType'],wf['product_id']]);
          }
        });
        // map JSON → Workflow
        return data
            .map<Workflow>(
                (json) => Workflow.fromJson(json as Map<String, dynamic>))
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
    return raw.map<Workflow>((row) => Workflow.fromJson(row)).toList();
  }

  Future<Workflow> updateWorkflow(Workflow wf) async {
    try {
      // Try the server, with a timeout
      final response = await http
          .post(
            Uri.parse('$apiUrl1/update'),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode(wf.toJson()),
          )
          .timeout(const Duration(milliseconds: 1000));

      if (response.statusCode == 200) {
        final updated = Workflow.fromJson(jsonDecode(response.body));
        // Mirror in SQLite as synced
        await _dbHelper.updateData(
          '''
        UPDATE workflow
        SET name = ?, created_by = ?, 
        is_synced = 1, needs_update = 0 ,
        quantity = ? , status_id = ? ,
        image = ? , imageType = ? ,
        product_id = ?
        WHERE id = ?
        ''',
          [updated.name, updated.createdBy, 
          updated.quantity , updated.status_id,
          updated.image, updated.imageType,
          updated.product_id,
          updated.id],
        );
        return updated;
      }
      throw Exception('Server returned ${response.statusCode}');
    } catch (e) {
      // Offline or server error → queue for later sync
      print('updateWorkflow: server failed, queuing offline: $e');
      await _dbHelper.updateData(
        '''
      UPDATE workflow
      SET name = ?, created_by = ?, 
      needs_update = 1 ,quantity = ?,
      status_id = ? ,image = ?,
      imageType = ? , product_id = ?
      WHERE id = ?
      ''',
        [wf.name, wf.createdBy,wf.quantity,wf.status_id,
        wf.image,wf.imageType,wf.product_id,
         wf.id],
      );
      return wf;
    }
  }

// Delete
  Future<void> deleteWorkflow(int id) async {
    try {
      // Try the server, with a timeout
      final response = await http
          .post(Uri.parse('$apiUrl1/delete/$id'))
          .timeout(const Duration(milliseconds: 1000));

      if (response.statusCode == 200) {
        // Remove locally immediately
        await _dbHelper.deleteData(
          'DELETE FROM workflow WHERE id = ?',
          [id],
        );
        return;
      }
      throw Exception('Server returned ${response.statusCode}');
    } catch (e) {
      // Offline or server error → flag for deletion
      print('deleteWorkflow: server failed, flagging offline: $e');
      await _dbHelper.updateData(
        '''
      UPDATE workflow
      SET is_deleted = 1
      WHERE id = ?
      ''',
        [id],
      );
    }
  }

  Future<Uint8List?> getWorkflowImage(int workflowId) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl1/get/$workflowId/image'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        print('Image response headers: ${response.headers}');
        print('Image data length: ${response.bodyBytes.length}');
        return response.bodyBytes; // Directly return the image bytes
      } else {
        print('Failed to fetch workflow image. Status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching workflow image: $e');
      return null;
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
        "SELECT * FROM workflow WHERE is_synced = 0 AND needs_update = 0 AND is_deleted = 0");

    for (var row in newRows) {
      try {
        final response = await http.post(
          Uri.parse('$apiUrl1/create'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': row['name'],
            'createdBy': row['created_by'],
            'quantity':row['quantity'],
            'status_id':row['status_id'],
            'image':row['image'],
            'imageType':row['imageType'],
            'product_id':row['product_id'],
          }),
        );

        if (response.statusCode == 201) {
          final serverWf = Workflow.fromJson(jsonDecode(response.body));

          await db!.transaction((txn) async {
            await txn.insert('workflow', {
              'id': serverWf.id,
              'name': serverWf.name,
              'created_by': serverWf.createdBy,
              'quantity' : serverWf.quantity ,
              'status_id' : serverWf.status_id,
              'image':serverWf.image,
              'imageType':serverWf.imageType,
              'product_id':serverWf.product_id,
              'is_synced': 1,
              'is_deleted': 0,
              'needs_update': 0,
            });
            await txn
                .delete('workflow', where: 'id = ?', whereArgs: [row['id']]);
          });
        }
      } catch (e) {
        print('Workflow sync (create) error: $e');
      }
    }

    // ── 2) Updated rows (needs_update = 1 && is_deleted = 0)
    final updatedRows = await _dbHelper.readData(
        "SELECT * FROM workflow WHERE needs_update = 1 AND is_deleted = 0");
    for (var row in updatedRows) {
      final wf = Workflow.fromJson(row);
      final response = await http.post(
        Uri.parse('$apiUrl1/update'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(wf.toJson()),
      );
      if (response.statusCode == 200) {
        await _dbHelper.updateData(
            "UPDATE workflow SET is_synced = 1, needs_update = 0 WHERE id = ${wf.id}");
      }
    }

    // ── 3) Deleted rows (is_deleted = 1)
    final deletedRows =
        await _dbHelper.readData("SELECT * FROM workflow WHERE is_deleted = 1");
    for (var row in deletedRows) {
      final id = row['id'];
      final response = await http.post(Uri.parse('$apiUrl1/delete/$id'));
      if (response.statusCode == 200) {
        await _dbHelper.deleteData("DELETE FROM workflow WHERE id = $id");
      }
    }
  }
}
