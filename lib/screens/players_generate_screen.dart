// lib/screens/players_generate_screen.dart
import 'package:flutter/material.dart';
import '../models/player.dart';
import '../models/team.dart';
import '../services/storage_service.dart';
import '../services/team_service.dart';
import '../services/team_storage_service.dart';

class PlayersGenerateScreen extends StatefulWidget {
  @override
  _PlayersGenerateScreenState createState() => _PlayersGenerateScreenState();
}

class _PlayersGenerateScreenState extends State<PlayersGenerateScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ratingController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  bool isSearching = false;
  String searchQuery = '';
  bool showPlayers = true;

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

  Future<void> loadPlayers() async {
    players = await StorageService.loadPlayers();
    setState(() {
      for (var p in players) {
        selectedPlayers[p.id] = false;
      }
      selectedOrder.clear();
    });
  }

  Future<void> savePlayersList() async {
    await StorageService.savePlayers(players);
  }

  void addPlayer() {
    String name = _nameController.text.trim();
    int? rating = int.tryParse(_ratingController.text);
    if (name.isEmpty || rating == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Nombre y rating son requeridos.")),
      );
      return;
    }
    setState(() {
      Player newPlayer = Player(
        id: DateTime.now().millisecondsSinceEpoch,
        name: name,
        rating: rating,
      );
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
              decoration: InputDecoration(labelText: "Nombre"),
            ),
            TextField(
              controller: _ratingController,
              decoration: InputDecoration(labelText: "Rating"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _nameController.clear();
              _ratingController.clear();
            },
            child: Text("Cancelar"),
          ),
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
            child: Text("Guardar"),
          ),
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
            child: Text("Cancelar"),
          ),
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
            child: Text("Eliminar"),
          ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No hay jugadores seleccionados.")),
      );
      return;
    }
    try {
      final result = generateCompleteTeams(
        selected,
        playersPerTeam,
        numberOfTeams,
        maxDifference: maxDifference,
      );
      final List<Team> teams = result["teams"];
      final List<Player> leftovers = result["leftovers"];

      TeamStorageService.saveTeams(teams, leftovers);

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
                  var team = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Equipo ${index + 1}",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text("Total de jugadores: ${team.players.length}"),
                        Text("Arquero: ${team.goalkeeper?.name ?? 'Ninguno'}"),
                        Text("Puntuación Total: ${team.totalScore}"),
                        SizedBox(height: 4),
                        Text("Jugadores:"),
                        ...team.players.asMap().entries.map((e) {
                          int i = e.key;
                          var p = e.value;
                          return Text("  ${i + 1}. ${p.name} - ${p.rating}");
                        }).toList(),
                      ],
                    ),
                  );
                }).toList(),
                Text(
                  "Jugadores Sobrantes:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (leftovers.isEmpty)
                  Text("  Ninguno")
                else
                  ...leftovers.asMap().entries.map((e) {
                    int i = e.key;
                    var p = e.value;
                    return Text("  ${i + 1}. ${p.name} - ${p.rating}");
                  }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cerrar"),
            ),
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
    // Filtrar jugadores según búsqueda
    List<Player> filteredPlayers = players.where((player) {
      return player.name.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    int selectedCount = selectedPlayers.values.where((v) => v).length;

    return Scaffold(
      appBar: AppBar(
        title: Text("⚽ PICHANGEROS ⚽", style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.blue,
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(12),
          children: [
            // Sección "Agregar Jugador"
            Text(
              "Agregar Jugador",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: "Nombre",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _ratingController,
                    decoration: InputDecoration(
                      labelText: "Rating",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: addPlayer,
                  child: Text("Agregar"),
                ),
              ],
            ),
            SizedBox(height: 16),
            // Opciones de generación
            Text(
              "Opciones de generación",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Text("Jugadores por equipo: "),
                DropdownButton<int>(
                  value: playersPerTeam,
                  items: [5, 6, 7]
                      .map((e) => DropdownMenuItem<int>(
                            value: e,
                            child: Text("$e"),
                          ))
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
                            value: e,
                            child: Text("$e"),
                          ))
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
                            value: e,
                            child: Text("$e"),
                          ))
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
            // Encabezado de jugadores
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Jugadores ($selectedCount seleccionados)",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                // Botón para alternar búsqueda
                TextButton(
                  onPressed: () {
                    setState(() {
                      isSearching = !isSearching;
                      if (!isSearching) {
                        searchQuery = '';
                        _searchController.clear();
                      }
                    });
                  },
                  child: Text(
                    "Busqueda",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            // Cuadro de búsqueda inline
            if (isSearching)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Buscar jugadores...",
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          searchQuery = '';
                          _searchController.clear();
                        });
                      },
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                ),
              ),
            // Botones "Ocultar", "Select All", "Deselect All"
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      showPlayers = !showPlayers;
                    });
                  },
                  child: Text(
                    showPlayers ? "Ocultar" : "Mostrar",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed: () => selectAll(true),
                  child: Text("Select All"),
                ),
                TextButton(
                  onPressed: () => selectAll(false),
                  child: Text("Deselect All"),
                ),
              ],
            ),
            SizedBox(height: 8),
            // Lista de jugadores
            if (showPlayers)
              Column(
                children: filteredPlayers.map((player) {
                  bool isSelected = selectedPlayers[player.id] ?? false;
                  int? order = isSelected
                      ? (selectedOrder.indexOf(player.id) + 1)
                      : null;
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
                                if (value == true &&
                                    !selectedOrder.contains(player.id)) {
                                  selectedOrder.add(player.id);
                                } else if (value == false) {
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
                                child: Text(
                                  "$order",
                                  style: TextStyle(fontSize: 12),
                                ),
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
                            onPressed: () => editPlayer(player),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => deletePlayer(player),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            SizedBox(height: 16),
            // Botones de acción (Agregar Jugador, Generar Equipos)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: generateTeamsAction,
                  child: Text("Generar Equipos"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
