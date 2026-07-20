# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

PMPlayer is a Flutter app for offline audio playback from local files on the device. Per `docs/IDEA.md`, the intent is: "Aplicativo Flutter, MVVM Feature-wise, para reprodução de audio, utilizando os arquivos locais do dispositivo utilizado e totalmente offline. Simples e direto."

The repository currently contains only the stock `flutter create` skeleton (`lib/main.dart` is the default counter-less "Hello World" scaffold; no features, no `test/` directory, and no `CHANGELOG.md` exist yet). Treat any architecture described below as the mandated target structure for new work, not as something already present.

## Mandatory project rules (from `docs/RULES.md`)

These are explicit, non-negotiable conventions for this repo:

- Follow DRY.
- Develop every feature using TDD (write the failing test first).
- Code must be readable and easy to maintain.
- Follow MVVM with a feature-wise structure (see Architecture below) for all new code.
- Never commit under the user's own name/identity.
- Log every change made to `CHANGELOG.md` (create it if it doesn't exist yet).
- After every two mistakes made in a session, end that message with `!! INICIAR NOVA SEÇÃO !!` and write a `HANDOFF-{data}-{hora}-{recurso}.md` document summarizing the handoff.
- Always follow the design (design references, when they exist, take precedence over ad hoc UI choices).

## Commands

Standard Flutter tooling applies; there are no custom scripts or task runners.

```bash
flutter pub get              # install dependencies
flutter run                  # run on a connected device/simulator
flutter analyze              # static analysis (uses analysis_options.yaml -> flutter_lints)
dart format .                # format code
flutter test                 # run all tests
flutter test test/foo_test.dart                 # run a single test file
flutter test test/foo_test.dart --name "case"   # run a single test by name
flutter build apk            # Android build
flutter build ios            # iOS build
```

Linting is configured via `analysis_options.yaml`, which just includes `package:flutter_lints/flutter.yaml` — no custom rule overrides.

## Architecture

The project targets MVVM organized feature-wise (a top-level `features/` directory, each feature owning its own model/view/viewmodel), per `docs/RULES.md`. As features are added, they should live under something like `lib/features/<feature_name>/` with `view`, `viewmodel`, and `model` subdivisions, rather than grouping code by technical layer at the top level. Since no features exist yet, establish this structure with the first feature added (expected to be local audio file playback) rather than inferring it from existing code.
