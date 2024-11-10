class Note {
  final int? id;
  final String userId;
  final String title;
  final String content;
  final String mood;
  final String timestamp;
  final String? voicePath;
  final String? imagePath;
  final List<String>? imagePaths;

  Note({
    this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.mood,
    required this.timestamp,
    this.voicePath,
    this.imagePath,
    this.imagePaths = const [],
  });

  Note copyWith({
    int? id,
    String? userId,
    String? title,
    String? content,
    String? mood,
    String? timestamp,
    String? voicePath,
    String? imagePath,
    List<String>? imagePaths,
  }) {
    return Note(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      mood: mood ?? this.mood,
      timestamp: timestamp ?? this.timestamp,
      voicePath: voicePath ?? this.voicePath,
      imagePath: imagePath ?? this.imagePath,
      imagePaths: imagePaths ?? this.imagePaths,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'content': content,
      'mood': mood,
      'timestamp': timestamp,
      'voicePath': voicePath,
      'imagePath': imagePath,
      'imagePaths': imagePaths?.join(','),
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
      userId: map['user_id'] ?? 'default_user',
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
