import 'package:campus_resource_tracker/app.dart';
import 'package:campus_resource_tracker/services/cache_service.dart';
import 'package:campus_resource_tracker/state/library_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_support.dart';

void main() {
  testWidgets('dashboard and bottom navigation show MVP screens', (
    WidgetTester tester,
  ) async {
    final controller = LibraryController(
      api: FakeLibraryApi(),
      cache: MemoryStatusCache(),
    );
    await controller.initialize();

    await tester.pumpWidget(
      CampusResourceTrackerApp(controller: controller, showSplash: false),
    );
    await tester.pumpAndSettle();

    expect(find.text('Live Library Availability'), findsOneWidget);
    expect(find.text('Library Open'), findsOneWidget);
    expect(find.text('1'), findsNWidgets(2));

    await tester.tap(find.text('Seats'));
    await tester.pumpAndSettle();
    expect(find.text('Seat availability'), findsOneWidget);
    expect(find.text('Sensor distance: 18.5 cm'), findsOneWidget);

    await tester.tap(find.text('Activity'));
    await tester.pumpAndSettle();
    expect(find.text('Library activity'), findsOneWidget);
    expect(find.text('Demo'), findsNothing);
  });

  testWidgets('cached data shows a clear offline banner and retry button', (
    WidgetTester tester,
  ) async {
    final cachedAt = DateTime.utc(2026, 7, 28, 10);
    final controller = LibraryController(
      api: FakeLibraryApi(shouldFail: true),
      cache: MemoryStatusCache(
        cached: CachedStatus(status: sampleStatus(), cachedAt: cachedAt),
      ),
    );
    await controller.initialize();

    await tester.pumpWidget(
      CampusResourceTrackerApp(controller: controller, showSplash: false),
    );
    await tester.pumpAndSettle();

    expect(find.text('You are offline'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Retry'), findsOneWidget);
    expect(find.textContaining('may be outdated'), findsOneWidget);
  });

  testWidgets('splash screen includes project identity', (
    WidgetTester tester,
  ) async {
    final controller = LibraryController(
      api: FakeLibraryApi(),
      cache: MemoryStatusCache(),
    );

    await tester.pumpWidget(CampusResourceTrackerApp(controller: controller));

    expect(find.text('Campus Resource Tracker'), findsOneWidget);
    expect(find.text('Smart Library Availability'), findsOneWidget);
    expect(find.byIcon(Icons.local_library_rounded), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
    expect(find.text('Live Library Availability'), findsOneWidget);
  });
}
