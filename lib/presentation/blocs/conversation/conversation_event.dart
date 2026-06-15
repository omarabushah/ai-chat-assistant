import 'package:equatable/equatable.dart';

abstract class ConversationEvent extends Equatable {
  const ConversationEvent();

  @override
  List<Object?> get props => [];
}

/// Fetches all persisted conversations from the repository.
class LoadConversations extends ConversationEvent {
  const LoadConversations();
}

/// Creates a new conversation with the given [title].
class CreateConversation extends ConversationEvent {
  final String title;

  const CreateConversation(this.title);

  @override
  List<Object?> get props => [title];
}

/// Permanently deletes the conversation and all its messages.
class DeleteConversation extends ConversationEvent {
  final String conversationId;

  const DeleteConversation(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}
