import 'package:flutter/material.dart';
import '../models/player.dart';
import '../models/team.dart';
import '../services/storage_service.dart';
import '../services/team_service.dart';
import '../services/team_storage_service.dart';

class PlayersGenerateScreen extends StatefulWidget {
  const PlayersGenerateScreen({super.key});

  @override
  _PlayersGenerateScreenState createState() => _PlayersGenerateScreenState();
}

class _PlayersGenerateScreenState extends State<PlayersGenerateScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ratingController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  String searchQuery = '';    // Siempre mostrará el TextField de búsqueda
  bool showPlayers = true;    // Para mostrar/ocultar la lista de jugadores

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
                        })
                      ],
                    ),
                  );
                }),
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
                  })
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

  // Método auxiliar para contar los jugadores seleccionados.
  int _countSelected() {
    return selectedPlayers.values.where((v) => v).length;
  }

  // --- Widgets para el encabezado fijo ---
  Widget _buildSliverPersistentHeader(BuildContext context, bool innerBoxIsScrolled) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila: Encabezado (Jugadores (X) seleccionados) + Cuadro de búsqueda SIEMPRE visible
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Jugadores (${_countSelected()} seleccionados)",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              // Se quita el botón "Busqueda" y se muestra el TextField directamente
              
            ],
          ),
          SizedBox(
                width: 250,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Busca tu cojo...",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
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
          SizedBox(height: 8),
          // Fila: Botones "Ocultar", "Select All" y "Deselect All"
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
        ],
      ),
    );
  }

  // Delegate para SliverPersistentHeader
  SliverPersistentHeaderDelegate _buildSliverDelegate() {
    return _MySliverDelegate(
      minHeight: 147,
      maxHeight: 147,
      child: _buildSliverPersistentHeader(context, false),
    );
  }
  // --- Fin de widgets de encabezado fijo ---

  @override
  Widget build(BuildContext context) {
    // Filtrar jugadores según búsqueda.
    List<Player> filteredPlayers = players.where((player) {
      return player.name.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text("⚽ PICHANGEROS ⚽", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // Parte superior: Agregar Jugador y Opciones de generación.
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                  ],
                ),
              ),
            ),
            // Encabezado fijo: Jugadores, búsqueda y botones
            SliverPersistentHeader(
              pinned: true,
              delegate: _buildSliverDelegate(),
            ),
          ];
        },
        body: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: true,
              child: Column(
                children: [
                  // Lista de jugadores (scrollable)
                  if (showPlayers)
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        itemCount: filteredPlayers.length,
                        itemBuilder: (context, index) {
                          final player = filteredPlayers[index];
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
                        },
                      ),
                    ),
                  // Botón "Generar Equipos" al final (una sola vez)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: ElevatedButton(
                      onPressed: generateTeamsAction,
                      child: Text("Generar Equipos"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Delegate para SliverPersistentHeader
class _MySliverDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _MySliverDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _MySliverDelegate oldDelegate) {
    return minHeight != oldDelegate.minHeight ||
        maxHeight != oldDelegate.maxHeight ||
        child != oldDelegate.child;
  }
}
