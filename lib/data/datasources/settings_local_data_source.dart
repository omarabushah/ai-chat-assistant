import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/ai_provider.dart';

/// Contract for persisting and retrieving AI provider configurations.
///
/// Keeping this interface in the data layer (parallel to [ChatLocalDataSource])
/// allows [SettingsBloc] to depend on the abstraction without importing
/// any Hive symbols into the presentation layer.
abstract class SettingsLocalDataSource {
  Future<List<AiProvider>> getProviders();
  Future<void> saveProvider(AiProvider provider);
  Future<String?> getSelectedProviderId();
  Future<void> saveSelectedProviderId(String providerId);
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  static const String _providersBoxName = 'providers';
  static const String _settingsBoxName = 'settings';
  static const String _selectedProviderKey = 'selectedProviderId';

  // ---------------------------------------------------------------------------
  // Box accessors
  // ---------------------------------------------------------------------------

  Future<Box<dynamic>> get _providersBox async =>
      Hive.isBoxOpen(_providersBoxName)
          ? Hive.box(_providersBoxName)
          : await Hive.openBox(_providersBoxName);

  /// The 'settings' box MUST be pre-opened with [HiveAesCipher] in main.dart
  /// before any provider code runs. Accessing it synchronously here is safe
  /// because [main()] opens all boxes before calling [runApp()].
  Box<dynamic> get _settingsBox => Hive.box(_settingsBoxName);

  // ---------------------------------------------------------------------------
  // Providers
  // ---------------------------------------------------------------------------

  @override
  Future<List<AiProvider>> getProviders() async {
    final box = await _providersBox;
    return box.values
        .map((e) => _providerFromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<void> saveProvider(AiProvider provider) async {
    final box = await _providersBox;
    await box.put(provider.id, _providerToMap(provider));
  }

  // ---------------------------------------------------------------------------
  // Selected provider ID (stored in the encrypted 'settings' box)
  // ---------------------------------------------------------------------------

  @override
  Future<String?> getSelectedProviderId() async =>
      _settingsBox.get(_selectedProviderKey) as String?;

  @override
  Future<void> saveSelectedProviderId(String providerId) async =>
      _settingsBox.put(_selectedProviderKey, providerId);

  // ---------------------------------------------------------------------------
  // Serialisation helpers
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _providerToMap(AiProvider p) => {
        'id': p.id,
        'providerName': p.providerName,
        'baseUrl': p.baseUrl,
        'model': p.model,
        'apiKey': p.apiKey,
      };

  AiProvider _providerFromMap(Map<String, dynamic> map) => AiProvider(
        id: map['id'] as String,
        providerName: map['providerName'] as String,
        baseUrl: map['baseUrl'] as String,
        model: map['model'] as String,
        apiKey: map['apiKey'] as String,
      );
}
