import 'package:flutter/material.dart';

class EndMatchScreen extends StatelessWidget {
  final int winner;
  final int pointsTeam1;
  final int pointsTeam2;
  final int pointsTeam3;
  final String mvpEquipo1;
  final String mvpEquipo2;
  final String mvpEquipo3;

  EndMatchScreen({
    required this.winner,
    required this.pointsTeam1,
    required this.pointsTeam2,
    required this.pointsTeam3,
    required this.mvpEquipo1,
    required this.mvpEquipo2,
    required this.mvpEquipo3,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Resultado Final"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "¡Equipo ${winner + 1} gana el encuentro!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text("Puntos Acumulados:",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text("Equipo 1: $pointsTeam1", style: TextStyle(fontSize: 20)),
            Text("Equipo 2: $pointsTeam2", style: TextStyle(fontSize: 20)),
            Text("Equipo 3: $pointsTeam3", style: TextStyle(fontSize: 20)),
            SizedBox(height: 20),
            Text("MVP de cada equipo:",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text("Equipo 1: $mvpEquipo1", style: TextStyle(fontSize: 18)),
            Text("Equipo 2: $mvpEquipo2", style: TextStyle(fontSize: 18)),
            Text("Equipo 3: $mvpEquipo3", style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Volver al Inicio"),
            ),
          ],
        ),
      ),
    );
  }
}
