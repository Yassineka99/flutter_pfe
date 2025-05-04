import 'dart:core';

class Notification {
  int? id;
  int? userToNotify;
  String? message;
  int? visibility;
  Notification({this.id, this.userToNotify, this.message,this.visibility});

  factory Notification.fromJson(Map<String, dynamic> json) => Notification(
        id: json['id'] as int?,
        userToNotify: json['user_to_notify'] as int?,
        message: json['message'] as String?,
        visibility:json['visiblity'] as int?
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_to_notify': userToNotify,
        'message': message,
        'visiblity':visibility
      };
}
