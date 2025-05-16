class Workflow {
  int? id;
  String? name;
  int? createdBy;
  int? product_id;
  int? quantity;
  bool isSynced;
  Workflow({this.id, this.name, this.createdBy, this.isSynced = false , this.product_id , this.quantity});
  factory Workflow.fromJson(Map<String, dynamic> json) => Workflow(
      id: json['id'] as int?,
      name: json['name'] as String?,
      createdBy: json['createdBy'] ?? json['created_by'] as int?,
      product_id: json['product_id'] ?? json['product_id'] as int?,
      quantity: json['quantity'] ?? json['quantity'] as int?,
      isSynced: (json['is_synced'] ?? json['isSynced']) == 1);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'created_by': createdBy,
        'product_id': product_id,
        'quantity': quantity,
        'is_synced': isSynced ? 1 : 0
      };
}
