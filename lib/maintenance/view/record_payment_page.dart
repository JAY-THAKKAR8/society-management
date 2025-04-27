import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:society_management/constants/app_constants.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/maintenance/model/maintenance_payment_model.dart';
import 'package:society_management/maintenance/repository/i_maintenance_repository.dart';
import 'package:society_management/maintenance/service/receipt_service.dart';
import 'package:society_management/users/repository/i_user_repository.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/app_drop_down_widget.dart';
import 'package:society_management/widget/app_text_form_field.dart';
import 'package:society_management/widget/common_app_bar.dart';
import 'package:society_management/widget/common_button.dart';

class RecordPaymentPage extends StatefulWidget {
  final String periodId;
  final MaintenancePaymentModel payment;

  const RecordPaymentPage({
    super.key,
    required this.periodId,
    required this.payment,
  });

  @override
  State<RecordPaymentPage> createState() => _RecordPaymentPageState();
}

class _RecordPaymentPageState extends State<RecordPaymentPage> {
  final amountController = TextEditingController();
  final notesController = TextEditingController();
  final receiptController = TextEditingController();
  final checkNumberController = TextEditingController();
  final transactionIdController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  DateTime paymentDate = DateTime.now();
  String? selectedPaymentMethod;
  final isLoading = ValueNotifier<bool>(false);
  String? currentUserId;
  String? currentUserName;

  final List<String> paymentMethods = [
    'Cash',
    'UPI',
    'Bank Transfer',
    'Check',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    try {
      final userRepository = getIt<IUserRepository>();
      final result = await userRepository.getCurrentUser();

      result.fold(
        (failure) {
          Utility.toast(message: failure.message);
        },
        (user) {
          setState(() {
            currentUserId = user.id;
            currentUserName = user.name;
          });
        },
      );
    } catch (e) {
      Utility.toast(message: 'Error getting current user: $e');
    }
  }

  void _initializeData() {
    // Pre-fill with existing data if payment is partially paid
    if (widget.payment.status == PaymentStatus.partiallyPaid || widget.payment.status == PaymentStatus.paid) {
      amountController.text = widget.payment.amountPaid.toString();

      if (widget.payment.paymentDate != null) {
        paymentDate = DateTime.parse(widget.payment.paymentDate!);
      }

      selectedPaymentMethod = widget.payment.paymentMethod;
      notesController.text = widget.payment.notes ?? '';
      receiptController.text = widget.payment.receiptNumber ?? '';
      checkNumberController.text = widget.payment.checkNumber ?? '';
      transactionIdController.text = widget.payment.transactionId ?? '';
    } else {
      // For new payments, set the full amount
      amountController.text = widget.payment.amount?.toString() ?? '0';

      // Generate a receipt number for new payments
      _generateReceiptNumber();
    }
  }

  Future<void> _generateReceiptNumber() async {
    try {
      // Only auto-generate receipt number for new payments
      if (widget.payment.status == PaymentStatus.pending) {
        final receiptNumber = await ReceiptService.generateReceiptNumber();
        setState(() {
          receiptController.text = receiptNumber;
        });
      }
    } catch (e) {
      Utility.toast(message: 'Error generating receipt number: $e');
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    notesController.dispose();
    receiptController.dispose();
    checkNumberController.dispose();
    transactionIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Record Payment',
        showDivider: true,
        onBackTap: () {
          context.pop();
        },
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserInfoCard(),
              const Gap(20),
              AppTextFormField(
                controller: amountController,
                title: 'Payment Amount (₹)*',
                hintText: 'Enter amount paid',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter amount';
                  }
                  try {
                    final amount = double.parse(value);
                    if (amount <= 0) {
                      return 'Amount must be greater than 0';
                    }
                    if (widget.payment.amount != null && amount > widget.payment.amount!) {
                      return 'Amount cannot exceed ${widget.payment.amount}';
                    }
                  } catch (e) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const Gap(20),
              _buildDatePicker(
                context,
                'Payment Date*',
                paymentDate,
                (date) {
                  setState(() {
                    paymentDate = date;
                  });
                },
              ),
              const Gap(20),
              ValueListenableBuilder<String?>(
                valueListenable: ValueNotifier<String?>(selectedPaymentMethod),
                builder: (context, method, _) {
                  return AppDropDown<String>(
                    title: 'Payment Method*',
                    hintText: 'Select payment method',
                    selectedValue: method,
                    onSelect: (value) {
                      setState(() {
                        selectedPaymentMethod = value;
                      });
                    },
                    items: paymentMethods
                        .map(
                          (e) => DropdownMenuItem<String>(
                            value: e,
                            child: Text(e),
                          ),
                        )
                        .toList(),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please select payment method';
                      }
                      return null;
                    },
                  );
                },
              ),
              const Gap(20),
              // Conditional fields based on payment method
              if (selectedPaymentMethod == 'Check') ...[
                AppTextFormField(
                  controller: checkNumberController,
                  title: 'Check Number*',
                  hintText: 'Enter check number',
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(50),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter check number';
                    }
                    return null;
                  },
                ),
                const Gap(20),
              ],
              if (selectedPaymentMethod == 'UPI') ...[
                AppTextFormField(
                  controller: transactionIdController,
                  title: 'Transaction ID*',
                  hintText: 'Enter UPI transaction ID',
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(50),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter transaction ID';
                    }
                    return null;
                  },
                ),
                const Gap(20),
              ],
              if (selectedPaymentMethod == 'Bank Transfer') ...[
                AppTextFormField(
                  controller: transactionIdController,
                  title: 'Transaction Reference*',
                  hintText: 'Enter bank transaction reference',
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(50),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter transaction reference';
                    }
                    return null;
                  },
                ),
                const Gap(20),
              ],
              AppTextFormField(
                controller: receiptController,
                title: 'Receipt Number*',
                hintText: 'Receipt number will be auto-generated',
                readOnly: true,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(50),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Receipt number is required';
                  }
                  return null;
                },
              ),
              const Gap(20),
              AppTextFormField(
                controller: notesController,
                title: 'Notes',
                hintText: 'Optional notes',
                maxLines: 3,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(500),
                ],
              ),
              const Gap(30),
              ValueListenableBuilder<bool>(
                valueListenable: isLoading,
                builder: (context, loading, _) {
                  return CommonButton(
                    isLoading: loading,
                    text: 'Record Payment',
                    onTap: _submitPayment,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Member Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Name: ${widget.payment.userName ?? 'Unknown'}',
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Villa: ${widget.payment.userVillaNumber ?? 'N/A'}',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Line: ${_getLineText(widget.payment.userLineNumber)}',
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total Due: ₹${widget.payment.amount?.toStringAsFixed(2) ?? '0.00'}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.payment.amountPaid > 0) ...[
              const Divider(),
              Text(
                'Already Paid: ₹${widget.payment.amountPaid.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.green),
              ),
              if (widget.payment.amount != null)
                Text(
                  'Remaining: ₹${(widget.payment.amount! - widget.payment.amountPaid).toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.red),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker(
    BuildContext context,
    String label,
    DateTime selectedDate,
    Function(DateTime) onDateChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime.now().subtract(const Duration(days: 30)),
              lastDate: DateTime.now(),
            );
            if (pickedDate != null) {
              onDateChanged(pickedDate);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMM d, yyyy').format(selectedDate),
                  style: const TextStyle(fontSize: 16),
                ),
                const Icon(Icons.calendar_today),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitPayment() async {
    if (_formKey.currentState!.validate()) {
      if (currentUserId == null || currentUserName == null) {
        Utility.toast(message: 'Error: Could not identify the collector');
        return;
      }

      isLoading.value = true;

      try {
        final maintenanceRepository = getIt<IMaintenanceRepository>();
        final amountPaid = double.parse(amountController.text.trim());

        // Determine payment status
        PaymentStatus status;
        if (widget.payment.amount != null) {
          if (amountPaid >= widget.payment.amount!) {
            status = PaymentStatus.paid;
          } else {
            status = PaymentStatus.partiallyPaid;
          }
        } else {
          status = PaymentStatus.paid;
        }

        // Get payment method specific details
        String? checkNumber;
        String? transactionId;

        if (selectedPaymentMethod == 'Check') {
          checkNumber = checkNumberController.text.trim();
        } else if (selectedPaymentMethod == 'UPI' || selectedPaymentMethod == 'Bank Transfer') {
          transactionId = transactionIdController.text.trim();
        }

        final result = await maintenanceRepository.recordPayment(
          periodId: widget.periodId,
          userId: widget.payment.userId!,
          userName: widget.payment.userName!,
          userVillaNumber: widget.payment.userVillaNumber!,
          userLineNumber: widget.payment.userLineNumber!,
          collectedBy: currentUserId!,
          collectorName: currentUserName!,
          amount: widget.payment.amount ?? 0,
          amountPaid: amountPaid,
          paymentDate: paymentDate,
          paymentMethod: selectedPaymentMethod!,
          status: status,
          notes: notesController.text.trim(),
          receiptNumber: receiptController.text.trim(),
          checkNumber: checkNumber,
          transactionId: transactionId,
        );

        result.fold(
          (failure) {
            isLoading.value = false;
            Utility.toast(message: failure.message);
          },
          (payment) async {
            // Generate and share receipt
            try {
              // Get period details
              final periodResult = await maintenanceRepository.getMaintenancePeriodById(periodId: widget.periodId);

              periodResult.fold(
                (failure) {
                  Utility.toast(
                      message:
                          'Payment recorded successfully, but error getting period details for receipt: ${failure.message}');
                },
                (period) async {
                  try {
                    // Generate PDF receipt
                    final receiptFile = await ReceiptService.generateReceiptPDF(
                      payment: payment,
                      period: period,
                      paymentMethod: selectedPaymentMethod!,
                      checkNumber: checkNumber,
                      upiTransactionId: transactionId,
                    );

                    // Share receipt with user
                    await ReceiptService.shareReceipt(receiptFile);
                  } catch (e) {
                    Utility.toast(message: 'Payment recorded successfully, but error generating receipt: $e');
                  }
                },
              );
            } catch (e) {
              Utility.toast(message: 'Payment recorded successfully, but error with receipt: $e');
            }

            isLoading.value = false;
            Utility.toast(message: 'Payment recorded successfully');
            if (mounted) {
              context.pop();
            }
          },
        );
      } catch (e) {
        isLoading.value = false;
        Utility.toast(message: 'Error recording payment: $e');
      }
    }
  }

  String _getLineText(String? lineNumber) {
    switch (lineNumber) {
      case AppConstants.firstLine:
        return 'Line 1';
      case AppConstants.secondLine:
        return 'Line 2';
      case AppConstants.thirdLine:
        return 'Line 3';
      case AppConstants.fourthLine:
        return 'Line 4';
      case AppConstants.fifthLine:
        return 'Line 5';
      default:
        return 'Unknown';
    }
  }
}
