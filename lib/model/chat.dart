class Chat {
  int? id;
  String? message;
  int? from_user;
  int? to_user;
  DateTime? from_user_date;

  Chat({this.id, this.message, this.from_user, this.to_user,this.from_user_date});

  factory Chat.fromJson(Map<String, dynamic> json) => Chat(
        id: json['id'] as int?,
        message: json['message'] as String?,
        from_user: json['from_user'] as int?,
        to_user: json['to_user'] as int?,
        from_user_date: json['from_user_date'] == null 
          ? null 
          : DateTime.tryParse(json['from_user_date'].toString()),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'message': message,
        'from_user': from_user,
        'to_user': to_user,
        'from_user_date': from_user_date
      };
}
