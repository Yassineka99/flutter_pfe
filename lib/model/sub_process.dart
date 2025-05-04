class SubProcess {
  int? id;
  String? name;
  int? processId;
  int? statusId;
  DateTime? createdAt;
  DateTime? finishedAt;
  String? message;
  int? assignedTo;
  int? createdBy;

  SubProcess(
      {this.id,
      this.name,
      this.statusId,
      this.processId,
      this.createdAt,
      this.finishedAt,
      this.message,
      this.assignedTo,
      this.createdBy});
  factory SubProcess.fromJson(Map<String, dynamic> json) => SubProcess(
        id: json['id'] as int?,
        name: json['name'] as String?,
        processId: json['process_id'] as int?,
        statusId: json['status'] as int?,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
        finishedAt: json['finished_at'] != null
            ? DateTime.tryParse(json['finished_at'] as String)
            : null,
        message: json['message'] as String?,
        assignedTo: json['assigned_to'] as int?,
        createdBy: json['created_by'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'process_id': processId,
        'status_id': statusId,
        'finished_at': finishedAt,
        'created_at': createdAt,
        'message': message,
        'assigned_to': assignedTo,
        'created_by': createdBy,
      };
}
