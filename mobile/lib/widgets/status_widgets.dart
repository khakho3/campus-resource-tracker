import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../models/library_status.dart';

class StatePresentation {
  const StatePresentation({
    required this.color,
    required this.icon,
    required this.title,
    required this.description,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String description;
}

StatePresentation presentationFor(LibraryStatus status) {
  switch (status.status) {
    case 'FULL':
      return const StatePresentation(
        color: AppColors.red,
        icon: Icons.event_seat_rounded,
        title: 'Library Full',
        description: 'No available study seats · 100% occupied',
      );
    case 'CLOSED':
      return StatePresentation(
        color: AppColors.amber,
        icon: Icons.lock_clock_rounded,
        title: 'Library Not Open',
        description:
            'Hours: ${formatClock(status.openingTime)} – '
            '${formatClock(status.closingTime)}',
      );
    case 'INACTIVE':
      return const StatePresentation(
        color: AppColors.amber,
        icon: Icons.motion_photos_off_rounded,
        title: 'No Recent Activity',
        description: 'The library is open, but motion is not detected',
      );
    default:
      return const StatePresentation(
        color: AppColors.green,
        icon: Icons.check_circle_rounded,
        title: 'Library Open',
        description: 'Seats are currently available',
      );
  }
}

class LibraryStatusCard extends StatelessWidget {
  const LibraryStatusCard({required this.status, super.key});

  final LibraryStatus status;

  @override
  Widget build(BuildContext context) {
    final presentation = presentationFor(status);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: presentation.color.withValues(alpha: 0.09),
        border: Border.all(color: presentation.color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: presentation.color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              presentation.icon,
              color: Colors.white,
              size: 28,
              semanticLabel: presentation.title,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  presentation.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: presentation.color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(presentation.description),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status.status,
              style: TextStyle(
                color: presentation.color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, semanticLabel: label),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class SeatSummaryCard extends StatelessWidget {
  const SeatSummaryCard({
    required this.seat,
    required this.libraryOpen,
    super.key,
  });

  final SeatStatus seat;
  final bool libraryOpen;

  @override
  Widget build(BuildContext context) {
    final isAvailable = libraryOpen && !seat.isOccupied;
    final color = !libraryOpen
        ? AppColors.muted
        : isAvailable
        ? AppColors.green
        : AppColors.red;
    final label = !libraryOpen
        ? 'Unavailable while closed'
        : isAvailable
        ? 'Available'
        : 'Occupied';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                seat.code,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Study Seat ${seat.code}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.circle, size: 9, color: color),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(label, style: TextStyle(color: color)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
