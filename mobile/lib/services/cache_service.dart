import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/library_status.dart';

class CachedStatus {
  const CachedStatus({required this.status, required this.cachedAt});

  final LibraryStatus status;
  final DateTime cachedAt;
}

abstract class LibraryStatusCache {
  Future<CachedStatus?> load();

  Future<void> save(LibraryStatus status, DateTime cachedAt);
}

class PreferencesStatusCache implements LibraryStatusCache {
  PreferencesStatusCache(this._preferences);

  static const String _cacheKey = 'gctu_library_status_v1';
  final SharedPreferences _preferences;

  @override
  Future<CachedStatus?> load() async {
    final raw = _preferences.getString(_cacheKey);
    if (raw == null) {
      return null;
    }
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return CachedStatus(
        status: LibraryStatus.fromJson(json['status'] as Map<String, dynamic>),
        cachedAt: DateTime.parse(json['cached_at'] as String),
      );
    } on Object {
      await _preferences.remove(_cacheKey);
      return null;
    }
  }

  @override
  Future<void> save(LibraryStatus status, DateTime cachedAt) async {
    await _preferences.setString(
      _cacheKey,
      jsonEncode({
        'cached_at': cachedAt.toUtc().toIso8601String(),
        'status': status.toJson(),
      }),
    );
  }
}
