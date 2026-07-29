import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../state/library_controller.dart';
import '../widgets/common.dart';
import '../widgets/status_widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({required this.controller, super.key});

  final LibraryController controller;

  @override
  Widget build(BuildContext context) {
    final status = controller.status!;
    final presentation = presentationFor(status);
    final stateLabel = switch (status.status) {
      'AVAILABLE' => 'Open',
      'FULL' => 'Full',
      'CLOSED' => 'Closed',
      'INACTIVE' => 'Idle',
      _ => status.status,
    };
    return RefreshablePage(
      onRefresh: controller.refresh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OfflineBanner(controller: controller),
          Text(
            status.libraryName,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Live Library Availability',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 20),
          LibraryStatusCard(status: status),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 760 ? 4 : 2;
              return GridView.count(
                crossAxisCount: columns,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: columns == 4 ? 1.2 : 1.2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  MetricCard(
                    icon: Icons.event_available_rounded,
                    label: 'Available seats',
                    value: status.isOpen ? '${status.availableSeats}' : '—',
                    color: status.isOpen ? AppColors.green : AppColors.muted,
                  ),
                  MetricCard(
                    icon: Icons.event_seat_rounded,
                    label: 'Occupied seats',
                    value: status.isOpen ? '${status.occupiedSeats}' : '—',
                    color: status.isOpen ? AppColors.red : AppColors.muted,
                  ),
                  MetricCard(
                    icon: Icons.badge_rounded,
                    label: 'Staff',
                    value: status.staffPresent ? 'Present' : 'Absent',
                    color: status.staffPresent
                        ? AppColors.green
                        : AppColors.amber,
                  ),
                  MetricCard(
                    icon: presentation.icon,
                    label: 'Library state',
                    value: stateLabel,
                    color: presentation.color,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          const SectionHeading(
            'Occupancy',
            subtitle: 'Current library study-seat usage',
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${status.occupiedSeats} of ${status.totalSeats} '
                          'seats occupied',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        '${status.occupancyPercentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: status.occupancyPercentage / 100,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(10),
                    color: status.isFull ? AppColors.red : AppColors.green,
                    backgroundColor: AppColors.border,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeading('Study seats'),
          const SizedBox(height: 12),
          ...status.seats.map(
            (seat) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SeatSummaryCard(seat: seat, libraryOpen: status.isOpen),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Latest update ${formatDateTime(status.lastUpdateTime)}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}
