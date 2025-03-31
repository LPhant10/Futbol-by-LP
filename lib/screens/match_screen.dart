import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../models/player.dart';
import '../models/team.dart';
import '../services/team_storage_service.dart';
import 'end_match_screen.dart';

class MatchScreen extends StatefulWidget {
  @override
  _MatchScreenState createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  int timeLeft = 10; // 600 minutos en segundos
  Timer? timer;
  bool isFlashMode = true;
  int matchCount = 0;

  List<Team> teams = [];
  // Los partidos se interpretan así:
  // [0,1] → Partido base: Equipo 1 vs Equipo 2
  // [0,2] → Equipo 1 vs Equipo 3
  // [1,2] → Equipo 2 vs Equipo 3
  List<int> currentMatch = [0, 1];

  int pointsTeam1 = 0;
  int pointsTeam2 = 0;
  int pointsTeam3 = 0;

  Map<int, int> goalsByPlayer = {};
  Map<int, int> overallGoalsByPlayer = {};

  // Para preservar el ganador de la última base (opcional)
  int? lastBaseWinner;

  @override
  void initState() {
    super.initState();
    _loadGeneratedTeams();
  }

  Future<void> _loadGeneratedTeams() async {
    final result = await TeamStorageService.loadTeams();
    if (result["teams"] != null && (result["teams"] as List).isNotEmpty) {
      teams = List<Team>.from(result["teams"]);
    } else {
      teams = [];
    }
    for (var team in teams) {
      for (var player in team.players) {
        goalsByPlayer[player.id] = 0;
        overallGoalsByPlayer[player.id] = 0;
      }
    }
    setState(() {});
  }

  // Retorna true si currentMatch contiene los equipos 0 y 1 (sin importar el orden)
  bool isBaseMatch() {
    return currentMatch.toSet().containsAll({0, 1});
  }

  // Para partidos base, normalizamos el orden a [0,1].
  void normalizeBaseMatch() {
    if (isBaseMatch()) currentMatch.sort();
  }

  // Si el ganador es 0 o 1, el siguiente rival es siempre 2.
  // Para el Equipo 3 (índice 2): se asigna según el partido actual.
  int chooseNextOpponent(int winner) {
    if (winner == 0 || winner == 1) return 2;
    else {
      if (currentMatch[0] == 2) return 1;
      else return 0;
    }
  }

  void startTimer() {
    playSound('silvato.mp3');
    timer?.cancel();
    setState(() {
      timeLeft = 10; // 600
    });
    timer = Timer.periodic(Duration(seconds: 1), (t) {
      if (timeLeft > 0) {
        if (mounted) setState(() => timeLeft--);
      } else {
        if (mounted) onMatchEnded();
      }
    });
  }

  Future<void> playSound(String assetName) async {
    final player = AudioPlayer();
    await player.play(AssetSource(assetName));
  }

  void addGoalToTeam(int teamMatchIndex) {
    int actualTeamIndex = currentMatch[teamMatchIndex];
    if (teams.length <= actualTeamIndex) return;
    List<Player> teamPlayers = teams[actualTeamIndex].players;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("¿Quién anotó? (Equipo ${actualTeamIndex + 1})"),
          content: SingleChildScrollView(
            child: Column(
              children: teamPlayers.map((player) {
                int matchGoals = goalsByPlayer[player.id] ?? 0;
                int overallGoals = overallGoalsByPlayer[player.id] ?? 0;
                return ListTile(
                  title: Text(player.name),
                  subtitle: Text("Goles: $matchGoals (Total: $overallGoals)"),
                  onTap: () {
                    if (mounted) {
                      setState(() {
                        goalsByPlayer[player.id] = (goalsByPlayer[player.id] ?? 0) + 1;
                        overallGoalsByPlayer[player.id] = (overallGoalsByPlayer[player.id] ?? 0) + 1;
                      });
                    }
                    Navigator.pop(context);
                    if (isFlashMode && getTeamGoals(teamMatchIndex) >= 2 && mounted) {
                      onMatchEnded();
                    }
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  int getTeamGoals(int teamMatchIndex) {
    int actualTeamIndex = currentMatch[teamMatchIndex];
    int total = 0;
    for (var player in teams[actualTeamIndex].players) {
      total += goalsByPlayer[player.id] ?? 0;
    }
    return total;
  }

  String getMVP(int teamMatchIndex) {
    int actualTeamIndex = currentMatch[teamMatchIndex];
    List<Player> teamPlayers = teams[actualTeamIndex].players;
    if (teamPlayers.isEmpty) return "Ninguno";
    Player? mvp;
    int maxGoals = 0;
    for (var player in teamPlayers) {
      int playerGoals = overallGoalsByPlayer[player.id] ?? 0;
      if (playerGoals > maxGoals) {
        maxGoals = playerGoals;
        mvp = player;
      }
    }
    return mvp != null ? "${mvp.name} ($maxGoals goles)" : "Ninguno";
  }

  String getMaxGoleador() {
    Player? topPlayer;
    int maxGoals = 0;
    for (var team in teams) {
      for (var player in team.players) {
        int playerGoals = overallGoalsByPlayer[player.id] ?? 0;
        if (playerGoals > maxGoals) {
          maxGoals = playerGoals;
          topPlayer = player;
        }
      }
    }
    return topPlayer != null ? "${topPlayer.name} ($maxGoals goles)" : "Ninguno";
  }

  // Función para terminar el partido y programar el siguiente, según la lógica.
  void onMatchEnded() {
    timer?.cancel();
    playSound('silvato.mp3');

    // Caso 1: Partido base [0,1]
    if (isBaseMatch()) {
      normalizeBaseMatch(); // Forzamos [0,1]
      int goalsA = getTeamGoals(0); // goles del equipo en posición 0
      int goalsB = getTeamGoals(1); // goles del equipo en posición 1
      if (goalsA == goalsB) {
        int randomChoice = Random().nextBool() ? currentMatch[0] : currentMatch[1];
        lastBaseWinner = randomChoice;
        currentMatch = [randomChoice, 2];
      } else {
        int baseWinner = (goalsA > goalsB) ? currentMatch[0] : currentMatch[1];
        lastBaseWinner = baseWinner;
        if (baseWinner == 0) {
          pointsTeam1++;
          currentMatch = [0, 2]; // Siguiente: Equipo 1 vs Equipo 3
        } else {
          pointsTeam2++;
          currentMatch = [1, 2]; // Siguiente: Equipo 2 vs Equipo 3
        }
      }
      matchCount++;
    }
    // Caso 2: Partido con el Equipo 3 (currentMatch contiene al 2)
    else if (currentMatch.contains(2)) {
      // Definimos el equipo base y se calculan sus goles.
      int baseTeam;
      int baseTeamGoals;
      int team3Goals;
      if (currentMatch[0] == 2) {
        baseTeam = currentMatch[1];
        team3Goals = getTeamGoals(0); // posición 0 tiene el 3
        baseTeamGoals = getTeamGoals(1);
      } else {
        baseTeam = currentMatch[0];
        baseTeamGoals = getTeamGoals(0);
        team3Goals = getTeamGoals(1);
      }
      if (baseTeamGoals == team3Goals) {
        // Empate: se programa como si ganara el Equipo 3 (porque el base ya jugó)
        currentMatch = (baseTeam == 0) ? [2, 1] : [2, 0];
      } else {
        int winner = (baseTeamGoals > team3Goals) ? baseTeam : 2;
        if (winner == baseTeam) {
          // Gana el base → se suma punto al base y se programa el siguiente partido base:
          if (baseTeam == 0) {
            pointsTeam1++;
            currentMatch = [0, 1]; // [0,1] → Equipo 1 vs Equipo 2
          } else {
            pointsTeam2++;
            currentMatch = [1, 0]; // [0,1] (ordenado) → Equipo 1 vs Equipo 2 (con ganador 2)
          }
        } else {
          // Gana el Equipo 3 → se suma 1 punto a Equipo 3 y se programa:
          // Si el base es 0 (Equipo 1), siguiente es [2,1] (Equipo 3 vs Equipo 2)
          // Si el base es 1 (Equipo 2), siguiente es [2,0] (Equipo 3 vs Equipo 1)
          pointsTeam3++;
          currentMatch = (baseTeam == 0) ? [2, 1] : [2, 0];
        }
      }
      matchCount++;
    } else {
      currentMatch = [0, 1];
      matchCount = 0;
    }
    resetMatch();
  }

  void finishEncounter() {
    timer?.cancel();
    playSound('silvato.mp3');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => EndMatchScreen(
          winner: 0, // Ajusta según tu criterio final
          pointsTeam1: pointsTeam1,
          pointsTeam2: pointsTeam2,
          pointsTeam3: pointsTeam3,
          mvpEquipo1: getMVPByTournamentIndex(0),
          mvpEquipo2: getMVPByTournamentIndex(1),
          mvpEquipo3: teams.length > 2 ? getMVPByTournamentIndex(2) : "Ninguno",
        ),
      ),
    );
    resetMatch();
  }

  String getMVPByTournamentIndex(int tournamentIndex) {
    if (teams.length <= tournamentIndex) return "Ninguno";
    List<Player> teamPlayers = teams[tournamentIndex].players;
    if (teamPlayers.isEmpty) return "Ninguno";
    Player? mvp;
    int maxGoals = 0;
    for (var player in teamPlayers) {
      int playerGoals = overallGoalsByPlayer[player.id] ?? 0;
      if (playerGoals > maxGoals) {
        maxGoals = playerGoals;
        mvp = player;
      }
    }
    return mvp != null ? "${mvp.name} ($maxGoals goles)" : "Ninguno";
  }

  void resetMatch() {
    if (!mounted) return;
    setState(() {
      timeLeft = 10; // 600
      goalsByPlayer.updateAll((key, value) => 0);
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
    
    if (teams.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Partido", style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text("Partido", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Selector de modo.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Modo: ", style: TextStyle(fontSize: 18)),
                TextButton(
                  onPressed: () {
                    if (!mounted) return;
                    setState(() { isFlashMode = true; });
                  },
                  child: Text("Flash",
                      style: TextStyle(
                          color: isFlashMode ? Colors.red : Colors.grey,
                          fontSize: 18)),
                ),
                TextButton(
                  onPressed: () {
                    if (!mounted) return;
                    setState(() { isFlashMode = false; });
                  },
                  child: Text("Normal",
                      style: TextStyle(
                          color: !isFlashMode ? Colors.red : Colors.grey,
                          fontSize: 18)),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text("Tiempo restante: $minutes:$seconds",
                style: TextStyle(fontSize: 32)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: startTimer,
              child: Text("Iniciar Partido"),
            ),
            SizedBox(height: 20),
            Text(
              "Partido: Equipo ${currentMatch[0] + 1} vs Equipo ${currentMatch[1] + 1}",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            // Botones para agregar gol.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text("Equipo ${currentMatch[0] + 1}",
                          style: TextStyle(fontSize: 20)),
                      Text("Goles: ${getTeamGoals(0)}",
                          style: TextStyle(fontSize: 20)),
                      ElevatedButton(
                        onPressed: () => addGoalToTeam(0),
                        child: Text("+1 GOL"),
                      ),
                      SizedBox(height: 10),
                      Text("MVP: ${getMVP(0)}",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    children: [
                      Text("Equipo ${currentMatch[1] + 1}",
                          style: TextStyle(fontSize: 20)),
                      Text("Goles: ${getTeamGoals(1)}",
                          style: TextStyle(fontSize: 20)),
                      ElevatedButton(
                        onPressed: () => addGoalToTeam(1),
                        child: Text("+1 GOL"),
                      ),
                      SizedBox(height: 10),
                      Text("MVP: ${getMVP(1)}",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text("Máximo goleador: ${getMaxGoleador()}",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Text("Puntos:", style: TextStyle(fontSize: 20)),
            Text("Equipo 1: $pointsTeam1", style: TextStyle(fontSize: 20)),
            Text("Equipo 2: $pointsTeam2", style: TextStyle(fontSize: 20)),
            Text("Equipo 3: $pointsTeam3", style: TextStyle(fontSize: 20)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: finishEncounter,
              child: Text("Fin Encuentro"),
            ),
          ],
        ),
      ),
    );
  }
}
