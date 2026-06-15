import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/ai_provider.dart';
import '../blocs/settings/settings_bloc.dart';
import '../blocs/settings/settings_event.dart';
import '../blocs/settings/settings_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'AI Providers',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          if (state is SettingsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SettingsError) {
            return _SettingsErrorView(
              message: state.message,
              onRetry: () =>
                  context.read<SettingsBloc>().add(const LoadSettings()),
            );
          }

          if (state is SettingsLoaded) {
            if (state.providers.isEmpty) {
              return _EmptyProvidersView(
                onAddTapped: () => _showProviderForm(context),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: state.providers.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 72, endIndent: 16),
              itemBuilder: (context, index) {
                final provider = state.providers[index];
                final isSelected = provider.id == state.selectedProviderId;

                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      Icons.api_outlined,
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  title: Text(
                    provider.providerName,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    '${provider.model}  •  ${provider.baseUrl}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(140),
                      fontSize: 12,
                    ),
                  ),
                  trailing: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: isSelected
                        ? Icon(
                            Icons.check_circle_rounded,
                            key: const ValueKey('selected'),
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : Icon(
                            Icons.radio_button_unchecked,
                            key: const ValueKey('unselected'),
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withAlpha(100),
                          ),
                  ),
                  onTap: () => context
                      .read<SettingsBloc>()
                      .add(SelectProvider(provider.id)),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          // Always show the FAB so the user can add providers at any time.
          if (state is SettingsLoading) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () => _showProviderForm(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Provider'),
          );
        },
      ),
    );
  }

  void _showProviderForm(BuildContext context) {
    // Capture the bloc before entering the dialog — the dialog's context is
    // outside the MultiBlocProvider subtree.
    final settingsBloc = context.read<SettingsBloc>();
    showDialog(
      context: context,
      builder: (_) => _ProviderFormDialog(settingsBloc: settingsBloc),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider form dialog
// ─────────────────────────────────────────────────────────────────────────────

class _ProviderFormDialog extends StatefulWidget {
  final SettingsBloc settingsBloc;

  const _ProviderFormDialog({required this.settingsBloc});

  @override
  State<_ProviderFormDialog> createState() => _ProviderFormDialogState();
}

class _ProviderFormDialogState extends State<_ProviderFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _modelController = TextEditingController();
  final _apiKeyController = TextEditingController();
  bool _obscureApiKey = true;

  @override
  void dispose() {
    _nameController.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add AI Provider'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FormField(
                  controller: _nameController,
                  label: 'Provider Name',
                  hint: 'e.g. OpenAI',
                ),
                const SizedBox(height: 12),
                _FormField(
                  controller: _baseUrlController,
                  label: 'Base URL',
                  hint: 'https://api.openai.com/v1',
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 12),
                _FormField(
                  controller: _modelController,
                  label: 'Model',
                  hint: 'e.g. gpt-4o',
                ),
                const SizedBox(height: 12),
                // API Key field with visibility toggle
                TextFormField(
                  controller: _apiKeyController,
                  obscureText: _obscureApiKey,
                  decoration: InputDecoration(
                    labelText: 'API Key',
                    hintText: 'sk-...',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureApiKey
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscureApiKey = !_obscureApiKey),
                      tooltip: _obscureApiKey ? 'Show' : 'Hide',
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final provider = AiProvider(
      id: const Uuid().v4(),
      providerName: _nameController.text.trim(),
      baseUrl: _baseUrlController.text.trim(),
      model: _modelController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
    );

    widget.settingsBloc.add(SaveProvider(provider));
    Navigator.pop(context);
  }
}

// Reusable required text field for the form
class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType keyboardType;

  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'Required' : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty / error views
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyProvidersView extends StatelessWidget {
  final VoidCallback onAddTapped;

  const _EmptyProvidersView({required this.onAddTapped});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.api_outlined,
              size: 88,
              color: Theme.of(context).colorScheme.primary.withAlpha(60),
            ),
            const SizedBox(height: 24),
            Text(
              'No providers configured',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add an OpenAI-compatible provider to start chatting.',
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
              onPressed: onAddTapped,
              icon: const Icon(Icons.add),
              label: const Text('Add Provider'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _SettingsErrorView({required this.message, required this.onRetry});

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
