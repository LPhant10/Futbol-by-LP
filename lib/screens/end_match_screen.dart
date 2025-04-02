import 'dart:math';
import 'package:flutter/material.dart';
import 'payment_calculator_screen.dart';

class EndMatchScreen extends StatelessWidget {
  final int pointsTeam1;
  final int pointsTeam2;
  final int pointsTeam3;
  final int pointsTeam4;

  final String mvpEquipo1;
  final String mvpEquipo2;
  final String mvpEquipo3;
  final String mvpEquipo4;

  final int totalPlayers;
  final List<String> allPlayers;

  EndMatchScreen({
    required this.pointsTeam1,
    required this.pointsTeam2,
    required this.pointsTeam3,
    required this.pointsTeam4,
    required this.mvpEquipo1,
    required this.mvpEquipo2,
    required this.mvpEquipo3,
    required this.mvpEquipo4,
    required this.totalPlayers,
    required this.allPlayers,
  });

  @override
  Widget build(BuildContext context) {
    // Crear listas dinámicas
    List<int> puntos = [pointsTeam1, pointsTeam2, pointsTeam3, pointsTeam4];
    List<String> mvps = [mvpEquipo1, mvpEquipo2, mvpEquipo3, mvpEquipo4];

    // Solo mostrar los equipos que jugaron (que tienen MVP)
    List<int> equiposJugados = [];
    for (int i = 0; i < mvps.length; i++) {
      if (mvps[i] != "Ninguno") {
        equiposJugados.add(i); // índice 0 = Equipo 1
      }
    }

    // Determinar los ganadores
    int maxPoints = equiposJugados.isNotEmpty
        ? equiposJugados.map((i) => puntos[i]).reduce(max)
        : 0;

    List<int> winningTeams = equiposJugados
        .where((i) => puntos[i] == maxPoints)
        .map((i) => i + 1)
        .toList();

    String resultText = (winningTeams.length == 1)
        ? "¡Equipo ${winningTeams.first} gana el encuentro!"
        : "Empate entre los equipos: ${winningTeams.join(" y ")}";

    int winnersCount = (winningTeams.length == 1) ? 1 : winningTeams.length;

    return Scaffold(
      appBar: AppBar(
        title: Text("⚽ Resultado Final ⚽", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(resultText, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),

            Text("Puntos Acumulados:", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ...equiposJugados.map((index) => Text(
              "Equipo ${index + 1}: ${puntos[index]}",
              style: TextStyle(fontSize: 20),
            )),

            SizedBox(height: 20),

            Text("MVP de cada equipo:", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ...equiposJugados.map((index) => Text(
              "Equipo ${index + 1}: ${mvps[index]}",
              style: TextStyle(fontSize: 18),
            )),

            SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentCalculatorScreen(
                      initialPlayers: totalPlayers,
                      fromEndMatch: true,
                      winnersCount: winnersCount,
                      allPlayers: allPlayers,
                    ),
                  ),
                );
              },
              child: Text("Ir a Pagos"),
            ),

            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Volver al Inicio"),
            ),
          ],
        ),
      ),
    );
  }
}
