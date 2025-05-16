import 'dart:convert';
import 'package:http/http.dart' as http;
import '../env.dart';
import '../model/product.dart';

class ProductRepository {
  static const String apiUrl1 = '$baseUrl/api/product';


        Future<Product> getProductById(String id) async {
    final response = await http.get(
      Uri.parse('$apiUrl1/getProductById/$id'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    if (response.statusCode == 200) {
      return Product.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load client.');
    }
  }
}
