import 'package:equatable/equatable.dart';

import '../../../domain/entities/conversation.dart';

abstract class ConversationState extends Equatable {
  const ConversationState();

  @override
  List<Object?> get props => [];
}

class ConversationLoading extends ConversationState {
  const ConversationLoading();
}

/// At least one conversation exists.
class ConversationLoaded extends ConversationState {
  final List<Conversation> conversations;

  const ConversationLoaded(this.conversations);

  @override
  List<Object?> get props => [conversations];
}

/// No conversations have been created yet.
class ConversationEmpty extends ConversationState {
  const ConversationEmpty();
}

class ConversationError extends ConversationState {
  final String message;

  const ConversationError(this.message);

  @override
  List<Object?> get props => [message];
}
