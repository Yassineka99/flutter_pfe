class Workflow {
  int? id;
  String? name;
  int? createdBy;
  bool isSynced;
  Workflow({this.id, this.name, this.createdBy,this.isSynced=false});
  factory Workflow.fromJson(Map<String, dynamic> json) => Workflow(
        id: json['id'] as int?,
        name: json['name'] as String?,
        createdBy: json['createdBy'] ?? json['created_by'] as int?,
        isSynced:(json['is_synced'] ?? json['isSynced']) ==1 
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'created_by': createdBy,
        'is_synced':isSynced? 1 : 0
        
      };
}
