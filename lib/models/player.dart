class Player {
  int id;
  String name;
  int rating;

  Player({required this.id, required this.name, required this.rating});

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'rating': rating,
      };

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'],
      name: json['name'],
      rating: json['rating'],
    );
  }
}
