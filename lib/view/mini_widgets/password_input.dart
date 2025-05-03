import 'package:flutter/material.dart';

class PasswordInput extends StatefulWidget {
  final String hint;
  final TextEditingController controller;

  const PasswordInput({
    Key? key,
    required this.hint,
    required this.controller,
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
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xFFF3F1F1),
      ),
      margin: const EdgeInsets.only(left: 20, right: 20, top: 20),
      child: TextField(
        controller: widget.controller,
        obscureText: _obscure,
        cursorHeight: 20,
        cursorRadius: Radius.circular(10),
        cursorColor: const Color(0xFFC2BDBD),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: widget.hint,
          hintStyle: const TextStyle(
            fontFamily: 'BrandonGrotesque',
            fontSize: 16,
            color: Color(0xFFC2BDBD),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20,vertical: 15),
          suffixIcon: IconButton(
            icon: Icon(
              _obscure ? Icons.visibility_off : Icons.visibility,
              color: const Color(0xFFC2BDBD),
            ),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
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
