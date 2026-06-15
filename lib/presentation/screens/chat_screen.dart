import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../domain/entities/message.dart';
import '../blocs/chat/chat_bloc.dart';
import '../blocs/chat/chat_event.dart';
import '../blocs/chat/chat_state.dart';
import '../blocs/settings/settings_bloc.dart';
import '../blocs/settings/settings_state.dart';
import 'settings_screen.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String title;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.title,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Kick off message history load as soon as the screen is created.
    context.read<ChatBloc>().add(LoadChat(widget.conversationId));
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Schedules a smooth scroll to the bottom after the current frame renders.
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients &&
          _scrollController.position.maxScrollExtent > 0) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend() {
    final content = _inputController.text.trim();
    if (content.isEmpty) return;

    // Guard: ensure an AI provider has been selected first.
    final settingsState = context.read<SettingsBloc>().state;
    if (settingsState is! SettingsLoaded ||
        settingsState.selectedProvider == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Select an AI provider in Settings first.'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Go to Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ),
      );
      return;
    }

    // Clear before dispatching so the field empties immediately, not after
    // the async chain completes.
    _inputController.clear();

    context.read<ChatBloc>().add(
          SendMessage(
            content: content,
            provider: settingsState.selectedProvider!,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: BlocConsumer<ChatBloc, ChatState>(
        // ── Side-effects: scroll on new messages, SnackBar on error ──────────
        listenWhen: (previous, current) =>
            current is ChatSuccess ||
            current is ChatLoading ||
            current is ChatError,
        listener: (context, state) {
          if (state is ChatError) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Theme.of(context).colorScheme.error,
                  action: SnackBarAction(
                    label: 'Dismiss',
                    textColor: Theme.of(context).colorScheme.onError,
                    onPressed: () =>
                        ScaffoldMessenger.of(context).hideCurrentSnackBar(),
                  ),
                ),
              );
          }
          // Scroll to the newest message after every state that carries messages.
          if (state is ChatSuccess || state is ChatLoading) {
            _scrollToBottom();
          }
        },

        // ── UI ────────────────────────────────────────────────────────────────
        builder: (context, state) {
          final List<Message> messages;
          final bool isLoading;

          if (state is ChatSuccess) {
            messages = state.messages;
            isLoading = false;
          } else if (state is ChatLoading) {
            messages = state.messages;
            isLoading = true;
          } else if (state is ChatError) {
            messages = state.previousMessages;
            isLoading = false;
          } else {
            messages = const [];
            isLoading = false;
          }

          return Column(
            children: [
              // ── Message list ───────────────────────────────────────────────
              Expanded(
                child: _buildMessageList(
                  context,
                  messages: messages,
                  isLoading: isLoading,
                ),
              ),

              // ── AI typing progress bar (sits above the input) ──────────────
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: isLoading
                    ? LinearProgressIndicator(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        minHeight: 2,
                      )
                    : const SizedBox.shrink(),
              ),

              // ── Input bar ─────────────────────────────────────────────────
              _ChatInputBar(
                controller: _inputController,
                isLoading: isLoading,
                onSend: _handleSend,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessageList(
    BuildContext context, {
    required List<Message> messages,
    required bool isLoading,
  }) {
    // Empty state (no messages and not loading history)
    if (messages.isEmpty && !isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.chat_outlined,
                size: 72,
                color:
                    Theme.of(context).colorScheme.primary.withAlpha(50),
              ),
              const SizedBox(height: 16),
              Text(
                'Start the conversation',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Type a message below to get started.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(140),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Initial loading (empty list + spinner before history loads)
    if (messages.isEmpty && isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      // When loading, add one extra slot at the end for the typing indicator.
      itemCount: messages.length + (isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length && isLoading) {
          return const _TypingIndicator();
        }
        return _MessageBubble(message: messages[index]);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Message bubble
// ─────────────────────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final Message message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 4,
          bottom: 4,
          left: isUser ? 56 : 0,
          right: isUser ? 0 : 56,
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isUser
              ? colorScheme.primary
              : colorScheme.secondaryContainer,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isUser
            ? Text(
                message.content,
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontSize: 15,
                  height: 1.45,
                ),
              )
            : MarkdownBody(
                data: message.content,
                selectable: true,
                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                    .copyWith(
                  p: TextStyle(
                    color: colorScheme.onSecondaryContainer,
                    fontSize: 15,
                    height: 1.45,
                  ),
                  code: TextStyle(
                    color: colorScheme.onSecondaryContainer,
                    backgroundColor:
                        colorScheme.secondary.withAlpha(40),
                    fontSize: 13,
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: colorScheme.secondary.withAlpha(40),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  strong: TextStyle(
                    color: colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                  em: TextStyle(
                    color: colorScheme.onSecondaryContainer,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Typing indicator (shown as last item when isLoading = true)
// ─────────────────────────────────────────────────────────────────────────────

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 4, bottom: 4, right: 56),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36,
              child: LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'AI is typing…',
              style: TextStyle(
                color:
                    Theme.of(context).colorScheme.onSecondaryContainer,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Input bar
// ─────────────────────────────────────────────────────────────────────────────

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSend;

  const _ChatInputBar({
    required this.controller,
    required this.isLoading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: colorScheme.outline.withAlpha(60),
              width: 1,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // ── Text field ─────────────────────────────────────────────────
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !isLoading,
                maxLines: 5,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText:
                      isLoading ? 'AI is responding…' : 'Type a message…',
                  hintStyle: TextStyle(
                    color: colorScheme.onSurface.withAlpha(100),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: isLoading
                      ? colorScheme.surfaceContainerHighest.withAlpha(120)
                      : colorScheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                // Allow submit via keyboard Enter key.
                onSubmitted: isLoading ? null : (_) => onSend(),
                textInputAction: TextInputAction.send,
              ),
            ),

            const SizedBox(width: 8),

            // ── Send button ────────────────────────────────────────────────
            AnimatedOpacity(
              opacity: isLoading ? 0.4 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: IconButton.filled(
                onPressed: isLoading ? null : onSend,
                icon: const Icon(Icons.send_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  minimumSize: const Size(48, 48),
                ),
                tooltip: 'Send',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
