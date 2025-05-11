import 'dart:convert';
import 'package:http/http.dart' as http;
import '../env.dart';
import '../model/chat.dart';

class ChatRepository {
  static const String apiUrl1 = '$baseUrl/api/chat';
  Future<Chat> createMessage(
      String? message, int? from_user, int? to_user) async {
    final response = await http.post(
      Uri.parse('$apiUrl1/create'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'message': message!,
        'from_user': from_user!.toString(),
        'to_user': to_user!.toString(),
      }),
    );
    if (response.statusCode == 201) {
      return Chat.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create client.');
    }
  }

    Future<List<Chat>> GetAllbySenderid(int id) async {
    final response = await http.get(
      Uri.parse('$apiUrl1/get-all-by-sender-id/$id'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> decoded = jsonDecode(response.body);
      return decoded.map((json) => Chat.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load client.');
    }
  }

      Future<List<Chat>> GetAllbyRecieverid(int id) async {
    final response = await http.get(
      Uri.parse('$apiUrl1/get-all-by-reciever-id/$id'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> decoded = jsonDecode(response.body);
      return decoded.map((json) => Chat.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load client.');
    }
  }

  Future<Chat> updateSubProcess(Chat chat) async {
  final response = await http.post(
    Uri.parse('$apiUrl1/update'),
    headers: {'Content-Type': 'application/json; charset=UTF-8'},
    body: jsonEncode(chat.toJson()),
  );
  if (response.statusCode == 200) {
    return Chat.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to update subprocess');
  }
}


      Future<List<Chat>> GetAllbySenderAndRecieverid(int sender , int reciever) async {
    final response = await http.get(
      Uri.parse('$apiUrl1/get-all-by-sender-and-reciever-id/$sender/$reciever'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> decoded = jsonDecode(response.body);
      return decoded.map((json) => Chat.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load client.');
    }
  }
}
