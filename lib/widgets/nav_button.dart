// lib/widgets/nav_button.dart
// Thin wrapper kept for backwards compatibility.
// New code should use AppNavButton from app_components.dart directly.
import 'package:flutter/material.dart';
import 'app_components.dart';
import '../config/app_theme.dart';

class NavButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color buttonColor;
  final VoidCallback onPressed;

  const NavButton({
    super.key,
    required this.title,
    required this.icon,
    required this.buttonColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppNavButton(
      title: title,
      icon: icon,
      accentColor: buttonColor,
      onPressed: onPressed,
    );
  }
}