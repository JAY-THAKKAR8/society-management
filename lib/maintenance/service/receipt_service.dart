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

    // Payment method details
    String paymentDetails = 'Method: $paymentMethod';
    if (checkNumber != null && checkNumber.isNotEmpty) {
      paymentDetails += '\nCheck Number: $checkNumber';
    }
    if (upiTransactionId != null && upiTransactionId.isNotEmpty) {
      paymentDetails += '\nTransaction ID: $upiTransactionId';
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
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
                            fontSize: 20,
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          'Maintenance Receipt',
                          style: pw.TextStyle(
                            font: ttf,
                            fontSize: 14,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.blue),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                      ),
                      child: pw.Text(
                        'Receipt #: ${payment.receiptNumber}',
                        style: pw.TextStyle(
                          font: ttfBold,
                          fontSize: 12,
                          color: PdfColors.blue,
                        ),
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 20),

                // Divider
                pw.Divider(color: PdfColors.grey300),

                pw.SizedBox(height: 20),

                // Payment details
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Left column
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Paid By:',
                            style: pw.TextStyle(
                              font: ttfBold,
                              fontSize: 12,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            payment.userName ?? 'Unknown',
                            style: pw.TextStyle(
                              font: ttfBold,
                              fontSize: 14,
                            ),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            'Villa: ${payment.userVillaNumber ?? 'N/A'}',
                            style: pw.TextStyle(
                              font: ttf,
                              fontSize: 12,
                            ),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            'Line: ${payment.userLineNumber ?? 'N/A'}',
                            style: pw.TextStyle(
                              font: ttf,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Right column
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Payment Details:',
                            style: pw.TextStyle(
                              font: ttfBold,
                              fontSize: 12,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Text(
                            'Date: $paymentDate',
                            style: pw.TextStyle(
                              font: ttf,
                              fontSize: 12,
                            ),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            'Period: $periodName',
                            style: pw.TextStyle(
                              font: ttf,
                              fontSize: 12,
                            ),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            paymentDetails,
                            style: pw.TextStyle(
                              font: ttf,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 30),

                // Payment amount
                pw.Container(
                  padding: const pw.EdgeInsets.all(15),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(5)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Amount Paid:',
                        style: pw.TextStyle(
                          font: ttfBold,
                          fontSize: 14,
                        ),
                      ),
                      pw.Text(
                        '₹${payment.amountPaid.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          font: ttfBold,
                          fontSize: 16,
                          color: PdfColors.blue900,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 20),

                // Notes
                if (payment.notes != null && payment.notes!.isNotEmpty) ...[
                  pw.Text(
                    'Notes:',
                    style: pw.TextStyle(
                      font: ttfBold,
                      fontSize: 12,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.all(pw.Radius.circular(5)),
                    ),
                    child: pw.Text(
                      payment.notes!,
                      style: pw.TextStyle(
                        font: ttf,
                        fontSize: 12,
                        color: PdfColors.grey800,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 20),
                ],

                // Collector details
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Collected By:',
                          style: pw.TextStyle(
                            font: ttfBold,
                            fontSize: 12,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          payment.collectorName ?? 'Unknown',
                          style: pw.TextStyle(
                            font: ttf,
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
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Container(
                          height: 40,
                          width: 120,
                          child: pw.Center(
                            child: pw.Text(
                              'Signature',
                              style: pw.TextStyle(
                                font: ttf,
                                fontSize: 10,
                                color: PdfColors.grey500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                pw.Spacer(),

                // Footer
                pw.Divider(color: PdfColors.grey300),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text(
                    'Thank you for your payment!',
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 12,
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Center(
                  child: pw.Text(
                    '$societyName - Generated on ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}',
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 10,
                      color: PdfColors.grey500,
                    ),
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
