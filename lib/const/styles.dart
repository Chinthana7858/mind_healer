import 'package:flutter/material.dart';

class ScreenSize {
  double width(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  double height(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }
}





// Define a reusable custom text field widget
class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.labelText,
    required this.icon,
    this.obscureText = false, // Default value is false
    this.keyboardType = TextInputType.text, // Default value is TextInputType.text
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(
          color: Colors.teal,
          fontWeight: FontWeight.w400,
        ),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(30.0)),
          borderSide: BorderSide(color: Colors.teal),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(30.0)),
          borderSide: BorderSide(color: Colors.teal, width: 1.0),
        ),
        prefixIcon: Icon(icon, color: Colors.teal),
        filled: true,
        fillColor: Colors.white,
      ),
      keyboardType: keyboardType, // Use the keyboardType parameter
      obscureText: obscureText, // Use the obscureText parameter
    );
  }
}


class DateOfBirthPicker extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onTap;

  const DateOfBirthPicker({
    Key? key,
    required this.controller,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AbsorbPointer(
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Date of Birth',
            labelStyle: TextStyle(
              color: Colors.teal,
              fontWeight: FontWeight.w400,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(30.0)),
              borderSide: BorderSide(color: Colors.teal),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(30.0)),
              borderSide: BorderSide(color: Colors.teal, width: 1.0),
            ),
            filled: true,
            fillColor: Colors.white,
            prefixIcon: Icon(Icons.calendar_today, color: Colors.teal),
          ),
        ),
      ),
    );
  }
}