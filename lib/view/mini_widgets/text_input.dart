import 'package:flutter/material.dart';

class TextInput extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final IconData icon;

  const TextInput({
    Key? key,
    required this.hint,
    required this.controller,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFF5F7FA),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        cursorHeight: 20,
        cursorRadius: const Radius.circular(10),
        cursorColor: const Color(0xFF78A190),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF78A190)),
          hintStyle: const TextStyle(
            fontFamily: 'BrandonGrotesque',
            fontSize: 16,
            color: Color(0xFF6B7280),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
        ),
        style: const TextStyle(
          fontFamily: 'BrandonGrotesque',
          fontSize: 16,
          color: Color(0xFF28445C),
        ),
    )
    );
  }
}