import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:society_management/constants/app_colors.dart';
import 'package:society_management/utility/extentions/colors_extnetions.dart';

class AppTextFormField extends StatelessWidget {
  const AppTextFormField({
    super.key,
    required this.controller,
    this.hintText,
    this.enabled,
    this.validator,
    this.suffixIcon,
    this.obscureText = false,
    this.useShadow = false,
    this.readOnly = false,
    this.textCenter = false,
    this.maxLines = 1,
    this.minLines,
    this.textInputAction,
    this.contentPadding,
    this.keyboardType,
    this.title,
    this.hintStyle,
    this.inputFormatters,
    this.prefixIcon,
    this.onTap,
    this.textStyle,
    this.onChanged,
    this.maxWidthOfPrefix,
  });
  final TextEditingController controller;
  final String? hintText;
  final bool? enabled;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final bool obscureText;
  final bool readOnly;
  final bool textCenter;
  final int maxLines;
  final int? minLines;
  final TextInputAction? textInputAction;
  final EdgeInsetsGeometry? contentPadding;
  final TextInputType? keyboardType;
  final String? title;
  final TextStyle? hintStyle;
  final TextStyle? textStyle;
  final bool useShadow;
  final List<TextInputFormatter>? inputFormatters;
  final void Function()? onTap;
  final void Function(String)? onChanged;
  final double? maxWidthOfPrefix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null) ...[
          Text(
            title ?? '',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14),
          ),
          const Gap(6),
        ],
        Container(
          padding: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            boxShadow: useShadow
                ? [
                    BoxShadow(
                      color: AppColors.black.withOpacity2(0.08),
                      spreadRadius: 0,
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: TextFormField(
            textAlign: textCenter ? TextAlign.center : TextAlign.start,
            controller: controller,
            keyboardType: keyboardType,
            enabled: enabled,
            onTap: onTap,
            inputFormatters: inputFormatters,
            onTapOutside: (event) {
              FocusManager.instance.primaryFocus?.unfocus();
            },
            cursorColor: AppColors.white,
            style: textStyle ?? Theme.of(context).textTheme.bodyLarge,
            readOnly: readOnly,
            validator: validator,
            obscureText: obscureText,
            maxLines: obscureText ? 1 : maxLines,
            minLines: minLines,
            onChanged: onChanged,
            textInputAction: textInputAction,
            decoration: InputDecoration(
              hintText: hintText,
              suffixIcon: suffixIcon,
              prefixIcon: prefixIcon,
              prefixIconConstraints: BoxConstraints(maxWidth: maxWidthOfPrefix ?? double.infinity),
              contentPadding: contentPadding,
              hintStyle: hintStyle,
            ),
          ),
        ),
      ],
    );
  }
}
