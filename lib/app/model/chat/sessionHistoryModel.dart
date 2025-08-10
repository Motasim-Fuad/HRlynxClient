class SessionHistory {
  final String id;
  final String title;
  final int messageCount;
  final int tokensUsed;
  final LastMessage? lastMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  SessionHistory({
    required this.id,
    required this.title,
    required this.messageCount,
    required this.tokensUsed,
    this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SessionHistory.fromJson(Map<String, dynamic> json) {
    return SessionHistory(
      id: json['id'].toString(),
      title: json['title'],
      messageCount: json['message_count'],
      tokensUsed: json['tokens_used'],
      lastMessage: json['last_message'] != null
          ? LastMessage.fromJson(json['last_message'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class LastMessage {
  final String content;
  final bool isUser;
  final DateTime createdAt;

  LastMessage({
    required this.content,
    required this.isUser,
    required this.createdAt,
  });

  factory LastMessage.fromJson(Map<String, dynamic> json) {
    return LastMessage(
      content: json['content'],
      isUser: json['is_user'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}