enum GameItemType { food, medicine, toy }

class GameItem {
  final String id;
  final String name;
  final String imagePath;
  final GameItemType type;
  final int count;
  final String description;
  final int requiredLevel; // Add requiredLevel
  final String unlockMessage; // Add unlockMessage
  final String audioPath; // Audio path for the reward item

  const GameItem({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.type,
    this.count = 0,
    this.description = '',
    this.requiredLevel = 1, // Default is 1
    this.unlockMessage = '', // Default is empty
    this.audioPath = '', // Default is empty
  });

  GameItem copyWith({
    String? id,
    String? name,
    String? imagePath,
    GameItemType? type,
    int? count,
    String? description,
    int? requiredLevel,
    String? unlockMessage,
    String? audioPath,
  }) {
    return GameItem(
      id: id ?? this.id,
      name: name ?? this.name,
      imagePath: imagePath ?? this.imagePath,
      type: type ?? this.type,
      count: count ?? this.count,
      description: description ?? this.description,
      requiredLevel: requiredLevel ?? this.requiredLevel,
      unlockMessage: unlockMessage ?? this.unlockMessage,
      audioPath: audioPath ?? this.audioPath,
    );
  }
}
