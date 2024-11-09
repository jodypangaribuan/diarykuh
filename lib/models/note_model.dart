class Note {
  final int? id;
  final String userId; // Add this field
  final String title;
  final String content;
  final String mood;
  final String timestamp;
  final String? voicePath;
  final String? imagePath;
  final List<String>? imagePaths; // Update to support multiple images

  Note({
    this.id,
    required this.userId, // Add this field
    required this.title,
    required this.content,
    required this.mood,
    required this.timestamp,
    this.voicePath,
    this.imagePath,
    this.imagePaths = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId, // Add this field
      'title': title,
      'content': content,
      'mood': mood,
      'timestamp': timestamp,
      'voicePath': voicePath,
      'imagePath': imagePath,
      'imagePaths': imagePaths?.join(','), // Store as comma-separated string
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    String? imagePaths = map['imagePaths'];
    List<String> paths = [];
    if (imagePaths != null && imagePaths.isNotEmpty) {
      paths = imagePaths.split(',').where((e) => e.isNotEmpty).toList();
    }

    return Note(
      id: map['id'],
      userId: map['user_id'] ?? 'default_user', // Add this field with default
      title: map['title'],
      content: map['content'],
      mood: map['mood'],
      timestamp: map['timestamp'],
      voicePath: map['voicePath'],
      imagePath: map['imagePath'],
      imagePaths: paths,
    );
  }
}
