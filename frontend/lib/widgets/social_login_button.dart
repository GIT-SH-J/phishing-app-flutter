import 'package:flutter/material.dart';

class SocialLoginButton extends StatelessWidget {
  final Color color;
  final Color textColor;
  final IconData icon;
  final Color iconColor;
  final String text;
  final VoidCallback onTap;
  final bool hasBorder;

  const SocialLoginButton({
    super.key,
    required this.color,
    required this.textColor,
    required this.icon,
    required this.iconColor,
    required this.text,
    required this.onTap,
    this.hasBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: hasBorder ? 0 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: hasBorder
                ? const BorderSide(color: Color(0xFFE0E0E0))
                : BorderSide.none,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}