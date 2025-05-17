import 'dart:convert';
import 'package:http/http.dart' as http;
import '../env.dart';
import '../model/product.dart';
import '../services/db_helper.dart';

class ProductRepository {
  static const String apiUrl1 = '$baseUrl/api/product';
final DBHelper _dbHelper = DBHelper();
 Future<Product> getProductById(String id) async {
    try {
      // First try to fetch from server
      final response = await http
          .get(
            Uri.parse('$apiUrl1/getProductById/$id'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
          )
          .timeout(const Duration(milliseconds: 1000));

      if (response.statusCode == 200) {
        final serverProduct = Product.fromJson(jsonDecode(response.body));
        
        // Save to local database
        await _dbHelper.insertData('''
          INSERT OR REPLACE INTO product
            (id, name, status_id, modelFileName, is_synced)
          VALUES (?, ?, ?, ?, 1)
        ''', [
          serverProduct.id,
          serverProduct.name,
          serverProduct.status_id,
          serverProduct.modelFileName
        ]);
        
        return serverProduct;
      }
    } catch (e) {
      // If network fails, try to get from local database
      final List<Map<String, dynamic>> rows = await _dbHelper.readData(
        'SELECT * FROM product WHERE id = ?', 
        [id]
      );
      
      if (rows.isNotEmpty) {
        return Product.fromJson(rows.first);
      }
    }
    throw Exception('Failed to load product');
  }
  
}
