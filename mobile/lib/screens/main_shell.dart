import 'package:flutter/material.dart';

import '../state/library_controller.dart';
import 'activity_screen.dart';
import 'dashboard_screen.dart';
import 'seats_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({required this.controller, super.key});

  final LibraryController controller;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        return Scaffold(
          appBar: AppBar(
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Campus Resource Tracker',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                Text(
                  'GCTU Library',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: controller.isLoading ? null : controller.refresh,
                tooltip: 'Refresh library information',
                icon: controller.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: _buildBody(controller),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) =>
                setState(() => _selectedIndex = index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.event_seat_outlined),
                selectedIcon: Icon(Icons.event_seat_rounded),
                label: 'Seats',
              ),
              NavigationDestination(
                icon: Icon(Icons.sensors_outlined),
                selectedIcon: Icon(Icons.sensors_rounded),
                label: 'Activity',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(LibraryController controller) {
    if (controller.isLoading && controller.status == null) {
      return const _LoadingView();
    }
    if (controller.status == null) {
      return _ErrorView(
        message:
            controller.errorMessage ??
            'Library information could not be loaded.',
        onRetry: controller.refresh,
      );
    }
    return IndexedStack(
      index: _selectedIndex,
      children: [
        DashboardScreen(controller: controller),
        SeatsScreen(controller: controller),
        ActivityScreen(controller: controller),
      ],
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading library availability…'),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function({bool showLoading}) onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 54,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 14),
            Text(
              'Unable to load the library',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
