/// Thrown by the data layer when an AI provider returns a non-200 response.
///
/// Defined in the domain layer so that both the data-layer remote data source
/// (which throws it) and the presentation-layer Bloc (which catches and maps
/// it) can import a single canonical type without creating a cross-layer
/// dependency between presentation → data.
class AiApiException implements Exception {
  final int statusCode;

  /// Raw response body from the provider — used for internal logging only;
  /// never shown to users directly.
  final String body;

  const AiApiException({required this.statusCode, required this.body});

  @override
  String toString() => 'AiApiException($statusCode): $body';
}
