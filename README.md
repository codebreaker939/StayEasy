# stayeasy

StayEasy is a Flutter hotel discovery and booking prototype backed by Supabase.

## Local development

Copy `config/dev.example.json` to the ignored local file `config/dev.json` and
fill in the project URL and publishable key from the Supabase project. Run the
app with `flutter run --dart-define-from-file=config/dev.json`. The publishable
key is intended for client applications; never put a Supabase secret/service
role key or database password in this file or in Flutter code.

When the Supabase defines are omitted, development widgets use mock repository
implementations. Tests use those defaults or explicit repository overrides and
do not need live network access.

Run the checks with `dart format .`, `flutter analyze`, and `flutter test`.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
