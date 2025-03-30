// Para guardar y cargar los equipos generados
// lib/services/team_storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/team.dart';
import '../models/player.dart';

class TeamStorageService {
  static Future<void> saveTeams(List<Team> teams, List<Player> leftovers) async {
    final prefs = await SharedPreferences.getInstance();
    String teamsString = jsonEncode(teams.map((t) => t.toJson()).toList());
    await prefs.setString("generated_teams", teamsString);
    String leftoversString =
        jsonEncode(leftovers.map((p) => p.toJson()).toList());
    await prefs.setString("leftover_players", leftoversString);
  }

  static Future<Map<String, dynamic>> loadTeams() async {
    final prefs = await SharedPreferences.getInstance();
    String? teamsString = prefs.getString("generated_teams");
    String? leftoversString = prefs.getString("leftover_players");

    List<Team> teams = [];
    List<Player> leftovers = [];

    if (teamsString != null) {
      final teamsJson = jsonDecode(teamsString) as List;
      teams = teamsJson.map((json) => Team.fromJson(json)).toList();
    }

    if (leftoversString != null) {
      final leftoversJson = jsonDecode(leftoversString) as List;
      leftovers =
          leftoversJson.map((json) => Player.fromJson(json)).toList();
    }

    return {"teams": teams, "leftovers": leftovers};
  }
}