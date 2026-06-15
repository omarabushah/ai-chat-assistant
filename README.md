# AI Chat Assistant

A production-oriented AI Chat Assistant mobile application built with Flutter, demonstrating clean architecture, predictable state management, and offline-first capabilities.

## Features
* **Configurable AI Providers:** Connect to OpenAI, Gemini, or any OpenAI-compatible endpoint (e.g., LM Studio, OpenRouter) via dynamic settings.
* **Offline-First Persistence:** Conversations and messages are saved locally and are fully accessible without a network connection.
* **Predictable State Management:** Fully driven by `flutter_bloc` with strict separation of presentation and business logic.
* **Optimistic UI:** User messages appear instantly, maintaining a fluid conversational experience while awaiting API responses.
* **Resilient Error Handling:** API failures present user-friendly error banners without wiping the existing conversation context.

## Setup Instructions
1. Ensure the Flutter SDK (Stable Channel) is installed.
2. Clone the repository.
3. Run `flutter pub get` to install dependencies.
4. Run `flutter run` to launch on your preferred device or emulator.

## Environment Variables & Security
This application handles configuration dynamically at runtime rather than relying on static `.env` files. 
* Navigate to the **Settings** screen within the app to securely input your `Base URL`, `Model Name`, and `API Key`. 
* **Enterprise-Grade Security:** These credentials are encrypted at rest using an AES-256 cipher. The encryption key is generated and stored in the device's native hardware vault (Keystore/Keychain) using `flutter_secure_storage`, ensuring sensitive API keys are never exposed in plain text within the application's local data folder. 

## Application Architecture
The application strictly adheres to Clean Architecture principles, divided into three main layers:
* **Domain Layer:** Contains core business entities (`Conversation`, `Message`, `AiProvider`) utilizing `equatable` for value equality, alongside abstract repository interfaces.
* **Data Layer:** Implements the repositories. It orchestrates between the `ChatLocalDataSource` (Hive) for persistence and the `AiRemoteDataSource` (HTTP) for external API communication.
* **Presentation Layer:** Contains the UI screens and Blocs.

## Bloc Architecture Overview
Business logic is exclusively managed by three distinct Blocs:
* `SettingsBloc`: Manages the lifecycle of AI provider configurations.
* `ConversationBloc`: Handles loading, creating, and deleting chat histories.
* `ChatBloc`: Orchestrates the active conversation loop. It utilizes an optimistic update pattern, emitting a `ChatLoading` state with the user's message appended before initiating the remote repository call.

## Local Storage Design
Local persistence is powered by **Hive**, operating synchronously for high-performance reads.
* Entities are serialized to `Map<String, dynamic>` representations, allowing Hive to store them without relying on `build_runner` for type adapter generation.
* The local data source acts as the ultimate source of truth; all UI state is populated by reading directly from storage after write operations.