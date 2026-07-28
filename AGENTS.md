# Repository guide

- Keep the current split: Flutter in `mobile/`, FastAPI in `backend/`, and
  MySQL scripts in `database/`.
- Never commit `.env`, database passwords, virtual environments, or build
  output.
- Keep the mobile API base URL in `mobile/lib/core/api_config.dart` and pass
  environment-specific values with `--dart-define=API_BASE_URL=...`.
- Preserve the API contract documented in `docs/API.md`.
- Before handing off changes, run backend tests, `dart format`,
  `flutter analyze`, and `flutter test`.
