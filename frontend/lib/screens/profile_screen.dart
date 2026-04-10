import 'package:flutter/material.dart';
import '../app_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '내 정보',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            const CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFF1976D2),
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              appState.userName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const ListTile(
              leading: Icon(Icons.history, size: 28),
              title: Text('검사 기록', style: TextStyle(fontSize: 18)),
              trailing: Text('3건', style: TextStyle(fontSize: 16)),
            ),
            const ListTile(
              leading: Icon(Icons.shield_outlined, size: 28),
              title: Text('차단된 위험', style: TextStyle(fontSize: 18)),
              trailing: Text(
                '1건',
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}