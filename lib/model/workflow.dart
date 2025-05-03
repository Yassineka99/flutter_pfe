class Workflow {
  int? id;
  String? name;
  int? createdBy;
  Workflow({this.id, this.name, this.createdBy});
  factory Workflow.fromJson(Map<String, dynamic> json) => Workflow(
        id: json['id'] as int?,
        name: json['name'] as String?,
        createdBy: json['created_by'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': createdBy,
      };
}
