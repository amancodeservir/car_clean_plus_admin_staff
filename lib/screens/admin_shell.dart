import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants.dart';
import 'account_screens.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _items = <(IconData, String)>[
    (Icons.dashboard_outlined, 'Board'),
    (Icons.calendar_month_outlined, 'Book'),
    (Icons.group_outlined, 'People'),
    (Icons.grid_view_outlined, 'More'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const Text('Wash desk'),
        actions: const [DeskAlertButton()],
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
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _items[index].$1,
                            size: 22,
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
                              fontSize: 11,
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
