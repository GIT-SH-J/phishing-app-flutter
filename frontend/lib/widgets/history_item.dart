import 'package:flutter/material.dart';

class HistoryItem extends StatelessWidget {
  final Map<String, dynamic> item;
  const HistoryItem({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item['text'],
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: item['color'].withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              item['label'],
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: item['color'],
              ),
            ),
          ),
        ],
      ),
    );
  }
}