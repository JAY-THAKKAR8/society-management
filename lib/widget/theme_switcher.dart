import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/theme/theme_provider.dart';

/// A widget for switching between light and dark themes
class ThemeSwitcher extends StatelessWidget {
  final bool showLabel;
  final double size;
  final EdgeInsetsGeometry padding;

  const ThemeSwitcher({
    super.key,
    this.showLabel = true,
    this.size = 24,
    this.padding = const EdgeInsets.all(8),
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeState>(
      builder: (context, state) {
        final isDark = state == ThemeState.dark;
        
        return InkWell(
          onTap: () {
            context.read<ThemeCubit>().toggleTheme();
          },
          borderRadius: BorderRadius.circular(30),
          child: Padding(
            padding: padding,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                  size: size,
                  color: isDark 
                      ? AppColors.primaryOrange 
                      : AppColors.primaryBlue,
                ),
                if (showLabel) ...[
                  const SizedBox(width: 8),
                  Text(
                    isDark ? 'Dark Mode' : 'Light Mode',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark 
                          ? AppColors.darkText 
                          : AppColors.lightText,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
