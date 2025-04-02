// Aquí pondrás toda la lógica de generación y balanceo de equipos

import 'dart:math';
import '../models/player.dart';
import '../models/team.dart';

void balanceTeams(List<Team> teams, int playersPerTeam,
    {int maxDifference = 1}) {
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

Map<String, dynamic> generateFieldTeams(
    List<Player> players, int playersPerTeam, int numberOfTeams,
    {int maxDifference = 1}) {
  players.sort((a, b) => b.rating.compareTo(a.rating));
  List<Team> teams = List.generate(numberOfTeams, (_) => Team());
  List<Player> leftovers = [];

  for (var player in players) {
    // Buscar equipo con espacio y menor totalScore
    Team? bestTeam;
    for (var team in teams) {
      if (team.players.length < playersPerTeam) {
        if (bestTeam == null || team.totalScore < bestTeam.totalScore) {
          bestTeam = team;
        }
      }
    }

    if (bestTeam != null) {
      bestTeam.players.add(player);
      bestTeam.totalScore += player.rating;
    } else {
      leftovers.add(player); // Ya no hay espacio
    }
  }

  balanceTeams(teams, playersPerTeam, maxDifference: maxDifference);
  return {"teams": teams, "leftovers": leftovers};
}


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
    if (teams[i].players.isNotEmpty) {
    teams[i].cobradorId =
        teams[i].players[Random().nextInt(teams[i].players.length)].id;
  }
  }
  return {"teams": teams, "leftovers": leftovers};
}
