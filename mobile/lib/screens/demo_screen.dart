import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/library_status.dart';
import '../state/library_controller.dart';
import '../widgets/common.dart';

class DemoScreen extends StatelessWidget {
  const DemoScreen({required this.controller, super.key});

  final LibraryController controller;

  Future<void> _run(
    BuildContext context,
    Future<bool> action,
    String successMessage,
  ) async {
    final succeeded = await action;
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            succeeded
                ? successMessage
                : controller.actionError ?? 'The demo action failed.',
          ),
          backgroundColor: succeeded ? AppColors.green : AppColors.red,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final status = controller.status!;
    final disabled = controller.isMutating;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OfflineBanner(controller: controller),
                const SectionHeading(
                  'Demo controls',
                  subtitle:
                      'Simulate hardware readings until the ESP32 is connected',
                ),
                const SizedBox(height: 10),
                Text(
                  'Every action is sent to the API, saved in MySQL, and then '
                  'refreshed automatically.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: 18),
                _ControlCard(
                  title: 'Library access',
                  icon: Icons.local_library_rounded,
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: disabled || status.isOpen
                              ? null
                              : () => _run(
                                  context,
                                  controller.setLibraryOpen(true),
                                  'Library opened.',
                                ),
                          icon: const Icon(Icons.lock_open_rounded),
                          label: const Text('Open library'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: disabled || !status.isOpen
                              ? null
                              : () => _run(
                                  context,
                                  controller.setLibraryOpen(false),
                                  'Library closed.',
                                ),
                          icon: const Icon(Icons.lock_rounded),
                          label: const Text('Close library'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ...status.seats.map(
                  (seat) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SeatControl(
                      seat: seat,
                      disabled: disabled,
                      onChanged: (occupied) => _run(
                        context,
                        controller.setSeatOccupied(seat.id, occupied),
                        'Seat ${seat.code} marked '
                        '${occupied ? 'occupied' : 'available'}.',
                      ),
                    ),
                  ),
                ),
                _ControlCard(
                  title: 'Motion sensor',
                  icon: Icons.sensors_rounded,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Motion detected'),
                    subtitle: Text(
                      status.motionDetected
                          ? 'Activity is currently detected'
                          : 'No activity is currently detected',
                    ),
                    value: status.motionDetected,
                    onChanged: disabled
                        ? null
                        : (value) => _run(
                            context,
                            controller.setMotionDetected(value),
                            value
                                ? 'Motion detection enabled.'
                                : 'Motion detection disabled.',
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                _ControlCard(
                  title: 'Staff RFID',
                  icon: Icons.contactless_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        status.staffPresent
                            ? 'Demo staff member is present.'
                            : 'Demo staff member is absent.',
                      ),
                      const SizedBox(height: 12),
                      FilledButton.tonalIcon(
                        onPressed: disabled
                            ? null
                            : () => _run(
                                context,
                                controller.simulateStaffScan(),
                                'Demo RFID card scanned.',
                              ),
                        icon: const Icon(Icons.nfc_rounded),
                        label: const Text('Simulate staff RFID scan'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _ControlCard(
                  title: 'Restore demo',
                  icon: Icons.restart_alt_rounded,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.red,
                    ),
                    onPressed: disabled
                        ? null
                        : () => _run(
                            context,
                            controller.resetDemo(),
                            'Demo information reset.',
                          ),
                    icon: const Icon(Icons.restore_rounded),
                    label: const Text('Reset demo information'),
                  ),
                ),
                if (disabled) ...[
                  const SizedBox(height: 18),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ControlCard extends StatelessWidget {
  const _ControlCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.navy),
                const SizedBox(width: 9),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            child,
          ],
        ),
      ),
    );
  }
}

class _SeatControl extends StatelessWidget {
  const _SeatControl({
    required this.seat,
    required this.disabled,
    required this.onChanged,
  });

  final SeatStatus seat;
  final bool disabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _ControlCard(
      title: 'Seat ${seat.code}',
      icon: Icons.event_seat_rounded,
      child: Row(
        children: [
          Expanded(
            child: FilledButton(
              onPressed: disabled || !seat.isOccupied
                  ? null
                  : () => onChanged(false),
              child: const Text('Mark available'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton(
              onPressed: disabled || seat.isOccupied
                  ? null
                  : () => onChanged(true),
              child: const Text('Mark occupied'),
            ),
          ),
        ],
      ),
    );
  }
}
