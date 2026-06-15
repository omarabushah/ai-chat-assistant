import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';

abstract class ChatLocalDataSource {
  Future<List<Conversation>> getConversations();
  Future<List<Message>> getMessages(String conversationId);
  Future<void> saveConversation(Conversation conversation);
  Future<void> saveMessage(Message message);
  Future<void> deleteConversation(String conversationId);
}

class ChatLocalDataSourceImpl implements ChatLocalDataSource {
  static const String _conversationsBoxName = 'conversations';
  static const String _messagesBoxName = 'messages';

  /// Returns the already-open box or opens it for the first time.
  /// Hive.openBox() is idempotent — safe to call on every access.
  Future<Box<dynamic>> get _conversationsBox async =>
      Hive.isBoxOpen(_conversationsBoxName)
          ? Hive.box(_conversationsBoxName)
          : await Hive.openBox(_conversationsBoxName);

  Future<Box<dynamic>> get _messagesBox async =>
      Hive.isBoxOpen(_messagesBoxName)
          ? Hive.box(_messagesBoxName)
          : await Hive.openBox(_messagesBoxName);

  // ---------------------------------------------------------------------------
  // Read operations
  // ---------------------------------------------------------------------------

  @override
  Future<List<Conversation>> getConversations() async {
    final box = await _conversationsBox;
    final conversations = box.values
        .map((e) => _conversationFromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
    // Most-recently updated first.
    conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return conversations;
  }

  @override
  Future<List<Message>> getMessages(String conversationId) async {
    final box = await _messagesBox;
    final messages = box.values
        .map((e) => _messageFromMap(Map<String, dynamic>.from(e as Map)))
        .where((m) => m.conversationId == conversationId)
        .toList();
    // Chronological order for display.
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return messages;
  }

  // ---------------------------------------------------------------------------
  // Write operations
  // ---------------------------------------------------------------------------

  @override
  Future<void> saveConversation(Conversation conversation) async {
    final box = await _conversationsBox;
    await box.put(conversation.id, _conversationToMap(conversation));
  }

  @override
  Future<void> saveMessage(Message message) async {
    final box = await _messagesBox;
    await box.put(message.id, _messageToMap(message));
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    final conversationsBox = await _conversationsBox;
    await conversationsBox.delete(conversationId);

    // Cascade-delete every message that belongs to this conversation.
    final messagesBox = await _messagesBox;
    final keysToDelete = messagesBox.keys.where((key) {
      final raw = messagesBox.get(key);
      if (raw == null) return false;
      final map = Map<String, dynamic>.from(raw as Map);
      return map['conversationId'] == conversationId;
    }).toList();
    await messagesBox.deleteAll(keysToDelete);
  }

  // ---------------------------------------------------------------------------
  // Private serialisation helpers — plain maps, no build_runner required
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _conversationToMap(Conversation c) => {
        'id': c.id,
        'title': c.title,
        'createdAt': c.createdAt.toIso8601String(),
        'updatedAt': c.updatedAt.toIso8601String(),
      };

  Conversation _conversationFromMap(Map<String, dynamic> map) => Conversation(
        id: map['id'] as String,
        title: map['title'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: DateTime.parse(map['updatedAt'] as String),
      );

  Map<String, dynamic> _messageToMap(Message m) => {
        'id': m.id,
        'conversationId': m.conversationId,
        // Persist the enum as its name string so it survives app restarts.
        'role': m.role.name,
        'content': m.content,
        'timestamp': m.timestamp.toIso8601String(),
      };

  Message _messageFromMap(Map<String, dynamic> map) => Message(
        id: map['id'] as String,
        conversationId: map['conversationId'] as String,
        role: MessageRole.values.firstWhere(
          (r) => r.name == map['role'],
        ),
        content: map['content'] as String,
        timestamp: DateTime.parse(map['timestamp'] as String),
      );
}
