import 'package:flutter/material.dart';

class TextInput extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final IconData icon;

  const TextInput({
    super.key,
    required this.hint,
    required this.controller,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFFF8F5F3),
        border: Border.all(
          color: const Color(0xFFB5927F).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: TextField(
        controller: controller,
        cursorHeight: 22,
        cursorRadius: const Radius.circular(10),
        cursorColor: const Color(0xFFA17A69),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          prefixIcon: Icon(
            icon, 
            color: const Color(0xFFA17A69).withOpacity(0.8),
          ),
          hintStyle: TextStyle(
            fontFamily: 'BrandonGrotesque',
            fontSize: 16,
            color: const Color(0xFF6B7280).withOpacity(0.6),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 20,
          ),
        ),
        style: const TextStyle(
          fontFamily: 'BrandonGrotesque',
          fontSize: 16,
          color: Color(0xFF4e3a31),
        ),
      ),
    );
  }
}