import 'package:equatable/equatable.dart';

import '../../../domain/entities/ai_provider.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

/// Triggers a read of all stored providers and the selected provider ID.
class LoadSettings extends SettingsEvent {
  const LoadSettings();
}

/// Persists a new or updated [AiProvider] configuration.
class SaveProvider extends SettingsEvent {
  final AiProvider provider;

  const SaveProvider(this.provider);

  @override
  List<Object?> get props => [provider];
}

/// Marks [providerId] as the active provider for AI requests.
class SelectProvider extends SettingsEvent {
  final String providerId;

  const SelectProvider(this.providerId);

  @override
  List<Object?> get props => [providerId];
}
