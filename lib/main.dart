import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(MyApp());

/// Aplicación principal
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Quita el banner de debug
      title: 'Team Generator',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: TeamGeneratorPage(),
    );
  }
}

/// Modelo para un jugador
class Player {
  int id;
  String name;
  int rating;

  Player({required this.id, required this.name, required this.rating});

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'rating': rating,
      };

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'],
      name: json['name'],
      rating: json['rating'],
    );
  }
}

/// Modelo para un equipo
class Team {
  List<Player> players;
  int totalScore;
  Player? goalkeeper;

  Team({List<Player>? players, this.totalScore = 0, this.goalkeeper})
      : players = players ?? [];
}

/// Balancea las puntuaciones de los equipos para que la diferencia
/// no exceda [maxDifference].
void balanceTeams(List<Team> teams, int playersPerTeam, {int maxDifference = 1}) {
  int maxScore = teams.map((t) => t.totalScore).reduce(max);
  int minScore = teams.map((t) => t.totalScore).reduce(min);

  while (maxScore - minScore > maxDifference) {
    Team maxTeam = teams.firstWhere((t) => t.totalScore == maxScore);
    Team minTeam = teams.firstWhere((t) => t.totalScore == minScore);

    if (maxTeam.players.isNotEmpty) {
      Player playerToMove = maxTeam.players.removeLast();
      maxTeam.totalScore -= playerToMove.rating;
      if (minTeam.players.length < playersPerTeam) {
        minTeam.players.add(playerToMove);
        minTeam.totalScore += playerToMove.rating;
      } else {
        maxTeam.players.add(playerToMove);
        maxTeam.totalScore += playerToMove.rating;
        break;
      }
    } else {
      break;
    }
    maxScore = teams.map((t) => t.totalScore).reduce(max);
    minScore = teams.map((t) => t.totalScore).reduce(min);
  }
}

/// Genera equipos de campo con EXACTAMENTE [playersPerTeam] jugadores por equipo.
Map<String, dynamic> generateFieldTeams(
    List<Player> players, int playersPerTeam, int numberOfTeams,
    {int maxDifference = 1}) {
  // Ordenar jugadores de mayor a menor rating
  players.sort((a, b) => b.rating.compareTo(a.rating));
  List<Team> teams = List.generate(numberOfTeams, (_) => Team());
  List<Player> leftovers = [];

  for (var player in players) {
    Team team =
        teams.reduce((t1, t2) => t1.totalScore < t2.totalScore ? t1 : t2);
    if (team.players.length < playersPerTeam) {
      team.players.add(player);
      team.totalScore += player.rating;
    } else {
      leftovers.add(player);
    }
  }

  balanceTeams(teams, playersPerTeam, maxDifference: maxDifference);
  return {"teams": teams, "leftovers": leftovers};
}

/// Genera equipos completos:
/// 1. Se usan TODOS los jugadores para formar equipos de EXACTAMENTE [playersPerTeam] jugadores.
/// 2. Luego, en cada equipo se asigna un arquero:
///    - Si existe un jugador con rating == 1, se designa ese jugador.
///    - Si no, se ordena el equipo por rating ascendente y se asigna el jugador con menor rating.
Map<String, dynamic> generateCompleteTeams(
    List<Player> selectedPlayers, int playersPerTeam, int numberOfTeams,
    {int maxDifference = 1}) {
  if (selectedPlayers.length < playersPerTeam * numberOfTeams) {
    throw Exception(
        "No hay suficientes jugadores para formar $numberOfTeams equipos de $playersPerTeam jugadores cada uno.");
  }
  selectedPlayers.shuffle();

  final result = generateFieldTeams(
      selectedPlayers, playersPerTeam, numberOfTeams,
      maxDifference: maxDifference);
  List<Team> teams = result["teams"];
  List<Player> leftovers = result["leftovers"];

  // Asignar arquero en cada equipo sin quitarlo, para mantener el total de jugadores.
  for (int i = 0; i < teams.length; i++) {
    if (teams[i].players.any((p) => p.rating == 1)) {
      teams[i].goalkeeper = teams[i].players.firstWhere((p) => p.rating == 1);
    } else if (teams[i].players.isNotEmpty) {
      teams[i].players.sort((a, b) => a.rating.compareTo(b.rating));
      teams[i].goalkeeper = teams[i].players.first;
    }
  }
  return {"teams": teams, "leftovers": leftovers};
}

/// Pantalla principal con persistencia, selección y opciones de generación.
class TeamGeneratorPage extends StatefulWidget {
  @override
  _TeamGeneratorPageState createState() => _TeamGeneratorPageState();
}

class _TeamGeneratorPageState extends State<TeamGeneratorPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ratingController = TextEditingController();

  List<Player> players = [];
  Map<int, bool> selectedPlayers = {};
  List<int> selectedOrder = [];

  int playersPerTeam = 5;
  int numberOfTeams = 2;
  int maxDifference = 5; // Diferencia máxima deseada

  @override
  void initState() {
    super.initState();
    loadPlayers();
  }

  // Cargar jugadores desde SharedPreferences
  Future<void> loadPlayers() async {
    final prefs = await SharedPreferences.getInstance();
    String? playersString = prefs.getString("players");
    if (playersString != null) {
      List<dynamic> playersJson = jsonDecode(playersString);
      setState(() {
        players = playersJson.map((e) => Player.fromJson(e)).toList();
        for (var p in players) {
          selectedPlayers[p.id] = false;
        }
        selectedOrder.clear();
      });
    }
  }

  // Guardar jugadores en SharedPreferences
  Future<void> savePlayersList() async {
    final prefs = await SharedPreferences.getInstance();
    String playersString = jsonEncode(players.map((p) => p.toJson()).toList());
    await prefs.setString("players", playersString);
  }

  void addPlayer() {
    String name = _nameController.text.trim();
    int? rating = int.tryParse(_ratingController.text);
    if (name.isEmpty || rating == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Nombre y rating son requeridos.")));
      return;
    }
    setState(() {
      Player newPlayer = Player(
          id: DateTime.now().millisecondsSinceEpoch,
          name: name,
          rating: rating);
      players.add(newPlayer);
      selectedPlayers[newPlayer.id] = false;
      _nameController.clear();
      _ratingController.clear();
    });
    savePlayersList();
  }

  void editPlayer(Player player) {
    _nameController.text = player.name;
    _ratingController.text = player.rating.toString();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Editar jugador"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: "Nombre")),
            TextField(
                controller: _ratingController,
                decoration: InputDecoration(labelText: "Rating"),
                keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                _nameController.clear();
                _ratingController.clear();
              },
              child: Text("Cancelar")),
          TextButton(
              onPressed: () {
                setState(() {
                  player.name = _nameController.text.trim();
                  player.rating =
                      int.tryParse(_ratingController.text) ?? player.rating;
                });
                Navigator.pop(context);
                _nameController.clear();
                _ratingController.clear();
                savePlayersList();
              },
              child: Text("Guardar")),
        ],
      ),
    );
  }

  void deletePlayer(Player player) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Eliminar jugador"),
        content: Text("¿Estás seguro de eliminar a ${player.name}?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancelar")),
          TextButton(
              onPressed: () {
                setState(() {
                  players.removeWhere((p) => p.id == player.id);
                  selectedPlayers.remove(player.id);
                  selectedOrder.remove(player.id);
                });
                Navigator.pop(context);
                savePlayersList();
              },
              child: Text("Eliminar")),
        ],
      ),
    );
  }

  void selectAll(bool select) {
    setState(() {
      for (var player in players) {
        selectedPlayers[player.id] = select;
        if (select && !selectedOrder.contains(player.id)) {
          selectedOrder.add(player.id);
        } else if (!select) {
          selectedOrder.remove(player.id);
        }
      }
    });
  }

  void generateTeamsAction() {
    List<Player> selected =
        players.where((p) => selectedPlayers[p.id] == true).toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("No hay jugadores seleccionados.")));
      return;
    }
    try {
      final result = generateCompleteTeams(
          selected, playersPerTeam, numberOfTeams,
          maxDifference: maxDifference);
      final List<Team> teams = result["teams"];
      final List<Player> leftovers = result["leftovers"];
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Equipos Generados"),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...teams.asMap().entries.map((entry) {
                  int index = entry.key;
                  Team team = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Equipo ${index + 1}",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text("Total de jugadores: ${team.players.length}"),
                        Text("Arquero: ${team.goalkeeper?.name ?? 'Ninguno'}"),
                        Text("Puntuación Total: ${team.totalScore}"),
                        SizedBox(height: 4),
                        Text("Jugadores:"),
                        ...team.players.asMap().entries.map((e) {
                          int i = e.key;
                          Player p = e.value;
                          return Text("  ${i + 1}. ${p.name} - ${p.rating}");
                        }).toList(),
                      ],
                    ),
                  );
                }).toList(),
                Text("Jugadores Sobrantes:",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                if (leftovers.isEmpty)
                  Text("  Ninguno")
                else
                  ...leftovers.asMap().entries.map((e) {
                    int i = e.key;
                    Player p = e.value;
                    return Text("  ${i + 1}. ${p.name} - ${p.rating}");
                  }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cerrar")),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    int selectedCount = selectedPlayers.values.where((v) => v).length;
    return Scaffold(
      appBar: AppBar(
        title: Text("⚽ Team Generator by LP ⚽"),
        backgroundColor: Colors.green,
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(12),
          children: [
            // Sección para agregar jugador
            Text("Agregar Jugador",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                        labelText: "Nombre", border: OutlineInputBorder()),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _ratingController,
                    decoration: InputDecoration(
                        labelText: "Rating", border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(onPressed: addPlayer, child: Text("Agregar")),
              ],
            ),
            SizedBox(height: 16),
            // Opciones de generación al comienzo
            Text("Opciones de generación",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Row(
              children: [
                Text("Jugadores por equipo: "),
                DropdownButton<int>(
                  value: playersPerTeam,
                  items: [5, 6, 7]
                      .map((e) => DropdownMenuItem<int>(
                          value: e, child: Text("$e")))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      playersPerTeam = value ?? 5;
                    });
                  },
                ),
                SizedBox(width: 16),
                Text("Número de equipos: "),
                DropdownButton<int>(
                  value: numberOfTeams,
                  items: [2, 3, 4]
                      .map((e) => DropdownMenuItem<int>(
                          value: e, child: Text("$e")))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      numberOfTeams = value ?? 2;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Text("Diferencia máxima: "),
                DropdownButton<int>(
                  value: maxDifference,
                  items: [1, 2, 3, 4, 5]
                      .map((e) => DropdownMenuItem<int>(
                          value: e, child: Text("$e")))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      maxDifference = value ?? 1;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
            // Sección de jugadores y selección
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Jugadores",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    TextButton(
                        onPressed: () => selectAll(true),
                        child: Text("Select All")),
                    TextButton(
                        onPressed: () => selectAll(false),
                        child: Text("Deselect All")),
                  ],
                ),
              ],
            ),
            if (selectedCount > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text("Jugadores seleccionados: $selectedCount",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            Column(
              children: players.map((player) {
                bool isSelected = selectedPlayers[player.id] ?? false;
                int? order =
                    isSelected ? (selectedOrder.indexOf(player.id) + 1) : null;
                return Card(
                  child: ListTile(
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              selectedPlayers[player.id] = value ?? false;
                              if (value == true) {
                                if (!selectedOrder.contains(player.id)) {
                                  selectedOrder.add(player.id);
                                }
                              } else {
                                selectedOrder.remove(player.id);
                              }
                            });
                          },
                        ),
                        if (isSelected)
                          Padding(
                            padding: const EdgeInsets.only(left: 4.0),
                            child: CircleAvatar(
                              radius: 12,
                              child: Text("$order",
                                  style: TextStyle(fontSize: 12)),
                            ),
                          ),
                      ],
                    ),
                    title: Text(player.name),
                    subtitle: Text("Rating: ${player.rating}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () => editPlayer(player)),
                        IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => deletePlayer(player)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: generateTeamsAction,
                child: Text("Generar Equipos"),
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => MatchScreen()));
                },
                child: Text("Ir a Partido"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pantalla de Partido con cronómetro de 10 minutos y asignación de puntos.
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

  void startTimer() {
    if (timer != null) timer!.cancel();
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
    if (timer != null) timer!.cancel();

    int winner = 0; // 1 para Equipo1, 2 para Equipo2, 3 para Equipo3; 0 para empate
    // Si algún equipo alcanza 2 goles, se considera ganador inmediato.
    if (goalsTeam1 >= 2 || goalsTeam2 >= 2 || goalsTeam3 >= 2) {
      int maxGoals = max(goalsTeam1, max(goalsTeam2, goalsTeam3));
      if (goalsTeam1 == maxGoals) {
        winner = 1;
      } else if (goalsTeam2 == maxGoals) {
        winner = 2;
      } else if (goalsTeam3 == maxGoals) {
        winner = 3;
      }
    } else {
      // Si se acaba el tiempo sin que ningún equipo alcance 2 goles,
      // el que tenga mayor cantidad de goles gana (si hay empate, no suma punto).
      int maxGoals = max(goalsTeam1, max(goalsTeam2, goalsTeam3));
      List<int> winners = [];
      if (goalsTeam1 == maxGoals) winners.add(1);
      if (goalsTeam2 == maxGoals) winners.add(2);
      if (goalsTeam3 == maxGoals) winners.add(3);
      if (winners.length == 1) {
        winner = winners.first;
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
    if (timer != null) timer!.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String minutes = (timeLeft ~/ 60).toString().padLeft(2, '0');
    String seconds = (timeLeft % 60).toString().padLeft(2, '0');
    return Scaffold(
      appBar: AppBar(
        title: Text("Partido"),
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
                          if (goalsTeam1 >= 2) {
                            endMatch();
                          }
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
                          if (goalsTeam2 >= 2) {
                            endMatch();
                          }
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
                          if (goalsTeam3 >= 2) {
                            endMatch();
                          }
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
