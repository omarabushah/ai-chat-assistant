import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

import 'data/datasources/ai_remote_data_source.dart';
import 'data/datasources/chat_local_data_source.dart';
import 'data/datasources/settings_local_data_source.dart';
import 'data/repositories/chat_repository_impl.dart';
import 'domain/repositories/chat_repository.dart';
import 'presentation/blocs/chat/chat_bloc.dart';
import 'presentation/blocs/conversation/conversation_bloc.dart';
import 'presentation/blocs/conversation/conversation_event.dart';
import 'presentation/blocs/settings/settings_bloc.dart';
import 'presentation/blocs/settings/settings_event.dart';
import 'presentation/screens/conversation_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Hive initialisation ────────────────────────────────────────────────────
  await Hive.initFlutter();

  // ── Encryption key for the settings box ───────────────────────────────────
  // The key is generated once, stored in the platform's secure enclave
  // (Keychain on iOS, Keystore-backed EncryptedSharedPreferences on Android,
  // libsecret / Credential Manager on desktop), and retrieved on every
  // subsequent launch. It never touches the file system in plaintext.
  const secureStorage = FlutterSecureStorage();
  const _hiveKeyAlias = 'hive_secure_key';

  if (await secureStorage.read(key: _hiveKeyAlias) == null) {
    // First launch: generate a cryptographically random 256-bit key and
    // persist it. base64Url encoding makes it a safe plain-text string.
    final freshKey = Hive.generateSecureKey();
    await secureStorage.write(
      key: _hiveKeyAlias,
      value: base64UrlEncode(freshKey),
    );
  }

  final encodedKey = await secureStorage.read(key: _hiveKeyAlias);
  final encryptionKey = base64Url.decode(encodedKey!);

  // ── Open boxes ────────────────────────────────────────────────────────────
  // 'settings' holds API keys — encrypted with AES-256-CBC via HiveAesCipher.
  // The other boxes store non-sensitive structural data and remain standard.
  await Future.wait([
    Hive.openBox<dynamic>('conversations'),
    Hive.openBox<dynamic>('messages'),
    Hive.openBox<dynamic>('providers'),
    Hive.openBox<dynamic>(
      'settings',
      encryptionCipher: HiveAesCipher(encryptionKey),
    ),
  ]);

  // ── Dependency graph (manual DI, swap for get_it/injectable if preferred) ──
  final ChatLocalDataSource localDataSource = ChatLocalDataSourceImpl();
  final AiRemoteDataSource remoteDataSource = AiRemoteDataSourceImpl(
    client: http.Client(),
  );
  final ChatRepository chatRepository = ChatRepositoryImpl(
    localDataSource: localDataSource,
    remoteDataSource: remoteDataSource,
  );
  // SettingsLocalDataSourceImpl accesses 'providers' (plain) and 'settings'
  // (AES-256 encrypted). Both boxes are guaranteed open at this point.
  final SettingsLocalDataSource settingsDataSource =
      SettingsLocalDataSourceImpl();

  runApp(MyApp(
    chatRepository: chatRepository,
    settingsDataSource: settingsDataSource,
  ));
}

class MyApp extends StatelessWidget {
  final ChatRepository chatRepository;
  final SettingsLocalDataSource settingsDataSource;

  const MyApp({
    super.key,
    required this.chatRepository,
    required this.settingsDataSource,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsBloc>(
          create: (_) => SettingsBloc(settingsDataSource: settingsDataSource)
            ..add(const LoadSettings()),
        ),

        // ConversationBloc triggers an initial load so the sidebar/list is
        // populated as soon as the widget tree is built.
        BlocProvider<ConversationBloc>(
          create: (_) => ConversationBloc(chatRepository: chatRepository)
            ..add(const LoadConversations()),
        ),

        // ChatBloc starts in ChatInitial; LoadChat is dispatched by the UI
        // when the user taps a conversation.
        BlocProvider<ChatBloc>(
          create: (_) => ChatBloc(chatRepository: chatRepository),
        ),
      ],
      child: MaterialApp(
        title: 'AI Chat Assistant',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const ConversationListScreen(),
      ),
    );
  }
}
