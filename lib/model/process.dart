class Process {
  int? id;
  String? name;
  int? workflowId;
  int? statusId;
  int? order;
  int? createdBy;
  int? updatedBy;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? finishedAt;

  Process(
      {this.id,
      this.name,
      this.createdBy,
      this.statusId,
      this.order,
      this.updatedBy,
      this.workflowId,
      this.createdAt,
      this.finishedAt,
      this.updatedAt});
  factory Process.fromJson(Map<String, dynamic> json) => Process(
        id: json['id'] as int?,
        name: json['name'] as String?,
        createdBy: json['created_by'] as int?,
        updatedBy: json['updated_by'] as int?,
        order: json['order'] as int?,
        workflowId: json['workflow_id'] as int?,
        statusId: json['status_id'] as int?,
        createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
        finishedAt: json['finished_at'] != null ? DateTime.tryParse(json['finished_at'] as String) : null,
        updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'created_by': createdBy,
        'updated_by': id,
        'order': order,
        'workflow_id': workflowId,
        'status_id': statusId,
        'finished_at': finishedAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'created_at': createdAt?.toIso8601String(),
      };
}
