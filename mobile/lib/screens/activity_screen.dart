import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../state/library_controller.dart';
import '../widgets/common.dart';
import '../widgets/status_widgets.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({required this.controller, super.key});

  final LibraryController controller;

  @override
  Widget build(BuildContext context) {
    final status = controller.status!;
    final presentation = presentationFor(status);
    return RefreshablePage(
      onRefresh: controller.refresh,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OfflineBanner(controller: controller),
          const SectionHeading(
            'Library activity',
            subtitle: 'Motion, staff, hours, and current operating state',
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Column(
                children: [
                  InfoRow(
                    icon: Icons.sensors_rounded,
                    label: 'Motion status',
                    value: status.motionDetected
                        ? 'Activity detected'
                        : 'Inactive',
                    valueColor: status.motionDetected
                        ? AppColors.green
                        : AppColors.amber,
                  ),
                  const Divider(height: 1),
                  InfoRow(
                    icon: Icons.badge_rounded,
                    label: 'Staff presence',
                    value: status.staffPresent ? 'Present' : 'Absent',
                    valueColor: status.staffPresent
                        ? AppColors.green
                        : AppColors.amber,
                  ),
                  const Divider(height: 1),
                  InfoRow(
                    icon: Icons.schedule_rounded,
                    label: 'Opening time',
                    value: formatClock(status.openingTime),
                  ),
                  const Divider(height: 1),
                  InfoRow(
                    icon: Icons.nights_stay_rounded,
                    label: 'Closing time',
                    value: formatClock(status.closingTime),
                  ),
                  const Divider(height: 1),
                  InfoRow(
                    icon: presentation.icon,
                    label: 'Current library state',
                    value: status.status,
                    valueColor: presentation.color,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const Icon(
                    Icons.update_rounded,
                    color: AppColors.navy,
                    size: 28,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Latest update',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 3),
                        Text(formatDateTime(status.lastUpdateTime)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
