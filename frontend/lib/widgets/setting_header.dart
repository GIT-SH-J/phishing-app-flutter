import 'package:flutter/material.dart';

class SettingHeader extends StatelessWidget {
  final String title;
  const SettingHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1976D2),
        ),
      ),
    );
  }
}