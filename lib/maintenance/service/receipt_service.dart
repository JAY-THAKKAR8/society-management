import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:society_management/maintenance/model/maintenance_payment_model.dart';
import 'package:society_management/maintenance/model/maintenance_period_model.dart';
import 'package:society_management/utility/utility.dart';

class ReceiptService {
  static const String societyName = "Krishna Darshan Villa";

  // Generate a unique receipt number
  static Future<String> generateReceiptNumber() async {
    try {
      // Get the current count of receipts from Firestore
      final counterDoc = await FirebaseFirestore.instance.collection('counters').doc('receipts').get();

      int currentCount = 1; // Start from 1 if no counter exists

      if (counterDoc.exists) {
        currentCount = (counterDoc.data()?['count'] as num?)?.toInt() ?? 1;
      }

      // Format: KDVR-YYYYMMDD-XXXX (XXXX is sequential number)
      final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
      final receiptNumber = 'KDVR-$dateStr-${currentCount.toString().padLeft(4, '0')}';

      // Update the counter
      await FirebaseFirestore.instance.collection('counters').doc('receipts').set({
        'count': currentCount + 1,
        'last_updated': Timestamp.now(),
      });

      return receiptNumber;
    } catch (e) {
      Utility.toast(message: 'Error generating receipt number: $e');
      // Fallback to timestamp-based receipt number if counter fails
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return 'KDVR-$timestamp';
    }
  }

  // Generate PDF receipt
  static Future<File> generateReceiptPDF({
    required MaintenancePaymentModel payment,
    required MaintenancePeriodModel period,
    required String paymentMethod,
    String? checkNumber,
    String? upiTransactionId,
  }) async {
    final pdf = pw.Document();

    // Load font
    final fontData = await rootBundle.load("fonts/SFProDisplay-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);

    final fontDataBold = await rootBundle.load("fonts/SFProDisplay-Bold.ttf");
    final ttfBold = pw.Font.ttf(fontDataBold);

    // Format dates
    final paymentDate = payment.paymentDate != null && payment.paymentDate!.isNotEmpty
        ? DateFormat('dd MMM yyyy').format(DateTime.parse(payment.paymentDate!))
        : 'N/A';

    final periodName = period.name ?? 'Unnamed Period';
    final periodStartDate = period.startDate != null && period.startDate!.isNotEmpty
        ? DateFormat('dd MMM yyyy').format(DateTime.parse(period.startDate!))
        : 'N/A';
    final periodEndDate = period.endDate != null && period.endDate!.isNotEmpty
        ? DateFormat('dd MMM yyyy').format(DateTime.parse(period.endDate!))
        : 'N/A';

    // Define theme colors to match app theme
    const primaryColor = PdfColor(0.22, 0.71, 1); // #38b6ff - AppColors.buttonColor
    const primaryLight = PdfColor(0.22, 0.71, 1, 0.2);
    const textColor = PdfColors.white;
    const bgColor = PdfColor(0.12, 0.13, 0.14); // #1F2123 - AppColors.lightBlack

    // Payment method details
    String paymentMethodText = paymentMethod;
    String paymentDetailsText = '';

    if (checkNumber != null && checkNumber.isNotEmpty) {
      paymentDetailsText = 'Check Number: $checkNumber';
    } else if (upiTransactionId != null && upiTransactionId.isNotEmpty) {
      paymentDetailsText = 'Transaction ID: $upiTransactionId';
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            color: PdfColors.white,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header with background color
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(20),
                  decoration: const pw.BoxDecoration(
                    color: bgColor,
                    borderRadius: pw.BorderRadius.only(
                      bottomLeft: pw.Radius.circular(10),
                      bottomRight: pw.Radius.circular(10),
                    ),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                societyName,
                                style: pw.TextStyle(
                                  font: ttfBold,
                                  fontSize: 24,
                                  color: textColor,
                                ),
                              ),
                              pw.SizedBox(height: 5),
                              pw.Text(
                                'MAINTENANCE RECEIPT',
                                style: pw.TextStyle(
                                  font: ttfBold,
                                  fontSize: 16,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                            decoration: const pw.BoxDecoration(
                              color: primaryColor,
                              borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
                            ),
                            child: pw.Text(
                              'RECEIPT #: ${payment.receiptNumber}',
                              style: pw.TextStyle(
                                font: ttfBold,
                                fontSize: 14,
                                color: PdfColors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 15),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Date: $paymentDate',
                            style: pw.TextStyle(
                              font: ttf,
                              fontSize: 12,
                              color: textColor,
                            ),
                          ),
                          pw.Text(
                            'Period: $periodName',
                            style: pw.TextStyle(
                              font: ttf,
                              fontSize: 12,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 20),

                // Main content
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 20),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // User and Payment Information in a styled table
                      pw.Container(
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: primaryColor, width: 1.5),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                        ),
                        child: pw.Column(
                          children: [
                            // Table Header
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                              decoration: const pw.BoxDecoration(
                                color: primaryColor,
                                borderRadius: pw.BorderRadius.only(
                                  topLeft: pw.Radius.circular(7),
                                  topRight: pw.Radius.circular(7),
                                ),
                              ),
                              child: pw.Row(
                                children: [
                                  pw.Expanded(
                                    flex: 3,
                                    child: pw.Text(
                                      'PAYMENT DETAILS',
                                      style: pw.TextStyle(
                                        font: ttfBold,
                                        fontSize: 14,
                                        color: PdfColors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Table Content
                            pw.Table(
                              border: const pw.TableBorder(
                                horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                              ),
                              columnWidths: {
                                0: const pw.FlexColumnWidth(2),
                                1: const pw.FlexColumnWidth(3),
                              },
                              children: [
                                // Row 1
                                pw.TableRow(
                                  decoration: const pw.BoxDecoration(
                                    color: PdfColors.white,
                                  ),
                                  children: [
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.all(10),
                                      child: pw.Text(
                                        'Paid By',
                                        style: pw.TextStyle(
                                          font: ttfBold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.all(10),
                                      child: pw.Text(
                                        payment.userName ?? 'Unknown',
                                        style: pw.TextStyle(
                                          font: ttf,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // Row 2
                                pw.TableRow(
                                  decoration: const pw.BoxDecoration(
                                    color: primaryLight,
                                  ),
                                  children: [
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.all(10),
                                      child: pw.Text(
                                        'Villa Number',
                                        style: pw.TextStyle(
                                          font: ttfBold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.all(10),
                                      child: pw.Text(
                                        payment.userVillaNumber ?? 'N/A',
                                        style: pw.TextStyle(
                                          font: ttf,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // Row 3
                                pw.TableRow(
                                  decoration: const pw.BoxDecoration(
                                    color: PdfColors.white,
                                  ),
                                  children: [
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.all(10),
                                      child: pw.Text(
                                        'Line Number',
                                        style: pw.TextStyle(
                                          font: ttfBold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.all(10),
                                      child: pw.Text(
                                        payment.userLineNumber ?? 'N/A',
                                        style: pw.TextStyle(
                                          font: ttf,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // Row 4
                                pw.TableRow(
                                  decoration: const pw.BoxDecoration(
                                    color: primaryLight,
                                  ),
                                  children: [
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.all(10),
                                      child: pw.Text(
                                        'Period Duration',
                                        style: pw.TextStyle(
                                          font: ttfBold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.all(10),
                                      child: pw.Text(
                                        '$periodStartDate to $periodEndDate',
                                        style: pw.TextStyle(
                                          font: ttf,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // Row 5
                                pw.TableRow(
                                  decoration: const pw.BoxDecoration(
                                    color: PdfColors.white,
                                  ),
                                  children: [
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.all(10),
                                      child: pw.Text(
                                        'Payment Method',
                                        style: pw.TextStyle(
                                          font: ttfBold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.all(10),
                                      child: pw.Text(
                                        paymentMethodText,
                                        style: pw.TextStyle(
                                          font: ttf,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // Row 6 (conditional)
                                if (paymentDetailsText.isNotEmpty)
                                  pw.TableRow(
                                    decoration: const pw.BoxDecoration(
                                      color: primaryLight,
                                    ),
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(10),
                                        child: pw.Text(
                                          paymentMethod == 'Check' ? 'Check Number' : 'Transaction ID',
                                          style: pw.TextStyle(
                                            font: ttfBold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.all(10),
                                        child: pw.Text(
                                          paymentDetailsText.replaceAll(RegExp(r'.*: '), ''),
                                          style: pw.TextStyle(
                                            font: ttf,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      pw.SizedBox(height: 20),

                      // Amount Paid Section
                      pw.Container(
                        padding: const pw.EdgeInsets.all(15),
                        decoration: pw.BoxDecoration(
                          color: bgColor,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                          border: pw.Border.all(color: primaryColor, width: 1.5),
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'AMOUNT PAID',
                              style: pw.TextStyle(
                                font: ttfBold,
                                fontSize: 16,
                                color: textColor,
                              ),
                            ),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                              decoration: const pw.BoxDecoration(
                                color: primaryColor,
                                borderRadius: pw.BorderRadius.all(pw.Radius.circular(5)),
                              ),
                              child: pw.Text(
                                '₹${payment.amountPaid.toStringAsFixed(2)}',
                                style: pw.TextStyle(
                                  font: ttfBold,
                                  fontSize: 18,
                                  color: PdfColors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      pw.SizedBox(height: 20),

                      // Notes Section (if any)
                      if (payment.notes != null && payment.notes!.isNotEmpty) ...[
                        pw.Container(
                          width: double.infinity,
                          padding: const pw.EdgeInsets.all(15),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey400),
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'NOTES',
                                style: pw.TextStyle(
                                  font: ttfBold,
                                  fontSize: 14,
                                ),
                              ),
                              pw.SizedBox(height: 8),
                              pw.Text(
                                payment.notes!,
                                style: pw.TextStyle(
                                  font: ttf,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 20),
                      ],

                      // Collector and Signature Section
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Container(
                            padding: const pw.EdgeInsets.all(15),
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(color: PdfColors.grey400),
                              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                            ),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'COLLECTED BY',
                                  style: pw.TextStyle(
                                    font: ttfBold,
                                    fontSize: 14,
                                  ),
                                ),
                                pw.SizedBox(height: 8),
                                pw.Text(
                                  payment.collectorName ?? 'Unknown',
                                  style: pw.TextStyle(
                                    font: ttfBold,
                                    fontSize: 12,
                                  ),
                                ),
                                pw.SizedBox(height: 3),
                                pw.Text(
                                  'Line Head',
                                  style: pw.TextStyle(
                                    font: ttf,
                                    fontSize: 10,
                                    color: PdfColors.grey600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          pw.Container(
                            width: 150,
                            height: 70,
                            padding: const pw.EdgeInsets.all(10),
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(color: PdfColors.grey400),
                              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                            ),
                            child: pw.Column(
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              children: [
                                pw.Text(
                                  'SIGNATURE',
                                  style: pw.TextStyle(
                                    font: ttfBold,
                                    fontSize: 12,
                                  ),
                                ),
                                pw.SizedBox(height: 20),
                                pw.Divider(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                pw.Spacer(),

                // Footer
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  decoration: const pw.BoxDecoration(
                    color: bgColor,
                    borderRadius: pw.BorderRadius.only(
                      topLeft: pw.Radius.circular(10),
                      topRight: pw.Radius.circular(10),
                    ),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'Thank you for your payment!',
                        style: pw.TextStyle(
                          font: ttfBold,
                          fontSize: 14,
                          color: textColor,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        '$societyName - Generated on ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}',
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 10,
                          color: PdfColors.grey400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // Save the PDF
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/receipt_${payment.receiptNumber}.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  // Share receipt with user
  static Future<void> shareReceipt(File receiptFile) async {
    try {
      await Share.shareXFiles(
        [XFile(receiptFile.path)],
        subject: 'Maintenance Payment Receipt',
        text: 'Please find attached your maintenance payment receipt from $societyName.',
      );
    } catch (e) {
      Utility.toast(message: 'Error sharing receipt: $e');
    }
  }
}
