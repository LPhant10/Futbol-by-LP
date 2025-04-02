import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart'; // <--- Para listEquals
import 'package:flutter/material.dart';
import '../models/player.dart';
import '../models/team.dart';
import '../services/team_storage_service.dart';
import 'end_match_screen.dart';

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  _MatchScreenState createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  int timeLeft = 600;
  Timer? timer;
  bool isFlashMode = true;
  int matchCount = 0;
  List<Team> teams = [];
  List<int> currentMatch = [0, 1];
  int pointsTeam1 = 0;
  int pointsTeam2 = 0;
  int pointsTeam3 = 0;
  int pointsTeam4 = 0;
  Map<int, int> goalsByPlayer = {};
  Map<int, int> overallGoalsByPlayer = {};
  int? lastBaseWinner;
  bool isPaused = false;
  final TextEditingController _durationController = TextEditingController(text: "10"); // duración en minutos


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

  bool isBaseMatch() {
    return currentMatch.toSet().containsAll({0, 1});
  }

  void normalizeBaseMatch() {
    if (isBaseMatch()) currentMatch.sort();
  }

  List<int> toggleMatchForTie(List<int> match) {
    // Secuencia [0,1] → [1,2] → [2,0] → [0,1]
    if ((match[0] == 0 && match[1] == 1) || (match[0] == 1 && match[1] == 0)) {
      return [1, 2];
    } else if ((match[0] == 1 && match[1] == 2) || (match[0] == 2 && match[1] == 1)) {
      return [2, 0];
    } else if ((match[0] == 2 && match[1] == 0) || (match[0] == 0 && match[1] == 2)) {
      return [0, 1];
    }
    return match;
  }

  // EJEMPLO: Función para alternar partidos en caso de empate con 4 equipos.
  // Ajusta la secuencia según necesites.
  List<int> toggleMatchForTie4(List<int> match) {
    // Aquí solo un ejemplo básico de "rotación" en caso de empate
    // Dependiendo de tu lógica, puedes definir más secuencias.
    if (listEquals(match, [0, 2])) {
      return [2, 1];
    } else if (listEquals(match, [2, 0])) {
      return [0, 3];
    } else if (listEquals(match, [1, 3])) {
      return [3, 0];
    } else if (listEquals(match, [3, 1])) {
      return [1, 2];
    }
    // Puedes añadir más combinaciones si quisieras.
    return [0, 1];
  }

  void startTimer() {
  final int? customMinutes = int.tryParse(_durationController.text.trim());
  if (customMinutes == null || customMinutes <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Ingrese un tiempo válido en minutos")),
    );
    return;
  }

  playSound('silvato.mp3');
  timer?.cancel();

  setState(() {
    timeLeft = customMinutes * 60;
    isPaused = false;
  });

  timer = Timer.periodic(Duration(seconds: 1), (t) {
    if (!isPaused && timeLeft > 0) {
      setState(() {
        timeLeft--;
      });
    } else if (timeLeft == 0) {
      onMatchEnded();
    }
  });
}

void togglePause() {
  setState(() {
    isPaused = !isPaused;
  });
}
void resetTimer() {
  timer?.cancel();
  setState(() {
    timeLeft = 600;
    isPaused = false;
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
                        goalsByPlayer[player.id] =
                            (goalsByPlayer[player.id] ?? 0) + 1;
                        overallGoalsByPlayer[player.id] =
                            (overallGoalsByPlayer[player.id] ?? 0) + 1;
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
    return topPlayer != null
        ? "${topPlayer.name} ($maxGoals goles)"
        : "Ninguno";
  }

  void onMatchEnded() {
  timer?.cancel();
  playSound('silvato.mp3');

  // Caso 1: Sólo hay 2 equipos → siempre se juega [0,1]
  if (teams.length == 2) {
    normalizeBaseMatch(); // Asegura que currentMatch sea [0,1]
    int goalsA = getTeamGoals(0);
    int goalsB = getTeamGoals(1);
    if (goalsA == goalsB) {
      // En empate, elegimos aleatoriamente un ganador (sin asignar punto)
      lastBaseWinner = Random().nextBool() ? 0 : 1;
    } else {
      int baseWinner = (goalsA > goalsB) ? currentMatch[0] : currentMatch[1];
      lastBaseWinner = baseWinner;
      if (baseWinner == 0) {
        pointsTeam1++;
      } else {
        pointsTeam2++;
      }
    }
    currentMatch = [0, 1];
    matchCount++;
    resetMatch();
    return;
  }

  // Caso 2: Hay 3 equipos → se usa la lógica actual
  if (teams.length == 3) {
    if (isBaseMatch()) {
      normalizeBaseMatch(); // Forzamos que sea [0,1]
      int goalsA = getTeamGoals(0);
      int goalsB = getTeamGoals(1);
      if (goalsA == goalsB) {
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
    } else if (currentMatch.contains(2)) {
      int goalsMatch0 = getTeamGoals(0);
      int goalsMatch1 = getTeamGoals(1);
      if (goalsMatch0 == goalsMatch1) {
        currentMatch = toggleMatchForTie(currentMatch);
      } else {
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
          if (baseTeam == 0) {
            pointsTeam1++;
          } else {
            pointsTeam2++;
          }
          currentMatch = [0, 1];
        } else {
          pointsTeam3++;
          currentMatch = (baseTeam == 0) ? [2, 1] : [2, 0];
        }
      }
      matchCount++;
    }
  }


// Caso 3: Hay 4 equipos → Rotación de oponentes para el ganador
else if (teams.length == 4) {
  // Determinamos el ganador del partido actual
  int ganador;
  if (getTeamGoals(0) == getTeamGoals(1)) {
    // En empate, usamos toggle y reiniciamos el partido
    currentMatch = toggleMatchForTie(currentMatch);
    resetMatch();
    return;
  } else {
    ganador = (getTeamGoals(0) > getTeamGoals(1))
        ? currentMatch[0]
        : currentMatch[1];
  }
  lastBaseWinner = ganador;

  // Aumentamos el puntaje del ganador (asegúrate de que exista una variable pointsTeam4 para el equipo 4)
  switch (ganador) {
    case 0:
      pointsTeam1++;
      break;
    case 1:
      pointsTeam2++;
      break;
    case 2:
      pointsTeam3++;
      break;
    case 3:
      pointsTeam4++;
      break;
  }

  // Creamos una lista de oponentes (todos menos el ganador)
  List<int> oponentes = List<int>.generate(4, (i) => i)..remove(ganador);

  // Obtenemos el último oponente (el otro miembro de currentMatch)
  int lastOpponent = currentMatch.firstWhere((e) => e != ganador, orElse: () => oponentes.first);

  // Buscamos el índice del último oponente en la lista de oponentes
  int index = oponentes.indexOf(lastOpponent);
  // Calculamos el índice del siguiente oponente (cíclico)
  int nextIndex = (index + 1) % oponentes.length;
  int siguienteOponente = oponentes[nextIndex];

  // Actualizamos el partido actual
  currentMatch = [ganador, siguienteOponente];
  matchCount++;
    
  } else {
    // Si no se cumple ningún caso, se vuelve a la base
    currentMatch = [0, 1];
    matchCount = 0;
  }
  resetMatch();
}

////
int getTotalPlayers() {
  int total = 0;
  for (var team in teams) {
    total += team.players.length;
  }
  return total;
}

List<String> getAllPlayers() {
  List<String> result = [];
  for (var t in teams) {
    for (var p in t.players) {
      result.add(p.name); // O el nombre que quieras
    }
  }
  return result;
}

  void finishEncounter() {
  timer?.cancel();
  playSound('silvato.mp3');

  int totalPlayers = getTotalPlayers(); 
  List<String> allPlayers = getAllPlayers();

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => EndMatchScreen(
        pointsTeam1: pointsTeam1,
        pointsTeam2: pointsTeam2,
        pointsTeam3: pointsTeam3,
        pointsTeam4: pointsTeam4,
        
        mvpEquipo1: getMVPByTournamentIndex(0),
        mvpEquipo2: getMVPByTournamentIndex(1),
        mvpEquipo3: (teams.length > 2) ? getMVPByTournamentIndex(2) : "Ninguno",
        mvpEquipo4: getMVPByTournamentIndex(3),
        
        totalPlayers: totalPlayers,
        allPlayers: allPlayers,
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
      timeLeft = 600;
      goalsByPlayer.updateAll((key, value) => 0);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    _durationController.dispose();
    super.dispose();
  }


  //////////

  @override
  
Widget build(BuildContext context) {
  
  String minutes = (timeLeft ~/ 60).toString().padLeft(2, '0');
  String seconds = (timeLeft % 60).toString().padLeft(2, '0');

  if (teams.isEmpty) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(child: CircularProgressIndicator()),
    );
  }

  return GestureDetector(
    onTap: () => FocusScope.of(context).unfocus(),
    child: Stack(
      children: [
        Positioned.fill(
          child: Opacity(
            opacity: 0.3,
            child: Image.asset("assets/game.jpg", fit: BoxFit.cover),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            Navigator.pop(context);
                          },
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.sports_soccer, color: Colors.white, size: 28),
                              SizedBox(width: 6),
                              Text(
                                "JUGANDO",
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              SizedBox(width: 6),
                              Icon(Icons.sports_soccer, color: Colors.white, size: 28),
                            ],
                          ),
                        ),
                        SizedBox(width: 48), // Para alinear el botón de la izquierda
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Modo: ", style: TextStyle(fontSize: 18, color: Colors.white)),
                      TextButton(
                        onPressed: () {
                          if (!mounted) return;
                          setState(() {
                            isFlashMode = true;
                          });
                        },
                        child: Text("Flash", style: TextStyle(color: isFlashMode ? Colors.red : Colors.grey, fontSize: 18)),
                      ),
                      TextButton(
                        onPressed: () {
                          if (!mounted) return;
                          setState(() {
                            isFlashMode = false;
                          });
                        },
                        child: Text("Normal", style: TextStyle(color: !isFlashMode ? Colors.red : Colors.grey, fontSize: 18)),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  Text("Tiempo restante: $minutes:$seconds", style: TextStyle(fontSize: 32, color: Colors.white)),
SizedBox(height: 12),
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Text("Duración (min): ", style: TextStyle(color: Colors.white)),
    SizedBox(
      width: 60,
      child: TextField(
        controller: _durationController,
        keyboardType: TextInputType.number,
        style: TextStyle(color: Colors.white),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 8),
          filled: true,
          fillColor: Colors.black.withOpacity(0.3),
          border: OutlineInputBorder(),
        ),
      ),
    ),
  ],
),
SizedBox(height: 12),



                  Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    ElevatedButton(
      onPressed: startTimer,
      child: Text("Iniciar"),
    ),
    SizedBox(width: 10),
    ElevatedButton(
      onPressed: togglePause,
      child: Text(isPaused ? "Reanudar" : "Pausar"),
    ),
    SizedBox(width: 10),
    ElevatedButton(
      onPressed: resetTimer,
      child: Text("Reiniciar"),
    ),
  ],
),

                  SizedBox(height: 20),
                  Text(
                    "Partido: Equipo ${currentMatch[0] + 1} vs Equipo ${currentMatch[1] + 1}",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text("Equipo ${currentMatch[0] + 1}", style: TextStyle(fontSize: 20, color: Colors.white)),
                            Text("Goles: ${getTeamGoals(0)}", style: TextStyle(fontSize: 20,color: Colors.white)),
                            ElevatedButton(
                              onPressed: () => addGoalToTeam(0),
                              child: Text("+1 GOL"),
                            ),
                            SizedBox(height: 10),
                            Text("MVP: ${getMVP(0)}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.white)),
                          ],
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          children: [
                            Text("Equipo ${currentMatch[1] + 1}", style: TextStyle(fontSize: 20,color: Colors.white)),
                            Text("Goles: ${getTeamGoals(1)}", style: TextStyle(fontSize: 20,color: Colors.white)),
                            ElevatedButton(
                              onPressed: () => addGoalToTeam(1),
                              child: Text("+1 GOL"),
                            ),
                            SizedBox(height: 10),
                            Text("MVP: ${getMVP(1)}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Text("Máximo goleador: ${getMaxGoleador()}", style: 
                  TextStyle(fontSize: 20, fontWeight: FontWeight.bold,color: Colors.white)),
                  SizedBox(height: 20),
                  Text("Puntos:", style: TextStyle(fontSize: 20,color: Colors.white)),
                  Text("Equipo 1: $pointsTeam1", style: TextStyle(fontSize: 20,color: Colors.white)),
                  Text("Equipo 2: $pointsTeam2", style: TextStyle(fontSize: 20,color: Colors.white)),
                  if (teams.length >= 3) Text("Equipo 3: $pointsTeam3", style: TextStyle(fontSize: 20,color: Colors.white)),
                  if (teams.length == 4) Text("Equipo 4: $pointsTeam4", style: TextStyle(fontSize: 20,color: Colors.white)),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: finishEncounter,
                    child: Text("Fin Encuentro"),
                  ),
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