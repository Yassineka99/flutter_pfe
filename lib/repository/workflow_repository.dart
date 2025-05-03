import 'dart:convert';

import '../env.dart';
import '../model/workflow.dart';
import 'package:http/http.dart' as http;
class WorkflowRepository{
   static const String apiUrl1 = '$baseUrl/api/workflow';
  Future<Workflow> createWorkflow(
    String? name,
    int? createdBy
  ) async {
    final response = await http.post(
      Uri.parse('$apiUrl1/create'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'name': name!,
        'role': createdBy!.toString(),
      }),
    );
    if (response.statusCode == 201) {
      return Workflow.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create client.');
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
  final response = await http.get(
    Uri.parse('$apiUrl1/get-all'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
  );

  if (response.statusCode == 200) {
    final List<dynamic> decodedJson = jsonDecode(response.body);
    return decodedJson.map((json) => Workflow.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load workflows.');
  }
}
Future<Workflow> updateSubProcess(Workflow subProcess) async {
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
Future<void> deleteSubProcess(int id) async {
  final response = await http.post(Uri.parse('$apiUrl1/delete/$id'));
  if (response.statusCode != 200) {
    throw Exception('Failed to delete subprocess');
  }
}


}