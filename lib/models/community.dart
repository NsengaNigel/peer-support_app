class Community {
  final String id;
  final String name;
  final String description;
  final int memberCount;

  Community({
    required this.id,
    required this.name,
    required this.description,
    this.memberCount = 0,
  });

  factory Community.fromMap(Map<String, dynamic> data, String id) {
    return Community(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      memberCount: data['memberCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'memberCount': memberCount,
    };
  }
} 