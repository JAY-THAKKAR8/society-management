import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/theme/theme_provider.dart';

/// An enhanced widget for switching between light and dark themes
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

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              context.read<ThemeCubit>().toggleTheme();
            },
            borderRadius: BorderRadius.circular(30),
            child: Padding(
              padding: padding,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0x1AFF8008) // 10% opacity of primaryOrange
                          : const Color(0x1A38B6FF), // 10% opacity of primaryBlue
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isDark ? Icons.dark_mode : Icons.light_mode,
                      size: size,
                      color: isDark ? AppColors.primaryOrange : AppColors.primaryBlue,
                    ),
                  ),
                  if (showLabel) ...[
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isDark ? 'Dark Mode' : 'Light Mode',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Tap to switch theme',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0x99F8F9FA) : const Color(0x99111827),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
