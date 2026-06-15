import 'package:uuid/uuid.dart';

import '../../domain/entities/ai_provider.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/ai_remote_data_source.dart';
import '../datasources/chat_local_data_source.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatLocalDataSource localDataSource;
  final AiRemoteDataSource remoteDataSource;
  final Uuid _uuid;

  /// [uuid] is injectable so tests can supply a seeded/predictable generator.
  ChatRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  // ---------------------------------------------------------------------------
  // Read — delegate entirely to local storage
  // ---------------------------------------------------------------------------

  @override
  Future<List<Conversation>> getConversations() =>
      localDataSource.getConversations();

  @override
  Future<List<Message>> getMessages(String conversationId) =>
      localDataSource.getMessages(conversationId);

  // ---------------------------------------------------------------------------
  // Write — persist to local storage
  // ---------------------------------------------------------------------------

  @override
  Future<void> saveMessage(Message message) =>
      localDataSource.saveMessage(message);

  @override
  Future<void> saveConversation(Conversation conversation) =>
      localDataSource.saveConversation(conversation);

  @override
  Future<void> deleteConversation(String conversationId) =>
      localDataSource.deleteConversation(conversationId);

  // ---------------------------------------------------------------------------
  // AI round-trip
  // ---------------------------------------------------------------------------

  @override
  Future<Message> sendPrompt({
    required Message message,
    required AiProvider provider,
  }) async {
    // 1. Fetch the saved conversation history.
    //    The Bloc already persisted the current user message before calling
    //    sendPrompt, so we exclude it by ID to avoid sending it twice in the
    //    context window (once in history, once as latestMessage).
    final allSaved =
        await localDataSource.getMessages(message.conversationId);
    final history =
        allSaved.where((m) => m.id != message.id).toList();

    // 2. Hit the remote API with the full context window.
    //    Throws [AiApiException] on non-200 or [TimeoutException] after 30 s.
    final assistantContent = await remoteDataSource.sendMessage(
      history: history,
      latestMessage: message,
      provider: provider,
    );

    // 3. Build a fully-formed domain entity for the assistant reply.
    final assistantMessage = Message(
      id: _uuid.v4(),
      conversationId: message.conversationId,
      role: MessageRole.assistant,
      content: assistantContent,
      timestamp: DateTime.now(),
    );

    // 4. Persist the reply.
    await localDataSource.saveMessage(assistantMessage);

    // 5. Refresh the parent conversation's [updatedAt] so the
    //    ConversationListScreen re-sorts by last activity correctly.
    final conversations = await localDataSource.getConversations();
    final parent = conversations.firstWhere(
      (c) => c.id == message.conversationId,
      orElse: () => throw StateError(
        'Conversation ${message.conversationId} not found after save.',
      ),
    );
    await localDataSource.saveConversation(
      parent.copyWith(updatedAt: DateTime.now()),
    );

    return assistantMessage;
  }
}
