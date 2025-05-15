// services/openrouter_ai_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../env.dart';

class OpenRouterAI {
  final String apiKey = '$API_KEY'; 

  Future<String> sendMessage(List<Map<String, String>> conversation) async {
    final url = Uri.parse('https://openrouter.ai/api/v1/chat/completions');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'yourapp://chatbot', 
      },
      body: jsonEncode({
        "model": "mistralai/mistral-7b-instruct",
        "messages": conversation,
        "temperature": 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      print('API Error: ${response.body}');
      return "Sorry, something went wrong.";
    }
  }
}
