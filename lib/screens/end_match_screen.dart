import 'dart:math';
import 'package:flutter/material.dart';
import 'payment_calculator_screen.dart';

class EndMatchScreen extends StatelessWidget {
  final int pointsTeam1;
  final int pointsTeam2;
  final int pointsTeam3;
  final String mvpEquipo1;
  final String mvpEquipo2;
  final String mvpEquipo3;

  // NUEVO: cantidad total de jugadores que participaron.
  final int totalPlayers;

  EndMatchScreen({
    required this.pointsTeam1,
    required this.pointsTeam2,
    required this.pointsTeam3,
    required this.mvpEquipo1,
    required this.mvpEquipo2,
    required this.mvpEquipo3,
    required this.totalPlayers, // lo recibimos desde MatchScreen
  });

  @override
  Widget build(BuildContext context) {
    // Determinar el máximo de puntos
    int maxPoints = [pointsTeam1, pointsTeam2, pointsTeam3].reduce(max);

    // Crear una lista con los números de equipo que alcanzaron maxPoints
    List<int> winningTeams = [];
    if (pointsTeam1 == maxPoints) winningTeams.add(1);
    if (pointsTeam2 == maxPoints) winningTeams.add(2);
    if (pointsTeam3 == maxPoints) winningTeams.add(3);

    String resultText;
    if (winningTeams.length == 1) {
      resultText = "¡Equipo ${winningTeams.first} gana el encuentro!";
    } else {
      // Si hay empate, listamos los equipos
      resultText = "Empate entre los equipos: " + winningTeams.join(" y ");
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          " ⚽ Resultado Final ⚽",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              resultText,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              "Puntos Acumulados:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text("Equipo 1: $pointsTeam1", style: TextStyle(fontSize: 20)),
            Text("Equipo 2: $pointsTeam2", style: TextStyle(fontSize: 20)),
            Text("Equipo 3: $pointsTeam3", style: TextStyle(fontSize: 20)),
            SizedBox(height: 20),
            Text(
              "MVP de cada equipo:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text("Equipo 1: $mvpEquipo1", style: TextStyle(fontSize: 18)),
            Text("Equipo 2: $mvpEquipo2", style: TextStyle(fontSize: 18)),
            Text("Equipo 3: $mvpEquipo3", style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),

            // BOTÓN NUEVO: para ir a la pantalla de Pagos
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => PaymentCalculatorScreen(
                          initialPlayers: totalPlayers,
                          fromEndMatch: true, // Bloquea la edición

                          // Si hay un solo equipo ganador, pasamos winnersCount = 1
                          // Si hay varios, es un empate => winnersCount = winningTeams.length
                          /*  winnersCount: winningTeams.length, */
                        ),
                  ),
                );
              },

              child: Text("Ir a Pagos"),
            ),

            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Regresamos al inicio
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
