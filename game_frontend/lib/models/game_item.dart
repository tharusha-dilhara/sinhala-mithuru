enum GameItemType { food, medicine, toy }

class GameItem {
  final String id;
  final String name;
  final String imagePath;
  final GameItemType type;
  final int count;
  final String description;

  const GameItem({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.type,
    this.count = 0,
    this.description = '',
  });

  GameItem copyWith({
    String? id,
    String? name,
    String? imagePath,
    GameItemType? type,
    int? count,
    String? description,
  }) {
    return GameItem(
      id: id ?? this.id,
      name: name ?? this.name,
      imagePath: imagePath ?? this.imagePath,
      type: type ?? this.type,
      count: count ?? this.count,
      description: description ?? this.description,
    );
  }
}
