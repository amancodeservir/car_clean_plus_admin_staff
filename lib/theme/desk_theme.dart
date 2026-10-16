import 'package:flutter/material.dart';

import '../core/constants.dart';

const double deskIconSize = 22;
const String deskFont = 'PlusJakartaSans';

const TextStyle deskHeadline = TextStyle(
  fontFamily: deskFont,
  color: AppConstants.ink,
  fontSize: 26,
  fontWeight: FontWeight.w700,
  height: 1.1,
  letterSpacing: -0.4,
);

const TextStyle deskTitle = TextStyle(
  fontFamily: deskFont,
  color: AppConstants.ink,
  fontSize: 16,
  fontWeight: FontWeight.w700,
  height: 1.2,
  letterSpacing: -0.2,
);

const TextStyle deskRow = TextStyle(
  fontFamily: deskFont,
  color: AppConstants.ink,
  fontSize: 14,
  fontWeight: FontWeight.w700,
  height: 1.2,
);

const TextStyle deskBody = TextStyle(
  fontFamily: deskFont,
  color: AppConstants.ink,
  fontSize: 14,
  height: 1.35,
);

const TextStyle deskCaption = TextStyle(
  fontFamily: deskFont,
  color: AppConstants.muted,
  fontSize: 12,
  height: 1.25,
);

const TextStyle deskButton = TextStyle(
  fontFamily: deskFont,
  fontSize: 16,
  fontWeight: FontWeight.w700,
  height: 1.2,
);

const TextTheme deskText = TextTheme(
  displayLarge: deskHeadline,
  displayMedium: deskHeadline,
  displaySmall: deskHeadline,
  headlineLarge: deskHeadline,
  headlineMedium: deskHeadline,
  headlineSmall: deskTitle,
  titleLarge: deskTitle,
  titleMedium: deskTitle,
  titleSmall: deskRow,
  bodyLarge: deskBody,
  bodyMedium: deskBody,
  bodySmall: deskCaption,
  labelLarge: deskButton,
  labelMedium: deskCaption,
  labelSmall: deskCaption,
);

class DeskTheme {
  static ThemeData get data {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppConstants.line),
    );
    return ThemeData(
      useMaterial3: true,
      fontFamily: deskFont,
      scaffoldBackgroundColor: AppConstants.paper,
      textTheme: deskText,
      primaryTextTheme: deskText,
      colorScheme: const ColorScheme.light(
        primary: AppConstants.accent,
        onPrimary: Colors.white,
        secondary: AppConstants.accent,
        onSecondary: Colors.white,
        surface: AppConstants.card,
        onSurface: AppConstants.ink,
        error: AppConstants.danger,
      ),
      iconTheme: const IconThemeData(color: AppConstants.accent, size: deskIconSize),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppConstants.paper,
        foregroundColor: AppConstants.ink,
        surfaceTintColor: AppConstants.paper,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppConstants.ink, size: deskIconSize),
        titleTextStyle: deskTitle,
      ),
      cardTheme: const CardThemeData(
        color: AppConstants.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: AppConstants.line),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppConstants.card,
        titleTextStyle: deskTitle,
        contentTextStyle: deskBody,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: AppConstants.line),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppConstants.ink,
        contentTextStyle: deskBody.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: const StadiumBorder(),
      ),
      dividerTheme: const DividerThemeData(color: AppConstants.line, thickness: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppConstants.accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppConstants.line,
          disabledForegroundColor: AppConstants.muted,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: const StadiumBorder(),
          textStyle: deskButton,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppConstants.accent,
          side: const BorderSide(color: AppConstants.line),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: const StadiumBorder(),
          textStyle: deskButton,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppConstants.accent,
          textStyle: deskButton,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppConstants.accent,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: StadiumBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        labelStyle: deskCaption,
        hintStyle: deskCaption,
        prefixIconColor: AppConstants.accent,
        border: border,
        enabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppConstants.accent, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: AppConstants.iconWell,
        disabledColor: AppConstants.paper,
        labelStyle: const TextStyle(
          color: AppConstants.ink,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: const TextStyle(
          color: AppConstants.accent,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        side: const BorderSide(color: AppConstants.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        showCheckmark: false,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return AppConstants.accent;
            return Colors.white;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return Colors.white;
            return AppConstants.ink;
          }),
          side: const WidgetStatePropertyAll(BorderSide(color: AppConstants.line)),
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          iconSize: const WidgetStatePropertyAll(deskIconSize),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontWeight: FontWeight.w700, fontSize: 12, height: 1.25),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return AppConstants.muted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppConstants.accent;
          return AppConstants.line;
        }),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppConstants.accent),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppConstants.iconWell,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppConstants.accent,
        textColor: AppConstants.ink,
        titleTextStyle: deskRow,
        subtitleTextStyle: deskCaption,
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      ),
    );
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 3,
      decoration: BoxDecoration(
        color: AppConstants.signal,
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}

class IconWell extends StatelessWidget {
  const IconWell({super.key, required this.icon, this.iconColor});

  final IconData icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppConstants.iconWell,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: deskIconSize, color: iconColor ?? AppConstants.accent),
    );
  }
}

class DeskPhoto extends StatelessWidget {
  const DeskPhoto({
    super.key,
    required this.asset,
    this.height = 140,
    this.width,
  });

  final String asset;
  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: height,
        width: width ?? double.infinity,
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return ColoredBox(
              color: AppConstants.iconWell,
              child: const Center(
                child: Icon(Icons.image_outlined, size: 22, color: AppConstants.accent),
              ),
            );
          },
        ),
      ),
    );
  }
}

class DeskCard extends StatelessWidget {
  const DeskCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.onTap,
    this.margin = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: AppConstants.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.line),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final tone = statusTone(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        prettyStatus(status),
        style: TextStyle(
          color: tone.foreground,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
      ),
    );
  }
}

class MetaRow extends StatelessWidget {
  const MetaRow({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: deskIconSize, color: AppConstants.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text.isEmpty ? '—' : text,
              style: deskBody,
            ),
          ),
        ],
      ),
    );
  }
}

class DeskAction extends StatelessWidget {
  const DeskAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: StadiumBorder(side: const BorderSide(color: AppConstants.line)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: deskIconSize, color: AppConstants.accent),
              const SizedBox(width: 8),
              Text(
                label,
                style: deskRow,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DeskEmpty extends StatelessWidget {
  const DeskEmpty({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 8),
      child: Column(
        children: [
          Row(
            children: const [
              Expanded(child: DeskPhoto(asset: AppConstants.basicWash, height: 112)),
              SizedBox(width: 12),
              Expanded(child: DeskPhoto(asset: AppConstants.interiorWash, height: 112)),
            ],
          ),
          const SizedBox(height: 14),
          const Icon(Icons.inbox_outlined, size: 22, color: AppConstants.muted),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: deskBody.copyWith(color: AppConstants.muted),
          ),
        ],
      ),
    );
  }
}

class StatusTone {
  const StatusTone(this.foreground, this.background);

  final Color foreground;
  final Color background;
}

StatusTone statusTone(String status) {
  switch (status) {
    case 'completed':
      return const StatusTone(AppConstants.completed, AppConstants.completedBg);
    case 'in_progress':
    case 'on_the_way':
    case 'accepted':
      return const StatusTone(AppConstants.progress, AppConstants.progressBg);
    case 'cancelled':
    case 'blocked':
      return const StatusTone(AppConstants.danger, AppConstants.dangerBg);
    default:
      return const StatusTone(AppConstants.pending, AppConstants.pendingBg);
  }
}

String sourceLabel(String source) {
  switch (source) {
    case 'app':
      return 'App';
    case 'phone':
      return 'Phone';
    case 'admin_block':
      return 'Desk block';
    case 'website':
    case '':
      return 'Website';
    default:
      return prettyStatus(source);
  }
}

String prettyStatus(String status) {
  return status
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String washAssetFor(String service) {
  final name = service.toLowerCase();
  if (name.contains('interior') || name.contains('complete')) {
    return AppConstants.interiorWash;
  }
  return AppConstants.basicWash;
}

const statusSteps = <(String, String, IconData)>[
  ('pending', 'Booked', Icons.hourglass_bottom_outlined),
  ('accepted', 'Accepted', Icons.check_circle_outlined),
  ('on_the_way', 'On the way', Icons.directions_car_outlined),
  ('in_progress', 'Washing', Icons.autorenew_outlined),
  ('completed', 'Done', Icons.task_alt_outlined),
];

int statusStepIndex(String status) {
  switch (status) {
    case 'accepted':
      return 1;
    case 'on_the_way':
      return 2;
    case 'in_progress':
      return 3;
    case 'completed':
      return 4;
    default:
      return 0;
  }
}

String? nextStatusAfter(String status) {
  switch (status) {
    case 'pending':
    case 'confirmed':
    case 'lead':
      return 'accepted';
    case 'accepted':
      return 'on_the_way';
    case 'on_the_way':
      return 'in_progress';
    case 'in_progress':
      return 'completed';
    default:
      return null;
  }
}

class StatusTree extends StatelessWidget {
  const StatusTree({
    super.key,
    required this.status,
    this.onShift = true,
    this.onNext,
  });

  final String status;
  final bool onShift;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    if (status == 'cancelled' || status == 'blocked') {
      return Row(
        children: [
          Icon(statusIcon(status), size: 22, color: AppConstants.danger),
          const SizedBox(width: 8),
          Text(
            prettyStatus(status),
            style: deskRow.copyWith(color: AppConstants.danger),
          ),
        ],
      );
    }

    final current = statusStepIndex(status);
    final next = nextStatusAfter(status);
    final canMove = onNext != null && (next != 'accepted' || onShift);

    return Column(
      children: [
        for (var index = 0; index < statusSteps.length; index++)
          _StatusNode(
            label: index == 0 && (status == 'confirmed' || status == 'pending')
                ? prettyStatus(status)
                : statusSteps[index].$2,
            icon: statusSteps[index].$3,
            done: index < current || status == 'completed',
            here: index == current && status != 'completed',
            last: index == statusSteps.length - 1,
            action: index == current + 1 && next != null
                ? (canMove ? 'Mark ${statusSteps[index].$2.toLowerCase()}' : 'Turn on shift to accept')
                : null,
            onAction: index == current + 1 && canMove ? onNext : null,
          ),
      ],
    );
  }
}

class _StatusNode extends StatelessWidget {
  const _StatusNode({
    required this.label,
    required this.icon,
    required this.done,
    required this.here,
    required this.last,
    required this.action,
    required this.onAction,
  });

  final String label;
  final IconData icon;
  final bool done;
  final bool here;
  final bool last;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final color = done || here ? AppConstants.accent : AppConstants.muted;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          child: Column(
            children: [
              Icon(
                done ? Icons.check_circle_outlined : icon,
                size: 22,
                color: color,
              ),
              if (!last)
                Container(
                  width: 1.5,
                  height: action == null ? 18 : 46,
                  color: done ? AppConstants.accent : AppConstants.line,
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: last ? 0 : 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: (here || done ? deskRow : deskBody).copyWith(
                    color: here || done ? AppConstants.ink : AppConstants.muted,
                  ),
                ),
                if (here)
                  const Text(
                    'Now',
                    style: TextStyle(color: AppConstants.accent, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                if (action != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: onAction,
                      icon: Icon(
                        onAction == null ? Icons.lock_outlined : Icons.arrow_forward_outlined,
                        size: deskIconSize,
                      ),
                      label: Text(action!),
                      style: TextButton.styleFrom(
                        foregroundColor: onAction == null ? AppConstants.muted : AppConstants.accent,
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

IconData statusIcon(String status) {
  switch (status) {
    case 'lead':
      return Icons.flag_outlined;
    case 'pending':
      return Icons.hourglass_bottom_outlined;
    case 'confirmed':
      return Icons.event_available_outlined;
    case 'accepted':
      return Icons.check_circle_outlined;
    case 'on_the_way':
      return Icons.directions_car_outlined;
    case 'in_progress':
      return Icons.autorenew_outlined;
    case 'completed':
      return Icons.task_alt_outlined;
    case 'cancelled':
      return Icons.cancel_outlined;
    case 'blocked':
      return Icons.do_not_disturb_outlined;
    default:
      return Icons.label_outlined;
  }
}

/// What a role is called on screen.
String roleLabel(String role) {
  switch (role) {
    case 'superadmin':
      return 'Super admin';
    case 'admin':
      return 'Admin';
    case 'staff':
      return 'Washer';
    case 'customer':
      return 'Customer';
    default:
      return role;
  }
}

/// ₹1,23,456 style amounts, whole rupees.
String rupees(num value) {
  final whole = value.round().abs().toString();
  if (whole.length <= 3) return '${value < 0 ? '-' : ''}₹$whole';
  final last = whole.substring(whole.length - 3);
  var rest = whole.substring(0, whole.length - 3);
  final groups = <String>[];
  while (rest.length > 2) {
    groups.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) groups.insert(0, rest);
  return '${value < 0 ? '-' : ''}₹${groups.join(',')},$last';
}

/// "12 Oct, 3:05 PM" in the phone's time zone.
String whenText(String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
  final local = parsed.toLocal();
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.day} ${months[local.month - 1]}, $hour:$minute ${local.hour < 12 ? 'AM' : 'PM'}';
}
