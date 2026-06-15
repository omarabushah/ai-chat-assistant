import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/entities/ai_provider.dart';
import '../../domain/entities/message.dart';
import '../../domain/errors/chat_exceptions.dart';

abstract class AiRemoteDataSource {
  /// Sends the full conversation [history] plus [latestMessage] to the
  /// OpenAI-compatible endpoint configured in [provider].
  ///
  /// [history] must contain every prior turn in chronological order.
  /// [latestMessage] is the current user message — it is appended last so the
  /// model always sees the most recent prompt at the end of the context window.
  ///
  /// Returns the raw assistant reply content string.
  /// Throws [AiApiException] on non-200 responses.
  /// Throws [TimeoutException] if the provider does not respond within 30 s.
  Future<String> sendMessage({
    required List<Message> history,
    required Message latestMessage,
    required AiProvider provider,
  });
}

class AiRemoteDataSourceImpl implements AiRemoteDataSource {
  final http.Client client;

  /// Inject [http.Client] so it can be swapped with a mock in tests.
  AiRemoteDataSourceImpl({required this.client});

  @override
  Future<String> sendMessage({
    required List<Message> history,
    required Message latestMessage,
    required AiProvider provider,
  }) async {
    final uri = Uri.parse('${provider.baseUrl}/chat/completions');

    // Combine prior turns + the current user message into the full context
    // window. Order is chronological: oldest → newest.
    final allMessages = [...history, latestMessage];

    final response = await client
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${provider.apiKey}',
          },
          body: jsonEncode({
            'model': provider.model,
            'messages': allMessages
                .map((m) => {
                      'role': m.role.name,
                      'content': m.content,
                    })
                .toList(),
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw AiApiException(
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final content = decoded['choices'][0]['message']['content'] as String;
    return content;
  }
}
