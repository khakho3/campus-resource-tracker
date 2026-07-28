import 'package:flutter/foundation.dart';

import '../models/library_status.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';

class LibraryController extends ChangeNotifier {
  LibraryController({required this.api, required this.cache});

  final LibraryApi api;
  final LibraryStatusCache cache;

  LibraryStatus? status;
  DateTime? lastSuccessfulUpdate;
  String? errorMessage;
  String? actionError;
  bool isLoading = true;
  bool isOffline = false;
  bool isMutating = false;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    final cached = await cache.load();
    if (cached != null) {
      status = cached.status;
      lastSuccessfulUpdate = cached.cachedAt;
      isOffline = true;
      isLoading = false;
      notifyListeners();
    }
    await refresh(showLoading: cached == null);
  }

  Future<void> refresh({bool showLoading = true}) async {
    if (showLoading && status == null) {
      isLoading = true;
      notifyListeners();
    }
    try {
      final freshStatus = await api.fetchStatus();
      final fetchedAt = DateTime.now().toUtc();
      status = freshStatus;
      lastSuccessfulUpdate = fetchedAt;
      errorMessage = null;
      isOffline = false;
      await cache.save(freshStatus, fetchedAt);
    } on Object catch (error) {
      if (status != null) {
        isOffline = true;
        errorMessage = null;
      } else {
        errorMessage = _messageFor(error);
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> setLibraryOpen(bool value) {
    return _mutate(() => api.updateLibraryState(isOpen: value));
  }

  Future<bool> setMotionDetected(bool value) {
    return _mutate(() => api.updateLibraryState(motionDetected: value));
  }

  Future<bool> setSeatOccupied(int seatId, bool value) {
    return _mutate(() => api.updateSeat(seatId: seatId, isOccupied: value));
  }

  Future<bool> simulateStaffScan() {
    return _mutate(() => api.scanStaff('DEMO-RFID-001'));
  }

  Future<bool> resetDemo() {
    return _mutate(api.resetDemo);
  }

  Future<bool> _mutate(Future<void> Function() action) async {
    isMutating = true;
    actionError = null;
    notifyListeners();
    try {
      await action();
      await refresh(showLoading: false);
      return true;
    } on Object catch (error) {
      actionError = _messageFor(error);
      return false;
    } finally {
      isMutating = false;
      notifyListeners();
    }
  }

  String _messageFor(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    return 'Something went wrong. Please try again.';
  }
}
