class Workflow {
  int? id;
  String? name;
  int? createdBy;
  int? product_id;
  int? quantity;
  int? status_id;
  String? image;     
  String? imageType;
  bool isSynced;
  Workflow(
      {this.id,
      this.name,
      this.createdBy,
      this.isSynced = false,
      this.product_id,
      this.quantity,
      this.status_id,
      this.image,
      this.imageType});
  factory Workflow.fromJson(Map<String, dynamic> json) => Workflow(
      id: json['id'] as int?,
      name: json['name'] as String?,
      createdBy: json['createdBy'] ?? json['created_by'] as int?,
      product_id: json['product_id'] ?? json['product_id'] as int?,
      quantity: json['quantity'] ?? json['quantity'] as int?,
      status_id: json['status_id'] ?? json['status_id'] as int?,
       image:json['image'] as String?,
        imageType:json['imageType'] as String?,
      isSynced: (json['is_synced'] ?? json['isSynced']) == 1);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'created_by': createdBy,
        'product_id': product_id,
        'quantity': quantity,
        'image':     image,
        'imageType': imageType,
        'status_id': status_id,
        'is_synced': isSynced ? 1 : 0
      };
}
