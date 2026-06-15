import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/datasources/settings_local_data_source.dart';
import 'settings_event.dart';
import 'settings_state.dart';

/// Manages AI provider configurations.
///
/// All storage I/O is delegated to [SettingsLocalDataSource]; this Bloc
/// contains zero infrastructure imports (no Hive, no http).
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsLocalDataSource settingsDataSource;

  SettingsBloc({required this.settingsDataSource})
      : super(const SettingsLoading()) {
    on<LoadSettings>(_onLoadSettings);
    on<SaveProvider>(_onSaveProvider);
    on<SelectProvider>(_onSelectProvider);
  }

  // ---------------------------------------------------------------------------
  // Event handlers
  // ---------------------------------------------------------------------------

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    emit(const SettingsLoading());
    try {
      final providers = await settingsDataSource.getProviders();
      final selectedId = await settingsDataSource.getSelectedProviderId();
      emit(SettingsLoaded(providers: providers, selectedProviderId: selectedId));
    } catch (e) {
      emit(SettingsError('Failed to load settings: $e'));
    }
  }

  Future<void> _onSaveProvider(
    SaveProvider event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await settingsDataSource.saveProvider(event.provider);

      final providers = await settingsDataSource.getProviders();
      final selectedId = await settingsDataSource.getSelectedProviderId();
      emit(SettingsLoaded(providers: providers, selectedProviderId: selectedId));
    } catch (e) {
      emit(SettingsError('Failed to save provider: $e'));
    }
  }

  Future<void> _onSelectProvider(
    SelectProvider event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await settingsDataSource.saveSelectedProviderId(event.providerId);

      final providers = await settingsDataSource.getProviders();
      emit(SettingsLoaded(
        providers: providers,
        selectedProviderId: event.providerId,
      ));
    } catch (e) {
      emit(SettingsError('Failed to select provider: $e'));
    }
  }
}
