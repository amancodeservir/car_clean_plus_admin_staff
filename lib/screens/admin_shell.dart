import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants.dart';
import '../theme/desk_theme.dart';
import 'account_screens.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _items = <(IconData, String)>[
    (Icons.dashboard_outlined, 'Home'),
    (Icons.calendar_month_outlined, 'Bookings'),
    (Icons.group_outlined, 'People'),
    (Icons.grid_view_outlined, 'More'),
  ];

  static const _titles = ['Dashboard', 'Bookings', 'People', 'More'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Text(_titles[shell.currentIndex], style: deskTitle),
        actions: [
          IconButton(
            tooltip: 'Customer chats',
            onPressed: () => context.push('/desk/inbox'),
            icon: const Icon(Icons.forum_outlined, size: 22, color: AppConstants.accent),
          ),
          const DeskAlertButton(),
        ],
      ),
      body: shell,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppConstants.line)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              for (var index = 0; index < _items.length; index++)
                Expanded(
                  child: InkWell(
                    onTap: () => shell.goBranch(
                      index,
                      initialLocation: index == shell.currentIndex,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _items[index].$1,
                            size: deskIconSize,
                            color: shell.currentIndex == index
                                ? AppConstants.accent
                                : AppConstants.muted,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _items[index].$2,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: shell.currentIndex == index
                                  ? AppConstants.accent
                                  : AppConstants.muted,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
