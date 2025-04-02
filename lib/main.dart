// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/team_generator_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Quita el banner de debug
      title: 'Team Generator',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: TeamGeneratorPage(),
    );
  }
}
