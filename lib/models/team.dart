import 'player.dart';

class Team {
  List<Player> players;
  int totalScore;
  Player? goalkeeper;
  int? cobradorId;
  

  Team({List<Player>? players, this.totalScore = 0, this.goalkeeper, this.cobradorId,})
      : players = players ?? [];

  Map<String, dynamic> toJson() {
    return {
      'players': players.map((p) => p.toJson()).toList(),
      'totalScore': totalScore,
      'goalkeeper': goalkeeper?.toJson(),
      'cobradorId': cobradorId,
      
    };
  }

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      players: (json['players'] as List)
          .map((p) => Player.fromJson(p))
          .toList(),
      totalScore: json['totalScore'],
      goalkeeper: json['goalkeeper'] != null
          ? Player.fromJson(json['goalkeeper'])
          : null,
      cobradorId: json['cobradorId'],
    );
  }
}