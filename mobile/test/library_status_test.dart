import 'package:campus_resource_tracker/models/library_status.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_support.dart';

void main() {
  test('library status survives cache JSON round trip', () {
    final original = sampleStatus();

    final decoded = LibraryStatus.fromJson(original.toJson());

    expect(decoded.libraryName, 'GCTU Library');
    expect(decoded.status, 'AVAILABLE');
    expect(decoded.availableSeats, 1);
    expect(decoded.seats.map((seat) => seat.code), ['A1', 'A2']);
    expect(decoded.seats.first.lastDistanceCm, 18.5);
  });

  test('API timestamps without a timezone are treated as UTC', () {
    final parsed = parseApiDate('2026-07-28T10:30:00');

    expect(parsed.isUtc, isTrue);
    expect(parsed.hour, 10);
  });
}
