import 'package:flutter/material.dart';

class CyberCard extends StatefulWidget {
  final Widget child;
  final bool enableHover;
  const CyberCard({super.key, required this.child, required this.enableHover});

  @override
  State<CyberCard> createState() => _CyberCardState();
}

class _CyberCardState extends State<CyberCard> {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
