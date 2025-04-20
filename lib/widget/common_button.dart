import 'package:flutter/material.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/utility/extentions/colors_extnetions.dart';
import 'package:society_management/widget/custom_progress_indecator.dart';

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
    return Container(
      constraints: BoxConstraints(
        maxWidth: width ?? double.infinity,
        maxHeight: height ?? double.infinity,
      ),
      decoration: BoxDecoration(
        border: showBorder ? Border.all(color: AppColors.buttonColor, width: 1) : null,
        borderRadius: BorderRadius.circular(borderRadius ?? 100),
        boxShadow: removeShadow
            ? null
            : [
                BoxShadow(
                  color: AppColors.buttonColor.withOpacity2(0.31),
                  spreadRadius: 0,
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          padding: padding ?? EdgeInsets.symmetric(vertical: isLoading ? 14 : 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius ?? 100.0)),
        ),
        onPressed: isLoading ? () {} : onTap,
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CustomProgressIndecator(
                  color: AppColors.white,
                  strokeWidth: 3,
                ),
              )
            : text != null
                ? Text(
                    text ?? '',
                    style: textStyle ??
                        Theme.of(context).elevatedButtonTheme.style?.textStyle?.resolve({})?.copyWith(
                          color: textColor,
                        ),
                  )
                : icon,
      ),
    );
  }
}
