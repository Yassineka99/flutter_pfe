import 'dart:core';

class Notification {
  int? id;
  int? userToNotify;
  String? message;
  Notification({this.id, this.userToNotify, this.message});

  factory Notification.fromJson(Map<String, dynamic> json) => Notification(
        id: json['id'] as int?,
        userToNotify: json['user_to_notify'] as int?,
        message: json['message'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_to_notify': userToNotify,
        'message': message,
      };
}
