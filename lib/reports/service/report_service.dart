import 'dart:io';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:society_management/maintenance/model/maintenance_payment_model.dart';
import 'package:society_management/maintenance/model/maintenance_period_model.dart';
import 'package:society_management/users/model/user_model.dart';
import 'package:society_management/utility/utility.dart';

class ReportService {
  static const String societyName = 'KDV Society Management';
  static const PdfColor primaryColor = PdfColor.fromInt(0xFF2A5298);
  static const PdfColor secondaryColor = PdfColor.fromInt(0xFF10B981);
  static const PdfColor bgColor = PdfColor.fromInt(0xFFF8FAFC);

  /// Generate Payment Report PDF
  static Future<File> generatePaymentReportPDF({
    required List<MaintenancePaymentModel> payments,
    required List<MaintenancePeriodModel> periods,
    required String lineNumber,
    required String reportType, // 'all', 'paid', 'pending', 'overdue'
    String? startDate,
    String? endDate,
    String? lineHeadName,
  }) async {
    final pdf = pw.Document();

    // Load fonts
    final fontData = await rootBundle.load("fonts/SFProDisplay-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);
    final fontDataBold = await rootBundle.load("fonts/SFProDisplay-Bold.ttf");
    final ttfBold = pw.Font.ttf(fontDataBold);

    // Filter payments based on report type
    List<MaintenancePaymentModel> filteredPayments = filterPaymentsByType(payments, reportType);

    // Calculate totals
    final totalAmount = filteredPayments.fold<double>(0, (sum, payment) => sum + (payment.amount ?? 0));
    final totalPaid = filteredPayments.fold<double>(0, (sum, payment) => sum + payment.amountPaid);
    final totalPending = totalAmount - totalPaid;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return [
            // Header
            _buildReportHeader(ttfBold, ttf, 'Payment Report', lineNumber, lineHeadName),
            pw.SizedBox(height: 20),

            // Report Info
            _buildReportInfo(ttf, ttfBold, reportType, startDate, endDate, filteredPayments.length),
            pw.SizedBox(height: 20),

            // Summary Cards
            _buildPaymentSummary(ttf, ttfBold, totalAmount, totalPaid, totalPending),
            pw.SizedBox(height: 20),

            // Society Analytics
            _buildSocietyAnalytics(ttf, ttfBold, filteredPayments, periods),
            pw.SizedBox(height: 20),

            // Payments Table
            _buildPaymentsTable(ttf, ttfBold, filteredPayments, periods),
          ];
        },
      ),
    );

    // Save PDF
    final output = await getTemporaryDirectory();
    final fileName = 'payment_report_${lineNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  /// Generate Society Overview Report PDF (Admin Only)
  static Future<File> generateSocietyOverviewPDF({
    required Map<String, List<MaintenancePaymentModel>> linePayments,
    required Map<String, List<UserModel>> lineMembers,
    required List<MaintenancePeriodModel> periods,
    String? adminName,
  }) async {
    final pdf = pw.Document();

    // Load fonts
    final fontData = await rootBundle.load("fonts/SFProDisplay-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);
    final fontDataBold = await rootBundle.load("fonts/SFProDisplay-Bold.ttf");
    final ttfBold = pw.Font.ttf(fontDataBold);

    // Calculate society-wide totals
    double totalSocietyAmount = 0;
    double totalSocietyPaid = 0;
    int totalSocietyMembers = 0;

    linePayments.forEach((line, payments) {
      totalSocietyAmount += payments.fold<double>(0, (sum, p) => sum + (p.amount ?? 0));
      totalSocietyPaid += payments.fold<double>(0, (sum, p) => sum + p.amountPaid);
    });

    lineMembers.forEach((line, members) {
      totalSocietyMembers += members.length;
    });

    final totalSocietyPending = totalSocietyAmount - totalSocietyPaid;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return [
            // Header
            _buildReportHeader(ttfBold, ttf, 'Society Overview Report', 'ALL LINES', adminName),
            pw.SizedBox(height: 20),

            // Society Summary
            _buildSocietySummary(
                ttf, ttfBold, totalSocietyAmount, totalSocietyPaid, totalSocietyPending, totalSocietyMembers),
            pw.SizedBox(height: 20),

            // Line-wise Performance
            _buildLinePerformanceTable(ttf, ttfBold, linePayments, lineMembers),
          ];
        },
      ),
    );

    // Save PDF
    final output = await getTemporaryDirectory();
    final fileName = 'society_overview_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  /// Generate Member Report PDF
  static Future<File> generateMemberReportPDF({
    required List<UserModel> members,
    required List<MaintenancePaymentModel> payments,
    required String lineNumber,
    required String reportType, // 'all', 'active', 'inactive'
  }) async {
    final pdf = pw.Document();

    // Load fonts
    final fontData = await rootBundle.load("fonts/SFProDisplay-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);
    final fontDataBold = await rootBundle.load("fonts/SFProDisplay-Bold.ttf");
    final ttfBold = pw.Font.ttf(fontDataBold);

    // Filter members based on report type
    List<UserModel> filteredMembers = _filterMembersByType(members, reportType);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return [
            // Header
            _buildReportHeader(ttfBold, ttf, 'Member Report', lineNumber, null),
            pw.SizedBox(height: 20),

            // Report Info
            _buildMemberReportInfo(ttf, ttfBold, reportType, filteredMembers.length),
            pw.SizedBox(height: 20),

            // Members Table
            _buildMembersTable(ttf, ttfBold, filteredMembers, payments),
          ];
        },
      ),
    );

    // Save PDF
    final output = await getTemporaryDirectory();
    final fileName = 'member_report_${lineNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  /// Share report file
  static Future<void> shareReport(File reportFile, String reportType) async {
    try {
      await Share.shareXFiles(
        [XFile(reportFile.path)],
        subject: '$reportType Report - $societyName',
        text: 'Please find attached the $reportType report from $societyName.',
      );
    } catch (e) {
      Utility.toast(message: 'Error sharing report: $e');
    }
  }

  // Helper methods
  static List<MaintenancePaymentModel> filterPaymentsByType(
    List<MaintenancePaymentModel> payments,
    String reportType,
  ) {
    switch (reportType.toLowerCase()) {
      case 'paid':
        return payments.where((p) => p.status == PaymentStatus.paid).toList();
      case 'pending':
        return payments
            .where((p) =>
                p.status == PaymentStatus.pending ||
                p.status == PaymentStatus.overdue ||
                p.status == PaymentStatus.partiallyPaid)
            .toList();
      default:
        return payments;
    }
  }

  static List<UserModel> _filterMembersByType(
    List<UserModel> members,
    String reportType,
  ) {
    switch (reportType.toLowerCase()) {
      case 'active':
        return members.where((m) => m.isVillaOpen == 'yes').toList();
      case 'inactive':
        return members.where((m) => m.isVillaOpen == 'no').toList();
      default:
        return members;
    }
  }

  static pw.Widget _buildReportHeader(
    pw.Font boldFont,
    pw.Font regularFont,
    String reportTitle,
    String lineNumber,
    String? lineHeadName,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(20),
      decoration: const pw.BoxDecoration(
        color: primaryColor,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            societyName,
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 24,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            reportTitle,
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 20,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Line: ${lineNumber.toUpperCase().replaceAll('_', ' ')}',
            style: pw.TextStyle(
              font: regularFont,
              fontSize: 14,
              color: PdfColors.white,
            ),
          ),
          if (lineHeadName != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'Line Head: $lineHeadName',
              style: pw.TextStyle(
                font: regularFont,
                fontSize: 14,
                color: PdfColors.white,
              ),
            ),
          ],
          pw.SizedBox(height: 4),
          pw.Text(
            'Generated on: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
            style: pw.TextStyle(
              font: regularFont,
              fontSize: 12,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildReportInfo(
    pw.Font regularFont,
    pw.Font boldFont,
    String reportType,
    String? startDate,
    String? endDate,
    int recordCount,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Report Information',
            style: pw.TextStyle(font: boldFont, fontSize: 16),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Report Type: ${_formatReportType(reportType)}',
              style: pw.TextStyle(font: regularFont, fontSize: 12)),
          if (startDate != null)
            pw.Text('Start Date: $startDate', style: pw.TextStyle(font: regularFont, fontSize: 12)),
          if (endDate != null) pw.Text('End Date: $endDate', style: pw.TextStyle(font: regularFont, fontSize: 12)),
          pw.Text('Total Records: $recordCount', style: pw.TextStyle(font: regularFont, fontSize: 12)),
        ],
      ),
    );
  }

  static pw.Widget _buildMemberReportInfo(
    pw.Font regularFont,
    pw.Font boldFont,
    String reportType,
    int memberCount,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Report Information',
            style: pw.TextStyle(font: boldFont, fontSize: 16),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Report Type: ${_formatReportType(reportType)}',
              style: pw.TextStyle(font: regularFont, fontSize: 12)),
          pw.Text('Total Members: $memberCount', style: pw.TextStyle(font: regularFont, fontSize: 12)),
        ],
      ),
    );
  }

  static String _formatReportType(String reportType) {
    switch (reportType.toLowerCase()) {
      case 'paid':
        return 'Paid Payments';
      case 'pending':
        return 'Pending Payments (Including Overdue & Partial)';
      case 'active':
        return 'Active Members';
      case 'inactive':
        return 'Inactive Members';
      default:
        return 'All Records';
    }
  }

  static pw.Widget _buildSocietyAnalytics(
    pw.Font regularFont,
    pw.Font boldFont,
    List<MaintenancePaymentModel> payments,
    List<MaintenancePeriodModel> periods,
  ) {
    // Calculate society-specific metrics
    final totalMembers = payments.map((p) => p.userId).toSet().length;
    final paidMembers = payments.where((p) => p.status == PaymentStatus.paid).map((p) => p.userId).toSet().length;
    final pendingMembers = totalMembers - paidMembers;
    final activePeriods = periods.length;

    // Calculate average payment per member
    final totalPaidAmount = payments.fold<double>(0, (sum, p) => sum + p.amountPaid);
    final avgPaymentPerMember = totalMembers > 0 ? totalPaidAmount / totalMembers : 0.0;

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Society Management Analytics',
            style: pw.TextStyle(font: boldFont, fontSize: 16),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildAnalyticsCard(
                  boldFont,
                  regularFont,
                  'Total Members',
                  '$totalMembers',
                  'Active participants in line',
                  primaryColor,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _buildAnalyticsCard(
                  boldFont,
                  regularFont,
                  'Paid Members',
                  '$paidMembers',
                  'Members with completed payments',
                  secondaryColor,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _buildAnalyticsCard(
                  boldFont,
                  regularFont,
                  'Pending Members',
                  '$pendingMembers',
                  'Members with outstanding dues',
                  PdfColors.red,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildAnalyticsCard(
                  boldFont,
                  regularFont,
                  'Active Periods',
                  '$activePeriods',
                  'Maintenance collection periods',
                  PdfColors.blue,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _buildAnalyticsCard(
                  boldFont,
                  regularFont,
                  'Avg Payment/Member',
                  '₹${avgPaymentPerMember.toStringAsFixed(0)}',
                  'Average contribution per member',
                  PdfColors.purple,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(child: pw.Container()), // Empty space
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildAnalyticsCard(
    pw.Font boldFont,
    pw.Font regularFont,
    String title,
    String value,
    String description,
    PdfColor color,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 11,
              color: color,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 18,
              color: color,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            description,
            style: pw.TextStyle(
              font: regularFont,
              fontSize: 8,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPaymentSummary(
    pw.Font regularFont,
    pw.Font boldFont,
    double totalAmount,
    double totalPaid,
    double totalPending,
  ) {
    final collectionPercentage = totalAmount > 0 ? (totalPaid / totalAmount * 100) : 0.0;

    return pw.Column(
      children: [
        // First row - Main amounts
        pw.Row(
          children: [
            pw.Expanded(
              child: _buildSummaryCard(
                boldFont,
                regularFont,
                'Total Amount Due',
                '₹${totalAmount.toStringAsFixed(2)}',
                primaryColor,
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: _buildSummaryCard(
                boldFont,
                regularFont,
                'Amount Collected',
                '₹${totalPaid.toStringAsFixed(2)}',
                secondaryColor,
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: _buildSummaryCard(
                boldFont,
                regularFont,
                'Amount Pending',
                '₹${totalPending.toStringAsFixed(2)}',
                PdfColors.red,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        // Second row - Collection percentage and status
        pw.Row(
          children: [
            pw.Expanded(
              child: _buildSummaryCard(
                boldFont,
                regularFont,
                'Collection Rate',
                '${collectionPercentage.toStringAsFixed(1)}%',
                collectionPercentage >= 85
                    ? secondaryColor
                    : collectionPercentage >= 70
                        ? PdfColors.orange
                        : PdfColors.red,
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: _buildSummaryCard(
                boldFont,
                regularFont,
                'Collection Status',
                collectionPercentage >= 85
                    ? 'Excellent'
                    : collectionPercentage >= 70
                        ? 'Good'
                        : collectionPercentage >= 50
                            ? 'Average'
                            : 'Critical',
                collectionPercentage >= 85
                    ? secondaryColor
                    : collectionPercentage >= 70
                        ? PdfColors.orange
                        : PdfColors.red,
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(child: pw.Container()), // Empty space for alignment
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildSummaryCard(
    pw.Font boldFont,
    pw.Font regularFont,
    String title,
    String value,
    PdfColor color,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              font: regularFont,
              fontSize: 12,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 16,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPaymentsTable(
    pw.Font regularFont,
    pw.Font boldFont,
    List<MaintenancePaymentModel> payments,
    List<MaintenancePeriodModel> periods,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Payment Details',
          style: pw.TextStyle(font: boldFont, fontSize: 16),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(2), // Member Name
            1: const pw.FlexColumnWidth(1.5), // Villa
            2: const pw.FlexColumnWidth(2), // Period
            3: const pw.FlexColumnWidth(1.5), // Amount
            4: const pw.FlexColumnWidth(1.5), // Paid
            5: const pw.FlexColumnWidth(1.5), // Status
          },
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: bgColor),
              children: [
                _buildTableCell(boldFont, 'Member Name', isHeader: true),
                _buildTableCell(boldFont, 'Villa', isHeader: true),
                _buildTableCell(boldFont, 'Period', isHeader: true),
                _buildTableCell(boldFont, 'Amount', isHeader: true),
                _buildTableCell(boldFont, 'Paid', isHeader: true),
                _buildTableCell(boldFont, 'Status', isHeader: true),
              ],
            ),
            // Data rows
            ...payments.map((payment) {
              final period = periods.firstWhere(
                (p) => p.id == payment.periodId,
                orElse: () => const MaintenancePeriodModel(name: 'Unknown'),
              );
              return pw.TableRow(
                children: [
                  _buildTableCell(regularFont, payment.userName ?? 'N/A'),
                  _buildTableCell(regularFont, payment.userVillaNumber ?? 'N/A'),
                  _buildTableCell(regularFont, period.name ?? 'N/A'),
                  _buildTableCell(regularFont, '₹${(payment.amount ?? 0).toStringAsFixed(2)}'),
                  _buildTableCell(regularFont, '₹${payment.amountPaid.toStringAsFixed(2)}'),
                  _buildTableCell(regularFont, _formatPaymentStatus(payment.status)),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildMembersTable(
    pw.Font regularFont,
    pw.Font boldFont,
    List<UserModel> members,
    List<MaintenancePaymentModel> payments,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Member Details',
          style: pw.TextStyle(font: boldFont, fontSize: 16),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(2.5), // Name
            1: const pw.FlexColumnWidth(1.5), // Villa
            2: const pw.FlexColumnWidth(2), // Email
            3: const pw.FlexColumnWidth(1.5), // Mobile
            4: const pw.FlexColumnWidth(1.5), // Status
            5: const pw.FlexColumnWidth(1.5), // Total Paid
          },
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: bgColor),
              children: [
                _buildTableCell(boldFont, 'Name', isHeader: true),
                _buildTableCell(boldFont, 'Villa', isHeader: true),
                _buildTableCell(boldFont, 'Email', isHeader: true),
                _buildTableCell(boldFont, 'Mobile', isHeader: true),
                _buildTableCell(boldFont, 'Status', isHeader: true),
                _buildTableCell(boldFont, 'Total Paid', isHeader: true),
              ],
            ),
            // Data rows
            ...members.map((member) {
              final memberPayments = payments.where((p) => p.userId == member.id).toList();
              final totalPaid = memberPayments.fold<double>(0, (sum, p) => sum + p.amountPaid);

              return pw.TableRow(
                children: [
                  _buildTableCell(regularFont, member.name ?? 'N/A'),
                  _buildTableCell(regularFont, member.villNumber ?? 'N/A'),
                  _buildTableCell(regularFont, member.email ?? 'N/A'),
                  _buildTableCell(regularFont, member.mobileNumber ?? 'N/A'),
                  _buildTableCell(regularFont, member.isVillaOpen == 'yes' ? 'Active' : 'Inactive'),
                  _buildTableCell(regularFont, '₹${totalPaid.toStringAsFixed(2)}'),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTableCell(pw.Font font, String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: isHeader ? 12 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static String _formatPaymentStatus(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.overdue:
        return 'Overdue';
      case PaymentStatus.partiallyPaid:
        return 'Partial';
    }
  }

  static pw.Widget _buildSocietySummary(
    pw.Font regularFont,
    pw.Font boldFont,
    double totalAmount,
    double totalPaid,
    double totalPending,
    int totalMembers,
  ) {
    final collectionPercentage = totalAmount > 0 ? (totalPaid / totalAmount * 100) : 0.0;

    return pw.Column(
      children: [
        pw.Text(
          'Society Financial Overview',
          style: pw.TextStyle(font: boldFont, fontSize: 18),
        ),
        pw.SizedBox(height: 16),
        pw.Row(
          children: [
            pw.Expanded(
              child: _buildSummaryCard(
                boldFont,
                regularFont,
                'Total Society Amount',
                '₹${totalAmount.toStringAsFixed(2)}',
                primaryColor,
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: _buildSummaryCard(
                boldFont,
                regularFont,
                'Amount Collected',
                '₹${totalPaid.toStringAsFixed(2)}',
                secondaryColor,
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: _buildSummaryCard(
                boldFont,
                regularFont,
                'Amount Pending',
                '₹${totalPending.toStringAsFixed(2)}',
                PdfColors.red,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Row(
          children: [
            pw.Expanded(
              child: _buildSummaryCard(
                boldFont,
                regularFont,
                'Total Members',
                '$totalMembers',
                PdfColors.blue,
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: _buildSummaryCard(
                boldFont,
                regularFont,
                'Collection Rate',
                '${collectionPercentage.toStringAsFixed(1)}%',
                collectionPercentage >= 85
                    ? secondaryColor
                    : collectionPercentage >= 70
                        ? PdfColors.orange
                        : PdfColors.red,
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: _buildSummaryCard(
                boldFont,
                regularFont,
                'Society Status',
                collectionPercentage >= 85
                    ? 'Excellent'
                    : collectionPercentage >= 70
                        ? 'Good'
                        : 'Needs Attention',
                collectionPercentage >= 85
                    ? secondaryColor
                    : collectionPercentage >= 70
                        ? PdfColors.orange
                        : PdfColors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildLinePerformanceTable(
    pw.Font regularFont,
    pw.Font boldFont,
    Map<String, List<MaintenancePaymentModel>> linePayments,
    Map<String, List<UserModel>> lineMembers,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Line-wise Performance Analysis',
          style: pw.TextStyle(font: boldFont, fontSize: 16),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(2), // Line Name
            1: const pw.FlexColumnWidth(1.5), // Members
            2: const pw.FlexColumnWidth(2), // Total Amount
            3: const pw.FlexColumnWidth(2), // Collected
            4: const pw.FlexColumnWidth(2), // Pending
            5: const pw.FlexColumnWidth(1.5), // Rate
          },
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: bgColor),
              children: [
                _buildTableCell(boldFont, 'Line', isHeader: true),
                _buildTableCell(boldFont, 'Members', isHeader: true),
                _buildTableCell(boldFont, 'Total Amount', isHeader: true),
                _buildTableCell(boldFont, 'Collected', isHeader: true),
                _buildTableCell(boldFont, 'Pending', isHeader: true),
                _buildTableCell(boldFont, 'Rate %', isHeader: true),
              ],
            ),
            // Data rows
            ...linePayments.entries.map((entry) {
              final lineName = entry.key;
              final payments = entry.value;
              final members = lineMembers[lineName] ?? [];

              final totalAmount = payments.fold<double>(0, (sum, p) => sum + (p.amount ?? 0));
              final totalPaid = payments.fold<double>(0, (sum, p) => sum + p.amountPaid);
              final totalPending = totalAmount - totalPaid;
              final collectionRate = totalAmount > 0 ? (totalPaid / totalAmount * 100) : 0.0;

              return pw.TableRow(
                children: [
                  _buildTableCell(regularFont, lineName.toUpperCase().replaceAll('_', ' ')),
                  _buildTableCell(regularFont, '${members.length}'),
                  _buildTableCell(regularFont, '₹${totalAmount.toStringAsFixed(2)}'),
                  _buildTableCell(regularFont, '₹${totalPaid.toStringAsFixed(2)}'),
                  _buildTableCell(regularFont, '₹${totalPending.toStringAsFixed(2)}'),
                  _buildTableCell(regularFont, '${collectionRate.toStringAsFixed(1)}%'),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }
}
