// lib/screens/generated_teams_screen.dart
import 'package:flutter/material.dart';
import '../models/team.dart';
import '../models/player.dart';
import '../services/team_storage_service.dart';
import 'dart:math';

class GeneratedTeamsScreen extends StatefulWidget {
  @override
  _GeneratedTeamsScreenState createState() => _GeneratedTeamsScreenState();
}

class _GeneratedTeamsScreenState extends State<GeneratedTeamsScreen> {
  List<Team> teams = [];
  List<Player> leftovers = [];
  bool isLoading = true;

  // Mapa para almacenar el cobrador asignado para cada equipo (por índice)
  Map<int, int> _teamCobradores = {};

  @override
  void initState() {
    super.initState();
    loadPersistedTeams();
  }

  Future<void> loadPersistedTeams() async {
    final result = await TeamStorageService.loadTeams();
    setState(() {
      teams = result["teams"];
      leftovers = result["leftovers"];
      isLoading = false;
      // Reiniciamos el mapa de cobradores (se asignarán cuando se muestre cada equipo)
      _teamCobradores.clear();
    });
  }

  Widget teamWidget(Team team, int teamNumber) {
    // Si ya se asignó un cobrador para este equipo, se usa ese; de lo contrario se asigna de forma aleatoria
    if (!_teamCobradores.containsKey(teamNumber)) {
      if (team.players.isNotEmpty) {
        _teamCobradores[teamNumber] =
            team.players[Random().nextInt(team.players.length)].id;
      }
    }
    int? cobradorId = _teamCobradores[teamNumber];

    return Card(
      margin: EdgeInsets.all(8),
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Equipo $teamNumber",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text("Total de jugadores: ${team.players.length}"),
            Text("Arquero: ${team.goalkeeper?.name ?? 'Ninguno'}", 
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
            Text("Puntuación Total: ${team.totalScore}"),
            SizedBox(height: 4),
            Text("Jugadores:"),
            ...team.players.asMap().entries.map((entry) {
              int index = entry.key;
              Player p = entry.value;
              // Si este jugador es el cobrador, se añade el símbolo ⚽
              String playerText = "  ${index + 1}. ${p.name} - ${p.rating}" +
                  (cobradorId == p.id ? " ⚽" : "");
              return Text(playerText);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget leftoversWidget(List<Player> leftovers) {
    return Card(
      margin: EdgeInsets.all(8),
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Jugadores Sobrantes:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (leftovers.isEmpty)
              Text("  Ninguno")
            else
              ...leftovers.asMap().entries.map((entry) {
                int index = entry.key;
                Player p = entry.value;
                return Text("  ${index + 1}. ${p.name} - ${p.rating}");
              }).toList(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text("Equipos Generados (Persistentes)")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("⚽ Equipos Generados ⚽", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            // Primera fila: Muestra equipos 1 y 2 lado a lado (si existen)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (teams.length >= 1) Expanded(child: teamWidget(teams[0], 1)),
                if (teams.length >= 2) Expanded(child: teamWidget(teams[1], 2)),
              ],
            ),
            // Segunda fila: Muestra equipos 3 y 4 (si existen)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (teams.length >= 3) Expanded(child: teamWidget(teams[2], 3)),
                if (teams.length >= 4) Expanded(child: teamWidget(teams[3], 4)),
              ],
            ),
            // Fila para mostrar jugadores sobrantes (si hay)
            if (leftovers.isNotEmpty)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: leftoversWidget(leftovers)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
