import 'package:equatable/equatable.dart';

import '../../../domain/entities/ai_provider.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

class SettingsLoading extends SettingsState {
  const SettingsLoading();
}

class SettingsLoaded extends SettingsState {
  final List<AiProvider> providers;

  /// Null when no provider has been selected yet.
  final String? selectedProviderId;

  const SettingsLoaded({
    required this.providers,
    this.selectedProviderId,
  });

  /// Convenience getter so widgets don't need to search the list manually.
  AiProvider? get selectedProvider => selectedProviderId == null
      ? null
      : providers.where((p) => p.id == selectedProviderId).firstOrNull;

  @override
  List<Object?> get props => [providers, selectedProviderId];
}

class SettingsError extends SettingsState {
  final String message;

  const SettingsError(this.message);

  @override
  List<Object?> get props => [message];
}
