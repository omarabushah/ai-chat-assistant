import 'package:equatable/equatable.dart';

enum MessageRole { user, assistant }

class Message extends Equatable {
  final String id;
  final String conversationId;
  final MessageRole role;
  final String content;
  final DateTime timestamp;

  const Message({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.timestamp,
  });

  Message copyWith({
    String? id,
    String? conversationId,
    MessageRole? role,
    String? content,
    DateTime? timestamp,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  List<Object?> get props => [id, conversationId, role, content, timestamp];
}
