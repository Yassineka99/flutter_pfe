class Role {
  int? id;
  String? message;
  Role({this.id, this.message});

  factory Role.fromJson(Map<String, dynamic> json) => Role(
        id: json['id'] as int?,
        message: json['message'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'message': message,
      };
}