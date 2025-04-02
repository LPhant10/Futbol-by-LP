import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sorteo_lp/screens/match_screen.dart';
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

  const EndMatchScreen({
    super.key,
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
    List<int> puntos = [pointsTeam1, pointsTeam2, pointsTeam3, pointsTeam4];
    List<String> mvps = [mvpEquipo1, mvpEquipo2, mvpEquipo3, mvpEquipo4];

    List<int> equiposJugados = [];
    for (int i = 0; i < mvps.length; i++) {
      if (mvps[i] != "Ninguno") {
        equiposJugados.add(i);
      }
    }

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

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: Image.asset("assets/fgame.jpg", fit: BoxFit.cover),
            ),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Cabecera con botón de regreso + título centrado
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
  icon: Icon(Icons.arrow_back, color: Colors.white),
  onPressed: () {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const MatchScreen(),
      ),
    );
  },
),

                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.sports_soccer, color: Colors.white),
                                SizedBox(width: 6),
                                Text(
                                  "RESULTADO FINAL",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Icon(Icons.sports_soccer, color: Colors.white),
                              ],
                            ),
                          ),
                          SizedBox(width: 48), // Espacio para equilibrar
                        ],
                      ),
                    ),

                    // Contenido
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                              color: Colors.white.withOpacity(0.5),
                            ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(resultText,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white
                              )),
                          SizedBox(height: 16),

                          Text("Puntos Acumulados:",
                              style: TextStyle(color: Colors.white,
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          ...equiposJugados.map((index) => Text(
                                "Equipo ${index + 1}: ${puntos[index]}",
                                style: TextStyle(fontSize: 18,color: Colors.white),
                              )),

                          SizedBox(height: 16),

                          Text("MVP de cada equipo:",
                              style: TextStyle(color: Colors.white,
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          ...equiposJugados.map((index) => Text(
                                "Equipo ${index + 1}: ${mvps[index]}",
                                style: TextStyle(fontSize: 16,color: Colors.white),
                              )),

                          SizedBox(height: 20),

                          Center(
                            child: ElevatedButton(
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
                          ),

                          SizedBox(height: 12),
                          Center(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text("Volver al Inicio"),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
