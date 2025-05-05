import 'package:flutter/material.dart';

class PasswordInput extends StatefulWidget {
  final String hint;
  final TextEditingController controller;
  final IconData icon;

  const PasswordInput({
    Key? key,
    required this.hint,
    required this.controller,
    required this.icon,
  }) : super(key: key);

  @override
  State<PasswordInput> createState() => _PasswordInputState();
}

class _PasswordInputState extends State<PasswordInput> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFF5F7FA),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: widget.controller,
        obscureText: _obscure,
        cursorHeight: 20,
        cursorRadius: const Radius.circular(10),
        cursorColor: const Color(0xFF78A190),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: widget.hint,
          prefixIcon: Icon(widget.icon, color: const Color(0xFF78A190)),
          suffixIcon: IconButton(
            icon: Icon(
              _obscure ? Icons.visibility_off : Icons.visibility,
              color: const Color(0xFF78A190),
            ),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
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
      ),
    );
  }
}