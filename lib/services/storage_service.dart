// Aquí centralizas la lógica de carga y guardado en SharedPreferences
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player.dart';

class StorageService {
  static Future<List<Player>> loadPlayers() async {
    final prefs = await SharedPreferences.getInstance();
    String? playersString = prefs.getString("players");
    if (playersString != null) {
      List<dynamic> playersJson = jsonDecode(playersString);
      return playersJson.map((e) => Player.fromJson(e)).toList();
    }
    return [];
  }

  static Future<void> savePlayers(List<Player> players) async {
    final prefs = await SharedPreferences.getInstance();
    String playersString = jsonEncode(players.map((p) => p.toJson()).toList());
    await prefs.setString("players", playersString);
  }
}
