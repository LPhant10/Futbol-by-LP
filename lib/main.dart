import 'package:flutter/material.dart';
import 'screens/team_generator_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Quita el banner de debug
      title: 'Team Generator',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: TeamGeneratorPage(), // Pantalla principal de generación de equipos
    );
  }
}
