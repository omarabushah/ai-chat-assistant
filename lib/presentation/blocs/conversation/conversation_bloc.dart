import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/entities/conversation.dart';
import '../../../domain/repositories/chat_repository.dart';
import 'conversation_event.dart';
import 'conversation_state.dart';

class ConversationBloc extends Bloc<ConversationEvent, ConversationState> {
  final ChatRepository chatRepository;
  final Uuid _uuid;

  ConversationBloc({
    required this.chatRepository,
    Uuid? uuid,
  })  : _uuid = uuid ?? const Uuid(),
        super(const ConversationLoading()) {
    on<LoadConversations>(_onLoadConversations);
    on<CreateConversation>(_onCreateConversation);
    on<DeleteConversation>(_onDeleteConversation);
  }

  // ---------------------------------------------------------------------------
  // Event handlers
  // ---------------------------------------------------------------------------

  Future<void> _onLoadConversations(
    LoadConversations event,
    Emitter<ConversationState> emit,
  ) async {
    emit(const ConversationLoading());
    try {
      final conversations = await chatRepository.getConversations();
      emit(
        conversations.isEmpty
            ? const ConversationEmpty()
            : ConversationLoaded(conversations),
      );
    } catch (e) {
      emit(ConversationError('Failed to load conversations: $e'));
    }
  }

  Future<void> _onCreateConversation(
    CreateConversation event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      final now = DateTime.now();
      final conversation = Conversation(
        id: _uuid.v4(),
        title: event.title.trim().isEmpty ? 'New chat' : event.title.trim(),
        createdAt: now,
        updatedAt: now,
      );

      await chatRepository.saveConversation(conversation);

      // Reload from source-of-truth to keep ordering consistent.
      final conversations = await chatRepository.getConversations();
      emit(ConversationLoaded(conversations));
    } catch (e) {
      emit(ConversationError('Failed to create conversation: $e'));
    }
  }

  Future<void> _onDeleteConversation(
    DeleteConversation event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      await chatRepository.deleteConversation(event.conversationId);

      final conversations = await chatRepository.getConversations();
      emit(
        conversations.isEmpty
            ? const ConversationEmpty()
            : ConversationLoaded(conversations),
      );
    } catch (e) {
      emit(ConversationError('Failed to delete conversation: $e'));
    }
  }
}
