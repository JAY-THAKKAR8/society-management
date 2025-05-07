import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:society_management/constants/app_constants.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/maintenance/model/maintenance_payment_model.dart';
import 'package:society_management/maintenance/repository/i_maintenance_repository.dart';
import 'package:society_management/maintenance/service/late_fee_calculator.dart';
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

  // Late fee related variables
  double lateFeeAmountPaid = 0.0;
  final bool _hasUpdatedLateFee = false;
  final double _recalculatedLateFeeAmount = 0.0;
  final int _currentDaysLate = 0;

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
    // Initialize with existing data
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
      // For new payments, set the amount
      double totalAmount = widget.payment.amount ?? 0.0;
      amountController.text = totalAmount.toString();

      // Generate a receipt number for new payments
      _generateReceiptNumber();
    }

    // Initialize late fee data
    if (widget.payment.hasLateFee) {
      lateFeeAmountPaid = widget.payment.lateFeeAmount;
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
              // Payment amount field
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

                    // Check if amount exceeds the total due
                    final totalExpectedAmount = widget.payment.amount ?? 0;
                    if (amount > totalExpectedAmount) {
                      return 'Amount cannot exceed ₹${totalExpectedAmount.toStringAsFixed(2)}';
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
                // Make sure receipt number is clearly visible
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
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
              if (widget.payment.amount != null) ...[
                Text(
                  'Total Due: ₹${(widget.payment.amount! - widget.payment.amountPaid).toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
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
        final totalAmountPaid = double.parse(amountController.text.trim());

        // All payment goes to maintenance
        double maintenanceAmountPaid = totalAmountPaid;

        // Determine payment status
        PaymentStatus status;
        if (widget.payment.amount != null) {
          if (maintenanceAmountPaid >= widget.payment.amount!) {
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

        // Add note about late fee if applicable
        String notes = notesController.text.trim();
        if (widget.payment.hasLateFee) {
          final lateFeePaidText = "Late fee paid: ₹${lateFeeAmountPaid.toStringAsFixed(2)}";
          notes = notes.isEmpty ? lateFeePaidText : "$notes\n$lateFeePaidText";
        }

        // Record the payment (only the maintenance portion)
        final result = await maintenanceRepository.recordPayment(
          periodId: widget.periodId,
          userId: widget.payment.userId!,
          userName: widget.payment.userName!,
          userVillaNumber: widget.payment.userVillaNumber!,
          userLineNumber: widget.payment.userLineNumber!,
          collectedBy: currentUserId!,
          collectorName: currentUserName!,
          amount: widget.payment.amount ?? 0,
          amountPaid: maintenanceAmountPaid,
          paymentDate: paymentDate,
          paymentMethod: selectedPaymentMethod!,
          status: status,
          notes: notes,
          receiptNumber: receiptController.text.trim(),
          checkNumber: checkNumber,
          transactionId: transactionId,
        );

        // If there's a late fee payment, record it separately
        if (widget.payment.hasLateFee && lateFeeAmountPaid > 0) {
          try {
            // If the late fee has been recalculated, update the payment record with the new late fee amount
            if (_hasUpdatedLateFee && widget.payment.id != null) {
              try {
                // Update the payment record with the new late fee amount
                await FirebaseFirestore.instance.collection('maintenance_payments').doc(widget.payment.id).update({
                  'late_fee_amount': _recalculatedLateFeeAmount,
                  'days_late': _currentDaysLate,
                  'updated_at': Timestamp.now(),
                });

                debugPrint(
                    'Updated payment record with new late fee: $_recalculatedLateFeeAmount, days late: $_currentDaysLate');
              } catch (e) {
                debugPrint('Error updating payment record with new late fee: $e');
                // Continue with the payment process even if the update fails
              }
            }

            // Use the LateFeeCalculator to record the payment
            await LateFeeCalculator.recordLateFeePayment(
              userId: widget.payment.userId!,
              userName: widget.payment.userName!,
              amount: lateFeeAmountPaid,
              paymentDate: paymentDate,
              paymentMethod: selectedPaymentMethod!,
              receiptNumber: receiptController.text.trim(),
            );
          } catch (e) {
            debugPrint('Error recording late fee payment: $e');
            // Continue with the payment process even if late fee recording fails
          }
        }

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
    if (lineNumber == null) return 'Unknown';

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
        // Handle case where lineNumber might contain underscores
        if (lineNumber.contains('_')) {
          final parts = lineNumber.split('_');
          if (parts.length > 1) {
            // Convert FIRST_LINE to First Line
            return parts
                .map((part) => part.isNotEmpty ? '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}' : '')
                .join(' ');
          }
        }
        return lineNumber;
    }
  }
}
