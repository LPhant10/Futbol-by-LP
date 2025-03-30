import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../models/player.dart';
import '../models/team.dart';
import '../services/team_storage_service.dart';

class MatchScreen extends StatefulWidget {
  @override
  _MatchScreenState createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  int timeLeft = 600; // 10 minutos en segundos
  Timer? timer;

  // Modo de partido: Flash (termina al alcanzar 2 goles) o Normal.
  bool isFlashMode = true;

  // Conteo de partidos jugados (para el torneo de 3 equipos, se juegan 2 partidos)
  int matchCount = 0;

  // Equipos cargados (se asume que ya se generaron y se guardaron previamente).
  List<Team> teams = [];
  // currentMatch indica los índices de los equipos que juegan en el partido actual.
  // Inicialmente es [0,1] (Equipo1 vs Equipo2)
  List<int> currentMatch = [0, 1];

  // Puntos acumulados por equipo (a nivel de torneo)
  int pointsTeam1 = 0;
  int pointsTeam2 = 0;
  int pointsTeam3 = 0;

  // Mapas para llevar la cuenta de goles:
  // goalsByPlayer: goles del partido actual (se resetean en cada partido).
  // overallGoalsByPlayer: goles acumulados en el torneo (no se resetean al reiniciar el partido).
  Map<int, int> goalsByPlayer = {};
  Map<int, int> overallGoalsByPlayer = {};

  @override
  void initState() {
    super.initState();
    loadTeams();
  }

  // Carga los equipos guardados y se inicializan ambos mapas de goles para cada jugador.
  Future<void> loadTeams() async {
    final result = await TeamStorageService.loadTeams();
    List<Team> loadedTeams = result["teams"] ?? [];
    setState(() {
      teams = loadedTeams;
      // Inicializamos los goles para cada jugador en cada equipo
      for (var team in teams) {
        for (var player in team.players) {
          goalsByPlayer[player.id] = 0;
          overallGoalsByPlayer[player.id] = 0;
        }
      }
    });
  }

  // Método para reproducir sonido desde assets (nueva API de audioplayers)
  Future<void> playSound(String assetName) async {
    final player = AudioPlayer();
    await player.play(AssetSource(assetName));
  }

  // Inicia el cronómetro y reproduce el sonido de inicio.
  void startTimer() {
    playSound('silvato.mp3'); // Sonido de inicio
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

  // Agrega un gol a un jugador del equipo que está jugando.
  // teamMatchIndex es 0 o 1, refiriéndose a currentMatch[0] o currentMatch[1].
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
                    setState(() {
                      // Incrementamos goles para el jugador
                      goalsByPlayer[player.id] = matchGoals + 1;
                      overallGoalsByPlayer[player.id] = overallGoals + 1;
                      // Actualizamos el total de goles del equipo en el partido
                      if (teamMatchIndex == 0)
                        setState(() => {}); // Luego se calcula con getTeamGoals
                      else if (teamMatchIndex == 1)
                        setState(() => {});
                    });
                    Navigator.pop(context);
                    // En modo Flash, si el equipo alcanza 2 goles, se termina el partido.
                    if (isFlashMode && getTeamGoals(teamMatchIndex) >= 2) {
                      endMatch();
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

  // Calcula el total de goles del equipo en el partido (usando el mapa match-level).
  int getTeamGoals(int matchTeamIndex) {
    int actualTeamIndex = currentMatch[matchTeamIndex];
    int total = 0;
    for (var player in teams[actualTeamIndex].players) {
      total += goalsByPlayer[player.id] ?? 0;
    }
    return total;
  }

  // Calcula el MVP de un equipo usando los goles acumulados en el torneo (overallGoalsByPlayer).
  String getMVP(int matchTeamIndex) {
    int actualTeamIndex = currentMatch[matchTeamIndex];
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

  // Calcula el máximo goleador del torneo (usando overallGoalsByPlayer)
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

  // Finaliza el partido: detiene el cronómetro, reproduce el sonido, determina el ganador del partido y programa el siguiente enfrentamiento.
  void endMatch() {
    timer?.cancel();
    playSound('silvato.mp3'); // Sonido de fin

    int team1Goals = getTeamGoals(0);
    int team2Goals = getTeamGoals(1);

    int winner = 0; // 1, 2 o 3; 0 si empate
    // En modo Flash, si algún equipo alcanza 2 goles, se termina el partido.
    if (isFlashMode && (team1Goals >= 2 || team2Goals >= 2)) {
      winner = team1Goals > team2Goals ? currentMatch[0] + 1 : currentMatch[1] + 1;
    } else {
      // En modo Normal, se evalúa al terminar el tiempo.
      if (team1Goals == team2Goals) {
        // En empate, si es el primer partido, se asume que el ganador es el equipo que no jugó.
        if (matchCount == 0) {
          winner = currentMatch[1] + 1;
        }
      } else {
        winner = team1Goals > team2Goals ? currentMatch[0] + 1 : currentMatch[1] + 1;
      }
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
      else if (winner == 3) pointsTeam3++;
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
              scheduleNextMatch(winner, team1Goals, team2Goals);
              resetMatch();
            },
            child: Text("OK"),
          )
        ],
      ),
    );
  }

  // Programa el siguiente partido basado en la lógica: 
  // - Partido 1: [Equipo1 vs Equipo2]
  // - Si hay un ganador claro, ese equipo juega contra el equipo que no jugó.
  // - En empate, se descarta el Equipo1 y el siguiente partido es Equipo2 vs Equipo3.
  void scheduleNextMatch(int winner, int team1Goals, int team2Goals) {
    if (matchCount == 0) {
      if (team1Goals != team2Goals) {
        int nextTeam = [0, 1, 2].firstWhere((i) => !currentMatch.contains(i));
        currentMatch = [winner - 1, nextTeam];
      } else {
        currentMatch = [1, 2];
      }
      matchCount++;
    } else {
      // Reiniciamos el torneo para simplificar.
      currentMatch = [0, 1];
      matchCount = 0;
    }
  }

  // Reinicia el partido: se resetean el cronómetro y los goles del partido actual.
  // Los goles acumulados en overallGoalsByPlayer se mantienen.
  void resetMatch() {
    setState(() {
      timeLeft = 600;
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
        title: Text("⚽ JUGANDO ⚽" ,style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.red,
      ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("⚽ JUGANDO ⚽" ,style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.red,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Modo de partido (Flash o Normal)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Modo: ", style: TextStyle(fontSize: 18)),
                TextButton(
                  onPressed: () {
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
            // Cronómetro
            Text("Tiempo restante: $minutes:$seconds",
                style: TextStyle(fontSize: 32)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: startTimer,
              child: Text("Iniciar Partido"),
            ),
            SizedBox(height: 20),
            // Encabezado del partido: mostrar equipos que juegan
            Text(
              "Partido: Equipo ${currentMatch[0] + 1} vs Equipo ${currentMatch[1] + 1}",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            // Mostrar botones para agregar gol a cada equipo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Primer equipo del partido
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
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                // Segundo equipo del partido
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
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            // Mostrar el máximo goleador del torneo
            Text("Máximo goleador: ${getMaxGoleador()}",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            // Mostrar puntos acumulados
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
