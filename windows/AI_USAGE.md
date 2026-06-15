# AI Usage Report

## AI Tools Used
* **Cursor:** Primary IDE.
* **Claude 3.5 Sonnet:** Integrated via Cursor Composer and Chat for architectural scaffolding and boilerplate generation.

## Prompts Used
* *"Act as a senior Flutter developer. I am building a production-oriented AI Chat Assistant for an assessment. The app must strictly adhere to clean architecture and use Bloc for state management. Please generate the exact code for the core Domain Entities and their Abstract Repositories based on the following schema..."*
* *"Create the Data layer components implementing clean architecture. Implement ChatLocalDataSource using Hive and AiRemoteDataSource using the http package. The remote source should return a standard string, letting the repository handle ID generation and timestamps."*
* *"Generate the Presentation layer's state management using flutter_bloc. Ensure strict separation of concerns. Create SettingsBloc, ConversationBloc, and ChatBloc. ChatBloc must include optimistic UI updates."*
* *"Generate the UI screens using BlocBuilder and BlocConsumer. Ensure the chat input field is disabled during loading states and clears upon successful submission."*

## Generated Code
The majority of the structural boilerplate was generated via AI, including:
* Domain Entities (`conversation.dart`, `message.dart`, `ai_provider.dart`) and Equatable implementations.
* Data Sources and Repository implementations (`chat_repository_impl.dart`).
* Bloc event, state, and logic classes.
* UI structural code (Scaffolds, ListViews, Dialogs).

## Manually Written Code
Manual intervention and refinement were applied to:
* Project initialization and directory scaffolding (`lib/core`, `lib/domain`, etc.).
* Dependency management and package resolution in `pubspec.yaml`.
* Routing and multi-bloc initialization in `main.dart`.
* Specific UI refinements, debugging compiler errors, and ensuring correct `BuildContext` usage across asynchronous gaps.

## Engineering Decisions
1. **Repository Abstraction:** The `AiRemoteDataSource` strictly returns a raw `String` representing the assistant's response. The `ChatRepositoryImpl` is responsible for generating the UUID and timestamp, and constructing the final `Message` entity. This prevents the data source from leaking domain concepts.
2. **Optimistic UI Updates:** The `ChatBloc` appends the user's message to the state and emits it immediately before making the network call. This ensures a snappy, responsive feel.
3. **Non-Destructive Error Handling:** If the AI provider fails (e.g., rate limit, invalid key), `ChatBloc` emits a `ChatError` state but retains the `previousMessages` list. This prevents the user's conversation context from being wiped out upon a network failure.
4. **No Build Runner:** Hive is implemented using manual map serialization rather than generated TypeAdapters. This reduces project complexity, build times, and keeps the repository lightweight while fully satisfying the offline-first requirement.