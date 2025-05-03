import 'dart:core';

class User {
  int? id;
  String? name;
  String? email;
  String? phone;
  String? password;
  int? role;
  String? image;     
  String? imageType;
  
  User({this.id, this.name, this.email, this.phone, this.password, this.role,    this.image,
    this.imageType,});

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as int?,
        name: json['name'] as String?,
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        password: json['password'] as String?,
        role: json['role'] as int?,
        image:json['image'] as String?,
        imageType:json['imageType'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'role': role,
        'image':     image,
        'imageType': imageType,
      };
}
