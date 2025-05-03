import 'dart:convert';

import '../env.dart';
import '../model/process.dart';
import 'package:http/http.dart' as http;

import '../model/sub_process.dart';

class SubProcessRepoitory {
  static const String apiUrl1 = '$baseUrl/api/subprocess';
  Future<SubProcess> createSubProcess(
  String? name,
  int? processId,
  int? statusId,
  String? message,
  int? assignedTo,
  int? createdBy,
  ) async {
    final response = await http.post(
      Uri.parse('$apiUrl1/create'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'name': name!,
        'process_id': processId!.toString(),
        'status_id': statusId!.toString(),
        'created_by': createdBy!.toString(),
        'message': message!,
        'assigned_to': assignedTo!.toString(),

      }),
    );
    if (response.statusCode == 201) {
      return SubProcess.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create client.');
    }
  }

  Future<SubProcess> getSubProcessById(String id) async {
    final response = await http.get(
      Uri.parse('$apiUrl1/get-by-id/$id'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    if (response.statusCode == 200) {
      return SubProcess.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load client.');
    }
  }
  // Get all
Future<List<SubProcess>> getAllSubProcesses() async {
  final response = await http.get(Uri.parse('$apiUrl1/get-all'));
  if (response.statusCode == 200) {
    List<dynamic> data = jsonDecode(response.body);
    return data.map((item) => SubProcess.fromJson(item)).toList();
  } else {
    throw Exception('Failed to load subprocesses');
  }
}

// Get by process ID
Future<List<SubProcess>> getByProcessId(int processId) async {
  final response = await http.get(Uri.parse('$apiUrl1/get-all-by-process-id/$processId'));
  if (response.statusCode == 200) {
    List<dynamic> data = jsonDecode(response.body);
    return data.map((item) => SubProcess.fromJson(item)).toList();
  } else {
    throw Exception('Failed to load by process ID');
  }
}

// Get by user ID
Future<List<SubProcess>> getByUserId(int userId) async {
  final response = await http.get(Uri.parse('$apiUrl1/get-all-by-user-id/$userId'));
  if (response.statusCode == 200) {
    List<dynamic> data = jsonDecode(response.body);
    return data.map((item) => SubProcess.fromJson(item)).toList();
  } else {
    throw Exception('Failed to load by user ID');
  }
}

// Get by user and process ID
Future<List<SubProcess>> getByUserAndProcessId(int userId, int processId) async {
  final response = await http.get(Uri.parse('$apiUrl1/get-all-by-user-process-id/$userId/$processId'));
  if (response.statusCode == 200) {
    List<dynamic> data = jsonDecode(response.body);
    return data.map((item) => SubProcess.fromJson(item)).toList();
  } else {
    throw Exception('Failed to load by user and process ID');
  }
}

// Update
Future<SubProcess> updateSubProcess(SubProcess subProcess) async {
  final response = await http.post(
    Uri.parse('$apiUrl1/update'),
    headers: {'Content-Type': 'application/json; charset=UTF-8'},
    body: jsonEncode(subProcess.toJson()),
  );
  if (response.statusCode == 200) {
    return SubProcess.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to update subprocess');
  }
}

// Delete
Future<void> deleteSubProcess(int id) async {
  final response = await http.post(Uri.parse('$apiUrl1/delete/$id'));
  if (response.statusCode != 200) {
    throw Exception('Failed to delete subprocess');
  }
}


}