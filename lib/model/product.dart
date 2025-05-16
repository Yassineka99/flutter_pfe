class Product {
  int? id;
  String? name;
  int? status_id;
  String? modelFileName;
  Product({this.id, this.name, this.status_id, this.modelFileName});
  
  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as int?,
        name: json['name'] as String?,
        status_id: json['status_id'] ?? json['status_id'] as int?,
        modelFileName: json['modelFileName']as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'status_id': status_id,
        'modelFileName': modelFileName,
      };
}
