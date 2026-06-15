import 'package:equatable/equatable.dart';

class AiProvider extends Equatable {
  final String id;
  final String providerName;
  final String baseUrl;
  final String model;
  final String apiKey;

  const AiProvider({
    required this.id,
    required this.providerName,
    required this.baseUrl,
    required this.model,
    required this.apiKey,
  });

  AiProvider copyWith({
    String? id,
    String? providerName,
    String? baseUrl,
    String? model,
    String? apiKey,
  }) {
    return AiProvider(
      id: id ?? this.id,
      providerName: providerName ?? this.providerName,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      apiKey: apiKey ?? this.apiKey,
    );
  }

  @override
  List<Object?> get props => [id, providerName, baseUrl, model, apiKey];
}
