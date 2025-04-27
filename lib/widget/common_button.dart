import 'package:flutter/material.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/widget/custom_progress_indecator.dart';
import 'package:society_management/widget/trading_style_button.dart';

class CommonButton extends StatelessWidget {
  const CommonButton({
    this.text,
    required this.onTap,
    super.key,
    this.isLoading = false,
    this.backgroundColor,
    this.removeShadow = false,
    this.showBorder = false,
    this.textColor,
    this.width,
    this.icon,
    this.padding,
    this.textStyle,
    this.borderRadius,
    this.height,
  });
  final String? text;
  final void Function()? onTap;
  final bool isLoading;
  final Color? backgroundColor;
  final bool removeShadow;
  final Color? textColor;
  final double? width;
  final double? height;
  final Widget? icon;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;
  final double? borderRadius;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        width: width,
        height: height,
        child: TradingStyleButton(
          text: text ?? '',
          onPressed: () {}, // Disabled during loading
          showChartIcons: false,
          startColor: backgroundColor,
          height: height ?? 50,
          child: const SizedBox(
            height: 24,
            width: 24,
            child: CustomProgressIndecator(
              color: AppColors.white,
              strokeWidth: 3,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: TradingStyleButton(
        text: text ?? '',
        onPressed: onTap ?? () {},
        showChartIcons: false,
        startColor: backgroundColor,
        height: height ?? 50,
        child: icon,
      ),
    );
  }
}
