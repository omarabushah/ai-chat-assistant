import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/conversation/conversation_bloc.dart';
import '../blocs/conversation/conversation_event.dart';
import '../blocs/conversation/conversation_state.dart';
import 'chat_screen.dart';
import 'settings_screen.dart';

class ConversationListScreen extends StatelessWidget {
  const ConversationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'AI Chat',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: BlocBuilder<ConversationBloc, ConversationState>(
        builder: (context, state) {
          if (state is ConversationLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ConversationError) {
            return _ErrorView(
              message: state.message,
              onRetry: () => context
                  .read<ConversationBloc>()
                  .add(const LoadConversations()),
            );
          }

          if (state is ConversationEmpty) {
            return _EmptyView(
              onCreateTapped: () => _showCreateDialog(context),
            );
          }

          if (state is ConversationLoaded) {
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: state.conversations.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 72, endIndent: 16),
              itemBuilder: (context, index) {
                final conversation = state.conversations[index];
                return Dismissible(
                  key: ValueKey(conversation.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    color: Theme.of(context).colorScheme.error,
                    child: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.onError,
                    ),
                  ),
                  confirmDismiss: (_) async {
                    return _confirmDelete(context, conversation.title);
                  },
                  onDismissed: (_) {
                    context
                        .read<ConversationBloc>()
                        .add(DeleteConversation(conversation.id));
                  },
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: Text(
                        conversation.title.isNotEmpty
                            ? conversation.title[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer,
                        ),
                      ),
                    ),
                    title: Text(
                      conversation.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        _formatDate(conversation.updatedAt),
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withAlpha(140),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(100),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          conversationId: conversation.id,
                          title: conversation.title,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Chat'),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Dialogs
  // ---------------------------------------------------------------------------

  void _showCreateDialog(BuildContext context) {
    // Capture the bloc before entering the dialog context, which is outside
    // the MultiBlocProvider widget tree.
    final bloc = context.read<ConversationBloc>();
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Conversation'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Give it a title (optional)',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) {
            bloc.add(CreateConversation(controller.text));
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              bloc.add(CreateConversation(controller.text));
              Navigator.pop(ctx);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  Future<bool> _confirmDelete(BuildContext context, String title) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete conversation?'),
        content: Text(
          '"$title" and all its messages will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  final VoidCallback onCreateTapped;

  const _EmptyView({required this.onCreateTapped});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 88,
              color: Theme.of(context).colorScheme.primary.withAlpha(60),
            ),
            const SizedBox(height: 24),
            Text(
              'No conversations yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a new conversation and let AI assist you.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withAlpha(140),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onCreateTapped,
              icon: const Icon(Icons.add),
              label: const Text('Start your first chat'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
