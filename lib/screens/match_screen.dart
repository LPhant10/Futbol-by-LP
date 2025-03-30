// Aquí se implementa la pantalla del partido con cronómetro, goles, puntos y reproducción de audio

import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class MatchScreen extends StatefulWidget {
  @override
  _MatchScreenState createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  int timeLeft = 600; // 10 minutos en segundos
  Timer? timer;

  int goalsTeam1 = 0;
  int goalsTeam2 = 0;
  int goalsTeam3 = 0;

  int pointsTeam1 = 0;
  int pointsTeam2 = 0;
  int pointsTeam3 = 0;

  Future<void> playSound(String assetName) async {
    final player = AudioPlayer();
    await player.play(AssetSource(assetName));
  }

  void startTimer() {
    // Reproducir sonido al iniciar el partido
    playSound('silvato.mp3');
    timer?.cancel();
    setState(() {
      timeLeft = 600;
    });
    timer = Timer.periodic(Duration(seconds: 1), (t) {
      if (timeLeft > 0) {
        setState(() {
          timeLeft--;
        });
      } else {
        endMatch();
      }
    });
  }

  void endMatch() {
    timer?.cancel();
    // Reproducir sonido al finalizar el partido
    playSound('silvato.mp3');

    int winner = 0; // 1 para Equipo1, 2 para Equipo2, 3 para Equipo3; 0 para empate
    if (goalsTeam1 >= 2 || goalsTeam2 >= 2 || goalsTeam3 >= 2) {
      int maxGoals = max(goalsTeam1, max(goalsTeam2, goalsTeam3));
      if (goalsTeam1 == maxGoals)
        winner = 1;
      else if (goalsTeam2 == maxGoals)
        winner = 2;
      else if (goalsTeam3 == maxGoals)
        winner = 3;
    } else {
      int maxGoals = max(goalsTeam1, max(goalsTeam2, goalsTeam3));
      List<int> winners = [];
      if (goalsTeam1 == maxGoals) winners.add(1);
      if (goalsTeam2 == maxGoals) winners.add(2);
      if (goalsTeam3 == maxGoals) winners.add(3);
      if (winners.length == 1) winner = winners.first;
    }

    String message;
    if (winner == 0) {
      message = "Empate. No se otorga punto.";
    } else {
      message = "¡Equipo $winner gana y suma 1 punto!";
      if (winner == 1)
        pointsTeam1++;
      else if (winner == 2)
        pointsTeam2++;
      else if (winner == 3)
        pointsTeam3++;
    }

    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text("Fin del partido"),
              content: Text(message),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      resetMatch();
                    },
                    child: Text("OK"))
              ],
            ));
  }

  void resetMatch() {
    setState(() {
      timeLeft = 600;
      goalsTeam1 = 0;
      goalsTeam2 = 0;
      goalsTeam3 = 0;
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String minutes = (timeLeft ~/ 60).toString().padLeft(2, '0');
    String seconds = (timeLeft % 60).toString().padLeft(2, '0');
    return Scaffold(
      appBar: AppBar(
        title: Text("⚽ JUGANDO ⚽" ,style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Tiempo restante: $minutes:$seconds",
                style: TextStyle(fontSize: 32)),
            SizedBox(height: 20),
            ElevatedButton(
                onPressed: startTimer, child: Text("Iniciar Partido")),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text("Equipo 1", style: TextStyle(fontSize: 20)),
                    Text("Goles: $goalsTeam1", style: TextStyle(fontSize: 20)),
                    ElevatedButton(
                        onPressed: () {
                          setState(() {
                            goalsTeam1++;
                          });
                          if (goalsTeam1 >= 2) endMatch();
                        },
                        child: Text("+1 GOL"))
                  ],
                ),
                Column(
                  children: [
                    Text("Equipo 2", style: TextStyle(fontSize: 20)),
                    Text("Goles: $goalsTeam2", style: TextStyle(fontSize: 20)),
                    ElevatedButton(
                        onPressed: () {
                          setState(() {
                            goalsTeam2++;
                          });
                          if (goalsTeam2 >= 2) endMatch();
                        },
                        child: Text("+1 GOL"))
                  ],
                ),
                Column(
                  children: [
                    Text("Equipo 3", style: TextStyle(fontSize: 20)),
                    Text("Goles: $goalsTeam3", style: TextStyle(fontSize: 20)),
                    ElevatedButton(
                        onPressed: () {
                          setState(() {
                            goalsTeam3++;
                          });
                          if (goalsTeam3 >= 2) endMatch();
                        },
                        child: Text("+1 GOL"))
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            Text("Puntos:", style: TextStyle(fontSize: 20)),
            Text("Equipo 1: $pointsTeam1", style: TextStyle(fontSize: 20)),
            Text("Equipo 2: $pointsTeam2", style: TextStyle(fontSize: 20)),
            Text("Equipo 3: $pointsTeam3", style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
