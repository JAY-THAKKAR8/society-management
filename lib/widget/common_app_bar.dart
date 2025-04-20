import 'package:flutter/material.dart';
import 'package:society_management/constants/app_assets.dart';
import 'package:society_management/widget/app_svg_image.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CommonAppBar({
    super.key,
    this.onBackTap,
    this.title,
    this.titleWidget,
    this.actions,
    this.elivation,
    this.titleSpacing,
    this.leadingWidget,
    this.leadingWidth,
    this.centerTitle = false,
    this.showDivider = false,
  });
  final VoidCallback? onBackTap;
  final String? title;
  final Widget? titleWidget;
  final Widget? leadingWidget;
  final List<Widget>? actions;
  final double? elivation;
  final double? titleSpacing;
  final double? leadingWidth;
  final bool centerTitle;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBar(
          leading: onBackTap != null
              ? IconButton(
                  splashRadius: 24,
                  onPressed: onBackTap,
                  icon: const AppSvgImage(
                    AppAssets.leftArrowIcon,
                    height: 24,
                    width: 24,
                  ))
              : leadingWidget,
          centerTitle: centerTitle,
          leadingWidth: onBackTap != null ? null : leadingWidth,
          titleSpacing: titleSpacing ?? 0,
          title: title != null
              ? Text(
                  title!,
                  style: Theme.of(context).textTheme.bodyLarge,
                )
              : titleWidget,
          actions: actions,
          elevation: elivation ?? 0,
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }

  @override
  Size get preferredSize => showDivider ? AppBar().preferredSize + const Offset(0, 1) : AppBar().preferredSize;
}
