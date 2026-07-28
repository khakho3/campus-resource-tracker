import 'package:campus_resource_tracker/models/library_status.dart';
import 'package:campus_resource_tracker/services/api_service.dart';
import 'package:campus_resource_tracker/services/cache_service.dart';

LibraryStatus sampleStatus() {
  final updatedAt = DateTime.utc(2026, 7, 28, 10, 30);
  return LibraryStatus(
    libraryId: 1,
    libraryName: 'GCTU Library',
    isOpen: true,
    openingTime: '08:00:00',
    closingTime: '20:00:00',
    motionDetected: true,
    totalSeats: 2,
    occupiedSeats: 1,
    availableSeats: 1,
    occupancyPercentage: 50,
    isFull: false,
    status: 'AVAILABLE',
    staffPresent: true,
    seats: [
      SeatStatus(
        id: 1,
        code: 'A1',
        isOccupied: true,
        lastDistanceCm: 18.5,
        updatedAt: updatedAt,
      ),
      SeatStatus(
        id: 2,
        code: 'A2',
        isOccupied: false,
        lastDistanceCm: 90.2,
        updatedAt: updatedAt,
      ),
    ],
    lastUpdateTime: updatedAt,
  );
}

class FakeLibraryApi implements LibraryApi {
  FakeLibraryApi({LibraryStatus? status, this.shouldFail = false})
    : _status = status ?? sampleStatus();

  final LibraryStatus _status;
  final bool shouldFail;
  int fetchCount = 0;

  @override
  Future<LibraryStatus> fetchStatus() async {
    fetchCount += 1;
    if (shouldFail) {
      throw const ApiException('Offline for test');
    }
    return _status;
  }

  @override
  Future<void> resetDemo() async {}

  @override
  Future<void> scanStaff(String rfidUid) async {}

  @override
  Future<void> updateLibraryState({bool? isOpen, bool? motionDetected}) async {}

  @override
  Future<void> updateSeat({
    required int seatId,
    required bool isOccupied,
  }) async {}
}

class MemoryStatusCache implements LibraryStatusCache {
  MemoryStatusCache({this.cached});

  CachedStatus? cached;

  @override
  Future<CachedStatus?> load() async => cached;

  @override
  Future<void> save(LibraryStatus status, DateTime cachedAt) async {
    cached = CachedStatus(status: status, cachedAt: cachedAt);
  }
}
