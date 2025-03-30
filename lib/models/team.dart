import 'player.dart';

class Team {
  List<Player> players;
  int totalScore;
  Player? goalkeeper;

  Team({List<Player>? players, this.totalScore = 0, this.goalkeeper})
      : players = players ?? [];
}
