import 'dart:convert';

import '../env.dart';
import '../model/process.dart';
import 'package:http/http.dart' as http;

class ProcessRepoitory {
  static const String apiUrl1 = '$baseUrl/api/process';
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
  final response = await http.get(Uri.parse('$apiUrl1/get-all-by-user-id/$userId'));
  if (response.statusCode == 200) {
    List<dynamic> data = jsonDecode(response.body);
    return data.map((item) => Process.fromJson(item)).toList();
  } else {
    throw Exception('Failed to load by user ID');
  }
}

  Future<List<Process>> getByStatusId(int userId) async {
  final response = await http.get(Uri.parse('$apiUrl1/get-all-by-status-id/$userId'));
  if (response.statusCode == 200) {
    List<dynamic> data = jsonDecode(response.body);
    return data.map((item) => Process.fromJson(item)).toList();
  } else {
    throw Exception('Failed to load by user ID');
  }
}

  Future<List<Process>> getByWorkflowId(int userId) async {
  final response = await http.get(Uri.parse('$apiUrl1/get-all-by-workflow-id/$userId'));
  if (response.statusCode == 200) {
    List<dynamic> data = jsonDecode(response.body);
    return data.map((item) => Process.fromJson(item)).toList();
  } else {
    throw Exception('Failed to load by user ID');
  }
}

}