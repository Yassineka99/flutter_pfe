class Chat {
  int? id;
  String? message;
  int? from_user;
  int? to_user;

  Chat({this.id, this.message, this.from_user, this.to_user});


factory Chat.fromJson(Map<String, dynamic> json) => Chat(
        id: json['id'] as int?,
        message: json['message'] as String?,
        from_user: json['from_user'] as int?,
        to_user: json['to_user'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'message': message,
        'from_user':from_user,
        'to_user':to_user
      };


}
