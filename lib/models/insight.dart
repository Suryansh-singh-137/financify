class Insight {
  final String id;
  final String type; // 'overspend', 'spike', 'subscription', 'savings', 'general'
  final String title;
  final String body;
  final DateTime createdAt;
  bool seen;

  Insight({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    DateTime? createdAt,
    this.seen = false,
  }) : createdAt = createdAt ?? DateTime.now();

  String get emoji {
    switch (type) {
      case 'overspend':
        return '⚠️';
      case 'spike':
        return '📈';
      case 'subscription':
        return '🔄';
      case 'savings':
        return '💰';
      case 'budget':
        return '🎯';
      default:
        return '💡';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'body': body,
      'created_at': createdAt.toIso8601String(),
      'seen': seen ? 1 : 0,
    };
  }

  factory Insight.fromMap(Map<String, dynamic> map) {
    return Insight(
      id: map['id'] as String,
      type: map['type'] as String,
      title: map['title'] as String,
      body: map['body'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      seen: (map['seen'] as int?) == 1,
    );
  }
}
