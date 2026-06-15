import 'package:equatable/equatable.dart';

import '../../../domain/entities/message.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

/// No conversation has been opened yet.
class ChatInitial extends ChatState {
  const ChatInitial();
}

/// An AI request is in-flight.
///
/// Carries [messages] (including the optimistically-appended user message)
/// so the UI can show the conversation while the spinner is active.
class ChatLoading extends ChatState {
  final List<Message> messages;
  final String conversationId;

  const ChatLoading({
    required this.messages,
    required this.conversationId,
  });

  @override
  List<Object?> get props => [messages, conversationId];
}

/// Messages loaded or AI reply received successfully.
class ChatSuccess extends ChatState {
  final List<Message> messages;
  final String conversationId;

  const ChatSuccess({
    required this.messages,
    required this.conversationId,
  });

  @override
  List<Object?> get props => [messages, conversationId];
}

/// An error occurred.
///
/// [previousMessages] allows the UI to keep the conversation visible
/// while surfacing the error, rather than wiping the screen.
class ChatError extends ChatState {
  final String message;
  final List<Message> previousMessages;
  final String conversationId;

  const ChatError({
    required this.message,
    required this.previousMessages,
    required this.conversationId,
  });

  @override
  List<Object?> get props => [message, previousMessages, conversationId];
}
