import 'package:flutter/material.dart';
import 'app_state.dart';
import 'screens/access_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    appState.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    appState.removeListener(() => setState(() {}));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '스미싱 탐지기',
      debugShowCheckedModeBanner: false,
      home: const AccessScreen(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1976D2),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1976D2),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(appState.fontSize)),
          child: child!,
        );
      },
    );
  }
}
