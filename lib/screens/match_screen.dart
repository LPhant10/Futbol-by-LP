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
  // Para testeo, puedes reducir timeLeft (por ejemplo, a 10 seg), en producción 600 seg.
  int timeLeft = 10;
  Timer? timer;

  // Modo Flash: se termina el partido al alcanzar 2 goles.
  bool isFlashMode = true;
  int matchCount = 0;

  List<Team> teams = [];
  // Los partidos se interpretan de la siguiente forma:
  // [0,1] → Partido base: Equipo 1 vs Equipo 2.
  // [0,2] → Partido: Equipo 1 vs Equipo 3 (base = 0).
  // [1,2] → Partido: Equipo 2 vs Equipo 3 (base = 1).
  List<int> currentMatch = [0, 1];

  int pointsTeam1 = 0;
  int pointsTeam2 = 0;
  int pointsTeam3 = 0;

  Map<int, int> goalsByPlayer = {};
  Map<int, int> overallGoalsByPlayer = {};

  int? lastBaseWinner; // Para recordar el ganador de la base (opcional)

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

  // Retorna true si currentMatch contiene 0 y 1 (partido base).
  bool isBaseMatch() {
    return currentMatch.toSet().containsAll({0, 1});
  }

  // Para partidos base, forzamos el orden [0,1] (esto ayuda a identificar quién ganó).
  void normalizeBaseMatch() {
    if (isBaseMatch()) currentMatch.sort();
  }

  // Función auxiliar para elegir el siguiente rival.
  // Si el ganador es base (0 o 1), el siguiente rival es el Equipo 3 (índice 2).
  // Si el ganador es el Equipo 3 (índice 2), se asigna según:
  // - Si currentMatch es [0,2] → ya jugó contra el 1, siguiente rival es 1.
  // - Si currentMatch es [1,2] → ya jugó contra el 2, siguiente rival es 0.
  int chooseNextOpponent(int winner) {
    if (winner == 0 || winner == 1) return 2;
    else {
      if (currentMatch[0] == 2) return 1;
      else return 0;
    }
  }

  // Función auxiliar para alternar el partido en caso de empate.
  // Se define un ciclo:
  // [0,1] → [1,2] → [2,0] → [0,1]
  List<int> toggleMatchForTie(List<int> match) {
    // Si el partido actual es base [0,1] (o [1,0]), siguiente es [1,2].
    if ((match[0] == 0 && match[1] == 1) || (match[0] == 1 && match[1] == 0)) {
      return [1, 2];
    }
    // Si es [1,2] (Equipo 2 vs Equipo 3), siguiente es [2,0] (Equipo 3 vs Equipo 1).
    else if ((match[0] == 1 && match[1] == 2) || (match[0] == 2 && match[1] == 1)) {
      return [2, 0];
    }
    // Si es [2,0] (Equipo 3 vs Equipo 1), siguiente es [0,1] (Equipo 1 vs Equipo 2).
    else if ((match[0] == 2 && match[1] == 0) || (match[0] == 0 && match[1] == 2)) {
      return [0, 1];
    }
    return match;
  }

  // Para testeo rápido, se puede reducir el tiempo.
  void startTimer() {
    playSound('silvato.mp3');
    timer?.cancel();
    setState(() {
      // Para testeo, podrías poner timeLeft = 10;
      timeLeft = 10;
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
                    if (isFlashMode &&
                        getTeamGoals(teamMatchIndex) >= 2 &&
                        mounted) {
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

  // Lógica para terminar el partido y asignar el siguiente según la secuencia:
  // 1) Partido base [0,1]:
  //    - Si gana el Equipo 1 → 1 punto a Equipo 1 → siguiente: [0,2].
  //    - Si gana el Equipo 2 → 1 punto a Equipo 2 → siguiente: [1,2].
  //    - Si empatan → siguiente: toggle([0,1]) = [1,2].
  //
  // 2) Partido con el Equipo 3:
  //    Caso A: [0,2] (Equipo 1 vs Equipo 3):
  //      - Si gana el Equipo 1 → 1 punto a Equipo 1 → siguiente: [0,1].
  //      - Si gana el Equipo 3 → 1 punto a Equipo 3 → siguiente: [2,1].
  //      - Si empatan → siguiente: toggle([0,2]) = [2,1].
  //    Caso B: [1,2] (Equipo 2 vs Equipo 3):
  //      - Si gana el Equipo 2 → 1 punto a Equipo 2 → siguiente: [0,1] (equivalente a [1,0]).
  //      - Si gana el Equipo 3 → 1 punto a Equipo 3 → siguiente: [2,0].
  //      - Si empatan → siguiente: toggle([1,2]) = [2,0].
  void onMatchEnded() {
    timer?.cancel();
    playSound('silvato.mp3');

    // Si es partido base [0,1]
    if (isBaseMatch()) {
      normalizeBaseMatch(); // Forzamos que sea [0,1]
      int goalsA = getTeamGoals(0);
      int goalsB = getTeamGoals(1);
      if (goalsA == goalsB) {
        // En empate, usamos toggle para la secuencia.
        currentMatch = toggleMatchForTie(currentMatch);
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
    // Partido con el Equipo 3 (cuando currentMatch contiene 2)
    else if (currentMatch.contains(2)) {
      int goalsMatch0 = getTeamGoals(0);
      int goalsMatch1 = getTeamGoals(1);
      if (goalsMatch0 == goalsMatch1) {
        // En empate, usamos toggle para alternar la secuencia.
        currentMatch = toggleMatchForTie(currentMatch);
      } else {
        // Determinamos el equipo base (el que no es 2)
        int baseTeam = (currentMatch[0] == 2) ? currentMatch[1] : currentMatch[0];
        int baseGoals, team3Goals;
        if (currentMatch[0] == 2) {
          team3Goals = getTeamGoals(0);
          baseGoals = getTeamGoals(1);
        } else {
          baseGoals = getTeamGoals(0);
          team3Goals = getTeamGoals(1);
        }
        int winner = (baseGoals > team3Goals) ? baseTeam : 2;
        if (winner == baseTeam) {
          // El equipo base gana → se asigna el siguiente partido base.
          if (baseTeam == 0) {
            pointsTeam1++;
            currentMatch = [0, 1];
          } else {
            pointsTeam2++;
            currentMatch = [0, 1]; // [0,1] es la base
          }
        } else {
          // Gana el Equipo 3 → se suma 1 punto y el siguiente partido es contra el otro base.
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
          winner: 0, // Ajusta según tu criterio final.
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
      timeLeft = 10;
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
                    setState(() {
                      isFlashMode = true;
                    });
                  },
                  child: Text("Flash",
                      style: TextStyle(
                          color: isFlashMode ? Colors.red : Colors.grey,
                          fontSize: 18)),
                ),
                TextButton(
                  onPressed: () {
                    if (!mounted) return;
                    setState(() {
                      isFlashMode = false;
                    });
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
            // Botones para agregar goles.
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
