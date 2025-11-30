import 'package:flutter/material.dart';
import '../theme/adminlte_theme.dart';

/// Info Box widget estilo AdminLTE 3
class AdminLTEInfoBox extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const AdminLTEInfoBox({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AdminLTETheme.cardBorderRadius),
      child: Container(
        decoration: AdminLTETheme.infoBoxDecoration(color),
        padding: const EdgeInsets.all(AdminLTETheme.paddingMedium),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: AdminLTETheme.paddingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: AdminLTETheme.h4.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: AdminLTETheme.caption.copyWith(
                      color: AdminLTETheme.textMuted,
                    ),
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

/// Small Box widget estilo AdminLTE 3
class AdminLTESmallBox extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback? onTap;

  const AdminLTESmallBox({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AdminLTETheme.cardBorderRadius),
      child: Container(
        decoration: AdminLTETheme.smallBoxDecoration(gradient),
        padding: const EdgeInsets.all(AdminLTETheme.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AdminLTETheme.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AdminLTETheme.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(icon, color: AdminLTETheme.white.withOpacity(0.3), size: 60),
              ],
            ),
            if (onTap != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Más información',
                      style: TextStyle(
                        color: AdminLTETheme.white,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_circle_right, color: AdminLTETheme.white, size: 16),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Card widget estilo AdminLTE 3
class AdminLTECard extends StatelessWidget {
  final String? title;
  final Widget child;
  final List<Widget>? actions;
  final bool collapsible;
  final bool removable;
  final Color? headerColor;

  const AdminLTECard({
    super.key,
    this.title,
    required this.child,
    this.actions,
    this.collapsible = false,
    this.removable = false,
    this.headerColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AdminLTETheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Container(
              padding: const EdgeInsets.all(AdminLTETheme.paddingMedium),
              decoration: BoxDecoration(
                color: headerColor ?? AdminLTETheme.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AdminLTETheme.cardBorderRadius),
                  topRight: Radius.circular(AdminLTETheme.cardBorderRadius),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title!,
                      style: AdminLTETheme.h6.copyWith(
                        color: headerColor != null 
                            ? AdminLTETheme.white 
                            : AdminLTETheme.primary,
                      ),
                    ),
                  ),
                  if (actions != null) ...actions!,
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AdminLTETheme.paddingMedium),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Badge widget estilo AdminLTE 3
class AdminLTEBadge extends StatelessWidget {
  final String text;
  final Color color;
  final bool outlined;

  const AdminLTEBadge({
    super.key,
    required this.text,
    required this.color,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color,
        border: outlined ? Border.all(color: color) : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: outlined ? color : AdminLTETheme.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Button widget estilo AdminLTE 3
class AdminLTEButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? color;
  final IconData? icon;
  final bool outlined;
  final bool block;

  const AdminLTEButton({
    super.key,
    required this.text,
    this.onPressed,
    this.color,
    this.icon,
    this.outlined = false,
    this.block = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? AdminLTETheme.primary;
    
    final button = outlined
        ? OutlinedButton.icon(
            onPressed: onPressed,
            icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
            label: Text(text),
            style: OutlinedButton.styleFrom(
              foregroundColor: buttonColor,
              side: BorderSide(color: buttonColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AdminLTETheme.buttonBorderRadius),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          )
        : ElevatedButton.icon(
            onPressed: onPressed,
            icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
            label: Text(text),
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: AdminLTETheme.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AdminLTETheme.buttonBorderRadius),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          );
    
    return block ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Alert widget estilo AdminLTE 3
class AdminLTEAlert extends StatelessWidget {
  final String message;
  final Color color;
  final IconData icon;
  final bool dismissible;

  const AdminLTEAlert({
    super.key,
    required this.message,
    required this.color,
    required this.icon,
    this.dismissible = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AdminLTETheme.paddingMedium),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(AdminLTETheme.cardBorderRadius),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontSize: 14),
            ),
          ),
          if (dismissible)
            IconButton(
              icon: Icon(Icons.close, color: color, size: 18),
              onPressed: () {},
            ),
        ],
      ),
    );
  }
}
