// lib/screens/team_generator_page.dart
import 'package:flutter/material.dart';
import 'players_generate_screen.dart';
import 'match_screen.dart';
import 'generated_teams_screen.dart';
import 'payment_calculator_screen.dart.dart';

class TeamGeneratorPage extends StatelessWidget {
  const TeamGeneratorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("⚽ Team Generator by LP ⚽" , style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
      ),
      body: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PlayersGenerateScreen()),
                );
              },
              child: Text("Jugadores"),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => GeneratedTeamsScreen()),
                );
              },
              child: Text("Ver Equipos Guardados"),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MatchScreen()),
                );
              },
              child: Text("Ir a Partido"),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => PaymentCalculatorScreen()),
                );
              },
              child: Text("Pagos"),
            ),
          ],
        ),
      ),
    );
  }
}
