import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/entities/message.dart';
import '../../../domain/errors/chat_exceptions.dart';
import '../../../domain/repositories/chat_repository.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository chatRepository;
  final Uuid _uuid;

  ChatBloc({
    required this.chatRepository,
    Uuid? uuid,
  })  : _uuid = uuid ?? const Uuid(),
        super(const ChatInitial()) {
    on<LoadChat>(_onLoadChat);
    on<SendMessage>(_onSendMessage);
  }

  // ---------------------------------------------------------------------------
  // Event handlers
  // ---------------------------------------------------------------------------

  Future<void> _onLoadChat(
    LoadChat event,
    Emitter<ChatState> emit,
  ) async {
    // Show loading with an empty list — no previous messages visible yet.
    emit(ChatLoading(messages: const [], conversationId: event.conversationId));
    try {
      final messages = await chatRepository.getMessages(event.conversationId);
      emit(ChatSuccess(
        messages: messages,
        conversationId: event.conversationId,
      ));
    } catch (e) {
      emit(ChatError(
        message: 'Failed to load messages: $e',
        previousMessages: const [],
        conversationId: event.conversationId,
      ));
    }
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    // SendMessage is only valid when a conversation is loaded or in an error
    // state with a recoverable message list. Guard all other states.
    final currentState = state;
    if (currentState is! ChatSuccess && currentState is! ChatError) return;

    final String conversationId;
    final List<Message> existingMessages;

    if (currentState is ChatSuccess) {
      conversationId = currentState.conversationId;
      existingMessages = currentState.messages;
    } else {
      final errorState = currentState as ChatError;
      conversationId = errorState.conversationId;
      existingMessages = errorState.previousMessages;
    }

    // ── Step 1: Build and persist the user message ──────────────────────────
    final userMessage = Message(
      id: _uuid.v4(),
      conversationId: conversationId,
      role: MessageRole.user,
      content: event.content.trim(),
      timestamp: DateTime.now(),
    );

    try {
      await chatRepository.saveMessage(userMessage);
    } catch (e) {
      emit(ChatError(
        message: 'Failed to save message: $e',
        previousMessages: existingMessages,
        conversationId: conversationId,
      ));
      return;
    }

    // ── Step 2: Optimistic UI — show the user's message immediately ──────────
    final optimisticMessages = List<Message>.unmodifiable([
      ...existingMessages,
      userMessage,
    ]);

    emit(ChatLoading(
      messages: optimisticMessages,
      conversationId: conversationId,
    ));

    // ── Step 3: AI round-trip ────────────────────────────────────────────────
    try {
      final assistantMessage = await chatRepository.sendPrompt(
        message: userMessage,
        provider: event.provider,
      );

      emit(ChatSuccess(
        messages: List<Message>.unmodifiable([
          ...optimisticMessages,
          assistantMessage,
        ]),
        conversationId: conversationId,
      ));
    } catch (e) {
      // Map typed API errors to clean user-facing strings.
      // Generic exceptions (e.g. TimeoutException, SocketException) fall
      // through to the else branch.
      final String errorMessage;
      if (e is AiApiException) {
        errorMessage = switch (e.statusCode) {
          401 =>
            'Invalid API Key. Please verify your credentials in Settings.',
          403 =>
            'Access denied. Check that your API Key has the correct permissions.',
          429 =>
            'Rate limit reached. Please wait a moment before trying again.',
          500 =>
            'The AI provider is experiencing internal server issues.',
          503 =>
            'The AI provider is temporarily unavailable. Try again shortly.',
          _ =>
            'Connection failed (Status ${e.statusCode}). Please try again.',
        };
      } else {
        errorMessage =
            'An unexpected error occurred. Check your connection and try again.';
      }

      // Emit the error while preserving the message list so the conversation
      // remains visible in the UI.
      emit(ChatError(
        message: errorMessage,
        previousMessages: optimisticMessages,
        conversationId: conversationId,
      ));
    }
  }
}
