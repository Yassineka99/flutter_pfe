  import 'package:front/model/product.dart';
import 'package:front/repository/product_repository.dart';

class ProductViewModel
  {
  final ProductRepository productRepository = ProductRepository();
  Product? product;
  Future<Product?> getProductById(String id) async {
    try {
      product = await productRepository.getProductById(id);
      if (product != null) {
        return product!;
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching client: $e');
    }
  }}