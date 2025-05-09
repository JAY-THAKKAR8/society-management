import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:society_management/theme/theme_utils.dart';

class AppDropDown<T> extends StatelessWidget {
  const AppDropDown(
      {super.key,
      required this.onSelect,
      this.validator,
      this.selectedValue,
      this.hintText,
      this.number,
      this.focusNode,
      required this.items,
      this.title});
  final Function(T? value) onSelect;
  final String? Function(T?)? validator;

  final T? selectedValue;
  final String? hintText;
  final int? number;
  final FocusNode? focusNode;
  final List<DropdownMenuItem<T>>? items;
  final String? title;

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
        DropdownButtonFormField<T>(
          borderRadius: BorderRadius.circular(15),
          value: selectedValue,
          validator: validator,
          focusNode: focusNode,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          onChanged: (v) {
            onSelect(v);
          },
          style: Theme.of(context).textTheme.labelLarge,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            hintText: hintText,
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ThemeUtils.getTextColor(context, secondary: true),
                ),
            fillColor: ThemeUtils.getDropdownColor(context),
            filled: true,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: ThemeUtils.getPrimaryColor(context)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: ThemeUtils.getBorderColor(context)),
            ),
          ),
          items: items,
        ),
      ],
    );
  }
}
