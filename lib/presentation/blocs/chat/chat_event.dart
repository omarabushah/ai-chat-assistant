import 'package:equatable/equatable.dart';

import '../../../domain/entities/ai_provider.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

/// Loads the message history for an existing conversation.
class LoadChat extends ChatEvent {
  final String conversationId;

  const LoadChat(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

/// Sends a user message and triggers an AI round-trip.
///
/// [conversationId] is intentionally omitted here — the Bloc reads it from
/// the current [ChatSuccess] state, ensuring a message can only be sent
/// when a conversation is already loaded.
class SendMessage extends ChatEvent {
  final String content;
  final AiProvider provider;

  const SendMessage({required this.content, required this.provider});

  @override
  List<Object?> get props => [content, provider];
}
