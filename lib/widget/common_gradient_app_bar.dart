import 'package:flutter/material.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/widget/kdv_logo.dart';

/// A reusable gradient app bar with customizable colors and content
class CommonGradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Color> gradientColors;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackTap;
  final bool centerTitle;
  final double elevation;
  final bool showLogo;
  final double logoSize;
  final Widget? leading;
  final double height;

  const CommonGradientAppBar({
    super.key,
    required this.title,
    this.gradientColors = const [AppColors.primaryBlue, AppColors.primaryTeal],
    this.actions,
    this.showBackButton = true,
    this.onBackTap,
    this.centerTitle = true,
    this.elevation = 0,
    this.showLogo = true,
    this.logoSize = 32,
    this.leading,
    this.height = kToolbarHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height + MediaQuery.of(context).padding.top,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: gradientColors.last.withAlpha(40),
                  blurRadius: elevation * 4,
                  offset: Offset(0, elevation),
                ),
              ]
            : null,
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (showBackButton && leading == null)
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: onBackTap ?? () => Navigator.of(context).pop(),
              )
            else if (leading != null)
              leading!,
            if (showLogo) ...[
              const SizedBox(width: 8),
              KDVLogo(
                size: logoSize,
                primaryColor: AppColors.buttonColor,
                secondaryColor: Colors.white,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: centerTitle
                  ? Center(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            if (actions != null) ...actions!,
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}
