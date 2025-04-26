import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:society_management/constants/app_constants.dart';
import 'package:society_management/constants/app_strings.dart';
import 'package:society_management/cubit/refresh_cubit.dart';
import 'package:society_management/enums/enum_file.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/users/repository/i_user_repository.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/app_drop_down_widget.dart';
import 'package:society_management/widget/app_text_form_field.dart';
import 'package:society_management/widget/common_app_bar.dart';
import 'package:society_management/widget/common_button.dart';

class AddUserPage extends StatefulWidget {
  const AddUserPage({super.key, this.userId});
  final String? userId;
  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final mobileNumberController = TextEditingController();
  final villaNoController = TextEditingController();
  final passwordVisbility = ValueNotifier<bool>(true);
  final _formKey = GlobalKey<FormState>();

  final scrollController = ScrollController();

  final isLoading = ValueNotifier<bool>(false);
  final isButtonLoading = ValueNotifier<bool>(false);

  final selectedLine = ValueNotifier<String?>(null);
  final selectedRole = ValueNotifier<String?>(null);

  @override
  void initState() {
    super.initState();
    if (widget.userId != null) {
      getUser();
    }
  }

  Future<void> getUser() async {
    isLoading.value = true;
    final response = await getIt<IUserRepository>().getUser(userId: widget.userId!);
    response.fold(
      (l) {
        isLoading.value = false;
        Utility.toast(message: l.message);
      },
      (r) {
        nameController.text = r.name ?? '';
        emailController.text = r.email ?? '';
        passwordController.text = r.password ?? '';
        mobileNumberController.text = r.mobileNumber ?? '';
        selectedRole.value = r.userRoleViewString;
        selectedLine.value = r.userLineViewString;
        villaNoController.text = r.villNumber ?? '';
        isLoading.value = false;
      },
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    passwordVisbility.dispose();
    _formKey.currentState?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: widget.userId == null ? 'Add New Member' : 'Edit Member',
        showDivider: true,
        onBackTap: () {
          context.pop();
        },
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextFormField(
                  controller: nameController,
                  title: 'Name*',
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(100),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter name';
                    }
                    return null;
                  },
                ),
                const Gap(20),
                AppTextFormField(
                  controller: emailController,
                  title: 'Email*',
                  readOnly: widget.userId != null,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter email';
                    } else if (!Utility.isValidEmail(value.trim())) {
                      return 'Please enter valid email';
                    }
                    return null;
                  },
                ),
                const Gap(20),
                AppTextFormField(
                  controller: villaNoController,
                  title: 'Villa No.*',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(100),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter villa number';
                    }
                    return null;
                  },
                ),
                const Gap(20),
                ValueListenableBuilder<String?>(
                  valueListenable: selectedLine,
                  builder: (context, lineNo, _) {
                    return AppDropDown<String>(
                      title: 'Line No.*',
                      hintText: 'Select',
                      selectedValue: lineNo,
                      onSelect: (valueOfCategory) {
                        selectedLine.value = valueOfCategory;
                      },
                      items: AppStrings.lineList
                          .map(
                            (e) => DropdownMenuItem<String>(
                              value: e,
                              child: Text(
                                e,
                              ),
                            ),
                          )
                          .toList(),
                      validator: (p0) {
                        if (p0 == null || p0.trim().isEmpty) {
                          return 'Please select line';
                        }
                        return null;
                      },
                    );
                  },
                ),
                const Gap(20),
                ValueListenableBuilder<String?>(
                  valueListenable: selectedRole,
                  builder: (context, type, _) {
                    return AppDropDown<String>(
                      title: 'User Role*',
                      hintText: 'Select',
                      selectedValue: type,
                      onSelect: (valueOfCategory) {
                        selectedRole.value = valueOfCategory;
                      },
                      items: AppStrings.roleList
                          .map(
                            (e) => DropdownMenuItem<String>(
                              value: e,
                              child: Text(
                                e,
                              ),
                            ),
                          )
                          .toList(),
                      validator: (p0) {
                        if (p0 == null || p0.trim().isEmpty) {
                          return 'Please select line';
                        }
                        return null;
                      },
                    );
                  },
                ),
                const Gap(20),
                AppTextFormField(
                  controller: mobileNumberController,
                  title: 'Contact number*',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter contact number';
                    }
                    return null;
                  },
                ),
                if (widget.userId == null) ...[
                  const Gap(20),
                  ValueListenableBuilder<bool>(
                    valueListenable: passwordVisbility,
                    builder: (__, visible, _) {
                      return AppTextFormField(
                        title: 'Password*',
                        controller: passwordController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter password';
                          }
                          return null;
                        },
                        obscureText: visible,
                        suffixIcon: IconButton(
                          onPressed: () {
                            passwordVisbility.value = !visible;
                          },
                          icon: Icon(visible ? Icons.visibility_off : Icons.visibility),
                        ),
                      );
                    },
                  ),
                ],
                const Gap(20),
                ValueListenableBuilder<bool>(
                  valueListenable: isButtonLoading,
                  builder: (context, loading, _) {
                    return CommonButton(
                      isLoading: loading,
                      text: widget.userId == null ? 'Create' : 'Update',
                      onTap: () {
                        if (widget.userId == null) {
                          createUser();
                          log("${userRoleViewString}user role string");
                        } else {
                          editUser();
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> createUser() async {
    if (_formKey.currentState!.validate()) {
      isButtonLoading.value = true;
      final response = await getIt<IUserRepository>().addUser(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        mobileNumber: mobileNumberController.text.trim(),
        password: passwordController.text.trim(),
        villNumber: villaNoController.text.trim(),
        line: userLineViewString,
        role: userRoleViewString,
      );
      await response.fold(
        (l) {
          isButtonLoading.value = false;
          Utility.toast(message: l.message);
        },
        (r) async {
          isButtonLoading.value = false;
          Utility.toast(message: 'User created successfully');
          context.read<RefreshCubit>().modifyUser(r, UserAction.add);
          context.pop();
        },
      );
    }
  }

  Future<void> editUser() async {
    if (_formKey.currentState!.validate()) {
      isButtonLoading.value = true;
      final response = await getIt<IUserRepository>().updateCustomer(
        userId: widget.userId!,
        name: nameController.text,
        mobileNumber: mobileNumberController.text,
        line: userLineViewString,
        role: userRoleViewString,
        villNumber: villaNoController.text,
      );
      await response.fold(
        (l) {
          isButtonLoading.value = false;
          Utility.toast(message: l.message);
        },
        (r) async {
          isButtonLoading.value = false;
          Utility.toast(message: 'User updated successfully');
          context.read<RefreshCubit>().modifyUser(r, UserAction.edit);
          context.pop();
        },
      );
    }
  }

  String get userRoleViewString {
    switch (selectedRole.value) {
      case 'Admin':
        return AppConstants.admin;
      case 'Line head':
        return AppConstants.lineLead;
      case 'Line member':
        return AppConstants.lineMember;
      case 'Line head + Member':
        return AppConstants.lineHeadAndMember;
      default:
        return AppConstants.admin;
    }
  }

  String get userLineViewString {
    switch (selectedLine.value) {
      case 'First line':
        return AppConstants.firstLine;
      case 'Second line':
        return AppConstants.secondLine;
      case 'Third line':
        return AppConstants.thirdLine;
      case 'Fourth line':
        return AppConstants.fourthLine;
      case 'Fifth line':
        return AppConstants.fifthLine;
      default:
        return AppConstants.firstLine;
    }
  }
}
