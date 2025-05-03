import 'dart:core';

class User {
  int? id;
  String? name;
  String? email;
  String? phone;
  String? password;
  int? role;
  User({this.id, this.name, this.email, this.phone, this.password, this.role});

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as int?,
        name: json['name'] as String?,
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        password: json['password'] as String?,
        role: json['role'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'role': role,
      };
}
