import 'package:flutter/material.dart';

class Button extends StatefulWidget {
  final String label;
  final VoidCallback press;
  final Color color; // <-- Store color

  const Button({
    super.key,
    required this.label,
    required this.press,
    required this.color, // <-- Required here too
  });

  @override
  _ButtonState createState() => _ButtonState();
}

class _ButtonState extends State<Button> {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      width: size.width * .82,
      height: 55,
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
      decoration: BoxDecoration(
        color: widget.color, // <-- Use the passed color here
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: TextButton(
        onPressed: widget.press,
        child: Text(
          widget.label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
