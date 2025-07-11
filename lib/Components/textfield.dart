import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 👈 Required for TextInputFormatter

class InputField extends StatelessWidget {
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final bool isPassword;
  final String? Function(String?)? validator;
  final Color iconColor;
  final List<TextInputFormatter>? inputFormatters; // ✅ Add this line

  const InputField({
    super.key,
    required this.hint,
    required this.icon,
    required this.controller,
    this.isPassword = false,
    this.validator,
    this.iconColor = const Color(0xFF101D33),
    this.inputFormatters, // ✅ Add this line
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        validator: validator,
        inputFormatters: inputFormatters, // ✅ Pass to TextFormField
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: iconColor),
          prefixIcon: Icon(icon, color: iconColor),
          filled: true,
          fillColor: const Color(0xFFE2E6ED),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: iconColor, width: 3),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.blue, width: 3),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: iconColor, width: 3),
          ),
        ),
      ),
    );
  }
}
