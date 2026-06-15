import '../entities/conversation.dart';
import '../entities/message.dart';
import '../entities/ai_provider.dart';

/// Abstract contract that the data layer must fulfill.
/// All methods return a [Future] to keep the domain layer
/// agnostic of the underlying async mechanism (Hive, HTTP, etc.).
abstract class ChatRepository {
  /// Returns every stored [Conversation], ordered by [updatedAt] descending.
  Future<List<Conversation>> getConversations();

  /// Returns all [Message]s belonging to [conversationId],
  /// ordered by [timestamp] ascending.
  Future<List<Message>> getMessages(String conversationId);

  /// Persists a new [message] to local storage.
  Future<void> saveMessage(Message message);

  /// Creates a new [Conversation] or updates an existing one.
  /// Identified by [Conversation.id].
  Future<void> saveConversation(Conversation conversation);

  /// Deletes a [Conversation] and all of its associated [Message]s.
  Future<void> deleteConversation(String conversationId);

  /// Sends [message] to the AI backend described by [provider] and
  /// returns the assistant's reply as a [Message] entity.
  Future<Message> sendPrompt({
    required Message message,
    required AiProvider provider,
  });
}
