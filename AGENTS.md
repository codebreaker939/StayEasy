# StayEasy project guidance

- Figma is the visual source of truth. Inspect the relevant Figma frame before implementing a screen.
- Use Material 3, Riverpod for application/state boundaries, and go_router for navigation.
- Organize code feature-first, separating UI, domain logic, and data access when they are introduced.
- Do not add dependencies without a concrete need; prefer reusable widgets to duplicated screen code.
- Use StayEasy design tokens when available. Build responsive layouts rather than copying fixed Figma coordinates.
- Never put API keys or AI-provider secrets in Flutter code. Future AI requests must use a secure backend or Edge Function.
- Season-aware review ranking must be deterministic and testable; AI summarization is a separate layer.
- Do not modify native Android configuration unless explicitly needed.
- After meaningful changes, run `dart format .`, `flutter analyze`, and `flutter test`.
- Make small, focused Git commits, but do not create commits unless explicitly requested.



## Figma Source of Truth

StayEasy Figma file:

https://www.figma.com/design/cklJDBoj2GGMhJeTlvrBoN/StayEasy

Figma file key:

cklJDBoj2GGMhJeTlvrBoN

Rules:
- Treat Figma as the visual source of truth.
- Inspect the relevant Figma frame before implementing a screen.
- Do not modify the Figma file unless explicitly requested.
- Reuse StayEasy variables, styles, and components where applicable.
- Do not invent design tokens when they already exist in Figma.