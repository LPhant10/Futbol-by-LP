import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/team.dart';
import '../models/player.dart';

class TeamStorageService {
  static const String teamsKey = 'generatedTeams';
  static const String leftoversKey = 'generatedLeftovers';

  // Guarda los equipos y jugadores sobrantes (persistente)
  static Future<void> saveTeams(List<Team> teams, List<Player> leftovers) async {
    final prefs = await SharedPreferences.getInstance();
    // Convertir cada equipo a JSON (asumiendo que Team tiene toJson() y fromJson())
    List<String> teamsJson =
        teams.map((team) => jsonEncode(team.toJson())).toList();
    List<String> leftoversJson =
        leftovers.map((player) => jsonEncode(player.toJson())).toList();
    await prefs.setStringList(teamsKey, teamsJson);
    await prefs.setStringList(leftoversKey, leftoversJson);
  }

  // Carga los equipos y jugadores sobrantes
  static Future<Map<String, dynamic>> loadTeams() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? teamsJson = prefs.getStringList(teamsKey);
    List<String>? leftoversJson = prefs.getStringList(leftoversKey);
    List<Team> teams = [];
    List<Player> leftovers = [];
    if (teamsJson != null) {
      teams = teamsJson
          .map((teamStr) => Team.fromJson(jsonDecode(teamStr)))
          .toList();
    }
    if (leftoversJson != null) {
      leftovers = leftoversJson
          .map((playerStr) => Player.fromJson(jsonDecode(playerStr)))
          .toList();
    }
    return {"teams": teams, "leftovers": leftovers};
  }
}
