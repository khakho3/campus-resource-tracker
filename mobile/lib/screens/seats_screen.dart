import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../state/library_controller.dart';
import '../widgets/common.dart';

class SeatsScreen extends StatelessWidget {
  const SeatsScreen({required this.controller, super.key});

  final LibraryController controller;

  @override
  Widget build(BuildContext context) {
    final status = controller.status!;
    return RefreshablePage(
      onRefresh: controller.refresh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OfflineBanner(controller: controller),
          const SectionHeading(
            'Seat availability',
            subtitle: 'Sensor details for each GCTU Library seat',
          ),
          if (!status.isOpen) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3D6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Seat availability is disabled while the library is closed. '
                'Hours: ${formatClock(status.openingTime)} – '
                '${formatClock(status.closingTime)}.',
              ),
            ),
          ],
          const SizedBox(height: 18),
          ...status.seats.map(
            (seat) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SeatIcon(
                        code: seat.code,
                        occupied: seat.isOccupied,
                        enabled: status.isOpen,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Seat ${seat.code}',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 5),
                            _AvailabilityLabel(
                              occupied: seat.isOccupied,
                              enabled: status.isOpen,
                            ),
                            const SizedBox(height: 14),
                            Text(
                              seat.lastDistanceCm == null
                                  ? 'Sensor distance: Not reported'
                                  : 'Sensor distance: '
                                        '${seat.lastDistanceCm!.toStringAsFixed(1)} cm',
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Last update: '
                              '${formatDateTime(seat.updatedAt)}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeatIcon extends StatelessWidget {
  const _SeatIcon({
    required this.code,
    required this.occupied,
    required this.enabled,
  });

  final String code;
  final bool occupied;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = !enabled
        ? AppColors.muted
        : occupied
        ? AppColors.red
        : AppColors.green;
    return Container(
      width: 62,
      height: 62,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        code,
        style: TextStyle(
          color: color,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AvailabilityLabel extends StatelessWidget {
  const _AvailabilityLabel({required this.occupied, required this.enabled});

  final bool occupied;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = !enabled
        ? AppColors.muted
        : occupied
        ? AppColors.red
        : AppColors.green;
    final label = !enabled
        ? 'Unavailable while closed'
        : occupied
        ? 'Occupied'
        : 'Available';
    return Row(
      children: [
        Icon(Icons.circle, size: 10, color: color),
        const SizedBox(width: 7),
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
