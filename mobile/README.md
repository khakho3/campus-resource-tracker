# Campus Resource Tracker mobile app

Flutter Material 3 client for the GCTU Library availability MVP.

From this folder:

```powershell
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

For a physical phone, replace `10.0.2.2` with the development computer's
IPv4 address and keep both devices on the same network.

Quality checks:

```powershell
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```
