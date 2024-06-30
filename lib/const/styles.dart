import 'package:flutter/material.dart';
import 'package:newproject/const/colors.dart';

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
    super.key,
    required this.controller,
    required this.labelText,
    required this.icon,
    this.obscureText = false, // Default value is false
    this.keyboardType =
        TextInputType.text, // Default value is TextInputType.text
  });

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

class SearchTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final VoidCallback onPressed;

  const SearchTextField({
    Key? key,
    required this.controller,
    required this.labelText,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(
          color: primegreen,
          fontWeight: FontWeight.w500,
        ),
        suffixIcon: IconButton(
          icon: const Icon(
            Icons.search,
            color: primegreen,
          ),
          onPressed: onPressed,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25.0),
          borderSide: const BorderSide(
            color: primegreen,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25.0),
          borderSide: const BorderSide(color: primegreen),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 15.0,
          horizontal: 20.0,
        ),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      style: const TextStyle(
        fontSize: 16.0,
        color: Colors.black,
      ),
    );
  }
}

class DateOfBirthPicker extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onTap;

  const DateOfBirthPicker({
    super.key,
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AbsorbPointer(
        child: TextField(
          controller: controller,
          decoration: const InputDecoration(
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

class GradientText extends StatelessWidget {
  const GradientText(
    this.text, {
    super.key,
    required this.gradient,
    this.style,
  });

  final String text;
  final TextStyle? style;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(text, style: style),
    );
  }
}
