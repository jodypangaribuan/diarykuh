class Note {
  final int? id;
  final String title;
  final String content;
  final String mood;
  final String timestamp;
  final String? voicePath;
  final String? imagePath;

  Note({
    this.id,
    required this.title,
    required this.content,
    required this.mood,
    required this.timestamp,
    this.voicePath,
    this.imagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'mood': mood,
      'timestamp': timestamp,
      'voicePath': voicePath,
      'imagePath': imagePath,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      mood: map['mood'],
      timestamp: map['timestamp'],
      voicePath: map['voicePath'],
      imagePath: map['imagePath'],
    );
  }
}
