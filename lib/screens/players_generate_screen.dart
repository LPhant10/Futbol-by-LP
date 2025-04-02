import 'package:flutter/material.dart';
import 'package:sorteo_lp/screens/team_generator_page.dart';
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

  String searchQuery = '';
  bool showPlayers = true;

  List<Player> players = [];
  Map<int, bool> selectedPlayers = {};
  List<int> selectedOrder = [];

  int playersPerTeam = 5;
  int numberOfTeams = 2;
  int maxDifference = 5;

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
      builder:
          (_) => AlertDialog(
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
      builder:
          (_) => AlertDialog(
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
        builder:
            (_) => AlertDialog(
              title: Text(
                "Equipos Generados",
                style: TextStyle(color: Colors.red),
              ),
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
                            Text(
                              "Arquero: ${team.goalkeeper?.name ?? 'Ninguno'}",
                            ),
                            Text("Puntuación Total: ${team.totalScore}"),
                            SizedBox(height: 4),
                            Text("Jugadores:"),
                            ...team.players.asMap().entries.map((e) {
                              int i = e.key;
                              var p = e.value;
                              return Text(
                                "  ${i + 1}. ${p.name} - ${p.rating}",
                              );
                            }),
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
                      }),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  int _countSelected() {
    return selectedPlayers.values.where((v) => v).length;
  }

  @override
  Widget build(BuildContext context) {
    List<Player> filteredPlayers =
        players
            .where(
              (p) => p.name.toLowerCase().contains(searchQuery.toLowerCase()),
            )
            .toList();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,

        /* appBar: AppBar(
      title: Text("⚽ PICHANGEROS ⚽", style: TextStyle(color: Colors.white)),
      backgroundColor: Colors.transparent,
      
        ),  */
        body: Stack(
          children: [
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: 0.25,
                duration: Duration(milliseconds: 300),
                child: Image.asset('assets/pichangeros.jpg', fit: BoxFit.cover),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16.0,
                      horizontal: 8.0,
                    ),
                    child: Row(
                      children: [
                        // Botón de retroceso alineado a la izquierda
                        IconButton(
  icon: Icon(Icons.arrow_back, color: Colors.white),
  onPressed: () {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const TeamGeneratorPage(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  },
),


                        // Espacio para centrar el título visualmente
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Icon(Icons.sports_soccer, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                "PICHANGEROS",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.sports_soccer, color: Colors.white),
                            ],
                          ),
                        ),

                        // Ícono invisible para balancear el espacio del botón de retroceso
                        AnimatedOpacity(
                          duration: Duration(milliseconds: 300),
                          opacity: 0,
                          child: IconButton(
                            icon: Icon(Icons.arrow_back),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Encabezado fijo con opciones y agregar jugador
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Opciones de generación",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              "Jugadores por equipo: ",
                              style: TextStyle(color: Colors.white),
                            ),
                            DropdownButton<int>(
                              dropdownColor: Colors.black,
                              value: playersPerTeam,
                              items:
                                  [5, 6, 7]
                                      .map(
                                        (e) => DropdownMenuItem<int>(
                                          value: e,
                                          child: Text(
                                            "$e",
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                              onChanged:
                                  (value) => setState(
                                    () => playersPerTeam = value ?? 5,
                                  ),
                            ),
                            SizedBox(width: 16),
                            Text(
                              "Número de equipos: ",
                              style: TextStyle(color: Colors.white),
                            ),
                            DropdownButton<int>(
                              dropdownColor: Colors.black,
                              value: numberOfTeams,
                              items:
                                  [2, 3, 4]
                                      .map(
                                        (e) => DropdownMenuItem<int>(
                                          value: e,
                                          child: Text(
                                            "$e",
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                              onChanged:
                                  (value) => setState(
                                    () => numberOfTeams = value ?? 2,
                                  ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              "Diferencia máxima: ",
                              style: TextStyle(color: Colors.white),
                            ),
                            DropdownButton<int>(
                              dropdownColor: Colors.black,
                              value: maxDifference,
                              items:
                                  [1, 2, 3, 4, 5]
                                      .map(
                                        (e) => DropdownMenuItem<int>(
                                          value: e,
                                          child: Text(
                                            "$e",
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                              onChanged:
                                  (value) => setState(
                                    () => maxDifference = value ?? 1,
                                  ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          "Agregar Jugador",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _nameController,
                                style: TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: "Nombre",
                                  labelStyle: TextStyle(color: Colors.white70),
                                  filled: true,
                                  fillColor: Colors.black.withOpacity(0.3),
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _ratingController,
                                style: TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: "Rating",
                                  labelStyle: TextStyle(color: Colors.white70),
                                  filled: true,
                                  fillColor: Colors.black.withOpacity(0.3),
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
                        SizedBox(height: 12),
                        Row(
                          children: [
                            // Buscador (50%)
                            Expanded(
                              flex: 1,
                              child: TextField(
                                controller: _searchController,
                                style: TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  hintText: "Busca tu cojo...",

                                  hintStyle: TextStyle(color: Colors.white),
                                  filled: true,
                                  fillColor: Colors.black.withOpacity(0.3),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      color: Colors.white,
                                    ),
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

                            SizedBox(width: 8),

                            // Botón "Seleccionar Todo"
                            ElevatedButton(
                              onPressed: () => selectAll(true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              child: Text(
                                " Todo",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),

                            SizedBox(width: 4),

                            // Botón "Deseleccionar Todo"
                            ElevatedButton(
                              onPressed: () => selectAll(false),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: Text(
                                " Ninguno",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Jugadores seleccionados: ${_countSelected()}",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Scrollable lista de jugadores
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      itemCount: filteredPlayers.length,
                      itemBuilder: (context, index) {
                        final player = filteredPlayers[index];
                        bool isSelected = selectedPlayers[player.id] ?? false;
                        int? order =
                            isSelected
                                ? (selectedOrder.indexOf(player.id) + 1)
                                : null;

                        return Card(
                          color: Colors.black.withOpacity(0.3),
                          child: ListTile(
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Checkbox(
                                  value: isSelected,
                                  onChanged: (value) {
                                    setState(() {
                                      selectedPlayers[player.id] =
                                          value ?? false;
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
                                      backgroundColor: Colors.blue,
                                      child: Text(
                                        "$order",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            title: Text(
                              player.name,
                              style: TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              "Rating: ${player.rating}",
                              style: TextStyle(color: Colors.white70),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.white),
                                  onPressed: () => editPlayer(player),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.white),
                                  onPressed: () => deletePlayer(player),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Botón fijo
                  Padding(
                    padding: const EdgeInsets.all(12.0),
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
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _MySliverDelegate oldDelegate) {
    return minHeight != oldDelegate.minHeight ||
        maxHeight != oldDelegate.maxHeight ||
        child != oldDelegate.child;
  }
}
