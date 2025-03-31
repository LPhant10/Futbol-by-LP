import 'package:flutter/material.dart';
import '../models/team.dart';
import '../models/player.dart';
import '../services/team_storage_service.dart';

class GeneratedTeamsScreen extends StatefulWidget {
  @override
  _GeneratedTeamsScreenState createState() => _GeneratedTeamsScreenState();
}

class _GeneratedTeamsScreenState extends State<GeneratedTeamsScreen> {
  List<Team> teams = [];
  List<Player> leftovers = [];
  bool isLoading = true;

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
    });
  }

  Widget teamWidget(Team team, int teamNumber) {
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
            Text("Arquero: ${team.goalkeeper?.name ?? 'Ninguno'}"),
            Text("Puntuación Total: ${team.totalScore}"),
            SizedBox(height: 4),
            Text("Jugadores:"),
            ...team.players.asMap().entries.map((entry) {
              int index = entry.key;
              Player p = entry.value;
              return Text("  ${index + 1}. ${p.name} - ${p.rating}");
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
        title: Text(
          "⚽ Equipos Generados ⚽ ",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            // Primera fila: Equipo 1 y Equipo 2 (lado a lado)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (teams.length >= 1) Expanded(child: teamWidget(teams[0], 1)),
                if (teams.length >= 2) Expanded(child: teamWidget(teams[1], 2)),
              ],
            ),
            // Segunda fila: Equipo 3 y Sobrantes (lado a lado)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (teams.length >= 3) Expanded(child: teamWidget(teams[2], 3)),
                if (teams.length >= 4) Expanded(child: teamWidget(teams[3], 4)),

                
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                if (leftovers.isNotEmpty)
                  Expanded(child: leftoversWidget(leftovers)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
