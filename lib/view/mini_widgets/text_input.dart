import 'package:flutter/material.dart';

class TextInput extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  const TextInput({
    Key? key,
    required this.hint,
    required this.controller
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xFFF3F1F1),
      ),
      margin: const EdgeInsets.only(left: 20, right: 20, top: 20),
      child: TextField(
        controller: controller,
        cursorHeight: 20,
        cursorRadius: Radius.circular(10),
        cursorColor: Color(0xFFC2BDBD),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(
            fontFamily: 'BrandonGrotesque',
            fontSize: 16,
            color: Color(0xFFC2BDBD),
          ),
          contentPadding: const EdgeInsets.only(left: 20),
        ),
        style: const TextStyle(
          fontFamily: 'BrandonGrotesque',
          fontSize: 16,
          color: Color(0xFFC2BDBD),
        ),
      ),
    );
  }
}
