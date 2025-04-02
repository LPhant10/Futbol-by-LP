import 'package:flutter/material.dart';
import '../models/team.dart';
import '../models/player.dart';
import '../services/team_storage_service.dart';

class GeneratedTeamsScreen extends StatefulWidget {
  const GeneratedTeamsScreen({super.key});

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
    int? cobradorId = team.cobradorId;

    return Card(
      margin: EdgeInsets.all(8),
      color: Colors.white.withOpacity(0.6),
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Equipo $teamNumber",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text("Total de jugadores: ${team.players.length}",style: TextStyle(fontWeight: FontWeight.bold),),
            Text(
              "Arquero: ${team.goalkeeper?.name ?? 'Ninguno'}",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text("Puntuación Total: ${team.totalScore}",style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            if (cobradorId != null)
              Text(
                "Cobrador: ${team.players.firstWhere(
                      (p) => p.id == cobradorId,
                      orElse: () => team.players.first,
                    ).name} ⚽",style: TextStyle(fontWeight: FontWeight.bold)
              )
            else
              Text("Cobrador: Ninguno",style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text("Jugadores:", style: TextStyle(fontWeight: FontWeight.bold)),
            ...team.players.asMap().entries.map((entry) {
              int index = entry.key;
              Player p = entry.value;
              String playerText =
                  "  ${index + 1}. ${p.name} - ${p.rating}${cobradorId == p.id ? " ⚽" : ""}";
              return Text(playerText,style: TextStyle(fontWeight: FontWeight.bold));
            }),
          ],
        ),
      ),
    );
  }

  Widget leftoversWidget(List<Player> leftovers) {
    return Card(
      margin: EdgeInsets.all(8),
      color: Colors.white.withOpacity(0.6),
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
              Text("  Ninguno", style: TextStyle(fontWeight: FontWeight.bold))
            else
              ...leftovers.asMap().entries.map((entry) {
                int index = entry.key;
                Player p = entry.value;
                return Text("  ${index + 1}. ${p.name} - ${p.rating}", style: TextStyle(fontWeight: FontWeight.bold));
              }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Stack(
        children: [
          // Fondo
          Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: Image.asset("assets/egene.jpg", fit: BoxFit.cover),
            ),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      FocusManager.instance.primaryFocus?.unfocus();
                      Navigator.pop(context);
                    },
                  ),
                  // Botón y título
                  Padding(
                    padding: const EdgeInsets.all(25.0),
                    child: Row(
                      children: [
                        Icon(Icons.sports_soccer, color: Colors.white, size: 30),
                        SizedBox(width: 8),
                        Text(
                          'EQUIPOS GENERADOS',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.sports_soccer, color: Colors.white, size: 30),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (teams.isNotEmpty)
                                Expanded(child: teamWidget(teams[0], 1)),
                              if (teams.length >= 2)
                                Expanded(child: teamWidget(teams[1], 2)),
                            ],
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (teams.length >= 3)
                                Expanded(child: teamWidget(teams[2], 3)),
                              if (teams.length >= 4)
                                Expanded(child: teamWidget(teams[3], 4)),
                            ],
                          ),
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
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
