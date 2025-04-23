import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import 'package:society_management/extentions/firestore_extentions.dart';
import 'package:society_management/maintenance/model/maintenance_payment_model.dart';
import 'package:society_management/maintenance/model/maintenance_period_model.dart';
import 'package:society_management/maintenance/repository/i_maintenance_repository.dart';
import 'package:society_management/utility/app_typednfs.dart';
import 'package:society_management/utility/result.dart';

@Injectable(as: IMaintenanceRepository)
class MaintenanceRepository extends IMaintenanceRepository {
  MaintenanceRepository(super.firestore);

  @override
  FirebaseResult<MaintenancePeriodModel> createMaintenancePeriod({
    required String name,
    required String description,
    required double amount,
    required DateTime startDate,
    required DateTime endDate,
    required DateTime dueDate,
  }) {
    return Result<MaintenancePeriodModel>().tryCatch(
      run: () async {
        final now = Timestamp.now();
        final maintenanceCollection = FirebaseFirestore.instance.maintenance;
        final periodDoc = maintenanceCollection.doc();

        // Calculate total pending amount (will be updated as users pay)
        // First, get total number of users
        final usersSnapshot = await FirebaseFirestore.instance.users.get();
        final totalUsers = usersSnapshot.docs.length;
        final totalPending = amount * totalUsers;

        // Create maintenance period document
        await periodDoc.set({
          'id': periodDoc.id,
          'name': name,
          'description': description,
          'amount': amount,
          'start_date': Timestamp.fromDate(startDate),
          'end_date': Timestamp.fromDate(endDate),
          'due_date': Timestamp.fromDate(dueDate),
          'is_active': true,
          'total_collected': 0.0,
          'total_pending': totalPending,
          'created_at': now,
          'updated_at': now,
        });

        // Create payment records for all users
        final batch = FirebaseFirestore.instance.batch();
        final paymentsCollection = FirebaseFirestore.instance.maintenancePayments;

        for (final userDoc in usersSnapshot.docs) {
          final userData = userDoc.data();
          final paymentDoc = paymentsCollection.doc();
          
          batch.set(paymentDoc, {
            'id': paymentDoc.id,
            'period_id': periodDoc.id,
            'user_id': userData['id'],
            'user_name': userData['name'],
            'user_villa_number': userData['villa_number'],
            'user_line_number': userData['line_number'],
            'collected_by': null,
            'collector_name': null,
            'amount': amount,
            'amount_paid': 0.0,
            'payment_date': null,
            'payment_method': null,
            'status': 'pending',
            'notes': null,
            'receipt_number': null,
            'created_at': now,
            'updated_at': now,
          });
        }

        await batch.commit();

        // Log activity
        final activityDoc = FirebaseFirestore.instance.activities.doc();
        await activityDoc.set({
          'id': activityDoc.id,
          'message': '📅 New maintenance period created: $name',
          'type': 'maintenance_period',
          'timestamp': now,
        });

        return MaintenancePeriodModel(
          id: periodDoc.id,
          name: name,
          description: description,
          amount: amount,
          startDate: startDate.toString(),
          endDate: endDate.toString(),
          dueDate: dueDate.toString(),
          isActive: true,
          totalCollected: 0.0,
          totalPending: totalPending,
          createdAt: now.toDate().toString(),
          updatedAt: now.toDate().toString(),
        );
      },
    );
  }

  @override
  FirebaseResult<List<MaintenancePeriodModel>> getAllMaintenancePeriods() {
    return Result<List<MaintenancePeriodModel>>().tryCatch(
      run: () async {
        final periodsSnapshot = await FirebaseFirestore.instance.maintenance
            .orderBy('created_at', descending: true)
            .get();

        final periods = periodsSnapshot.docs
            .map((doc) => MaintenancePeriodModel.fromJson(doc.data()))
            .toList();

        return periods;
      },
    );
  }

  @override
  FirebaseResult<List<MaintenancePeriodModel>> getActiveMaintenancePeriods() {
    return Result<List<MaintenancePeriodModel>>().tryCatch(
      run: () async {
        final periodsSnapshot = await FirebaseFirestore.instance.maintenance
            .where('is_active', isEqualTo: true)
            .orderBy('created_at', descending: true)
            .get();

        final periods = periodsSnapshot.docs
            .map((doc) => MaintenancePeriodModel.fromJson(doc.data()))
            .toList();

        return periods;
      },
    );
  }

  @override
  FirebaseResult<MaintenancePeriodModel> getMaintenancePeriod({
    required String periodId,
  }) {
    return Result<MaintenancePeriodModel>().tryCatch(
      run: () async {
        final periodDoc = await FirebaseFirestore.instance.maintenance.doc(periodId).get();

        if (!periodDoc.exists) {
          throw Exception('Maintenance period not found');
        }

        return MaintenancePeriodModel.fromJson(periodDoc.data()!);
      },
    );
  }

  @override
  FirebaseResult<MaintenancePeriodModel> updateMaintenancePeriod({
    required String periodId,
    String? name,
    String? description,
    double? amount,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? dueDate,
    bool? isActive,
  }) {
    return Result<MaintenancePeriodModel>().tryCatch(
      run: () async {
        final now = Timestamp.now();
        final periodRef = FirebaseFirestore.instance.maintenance.doc(periodId);
        final periodDoc = await periodRef.get();

        if (!periodDoc.exists) {
          throw Exception('Maintenance period not found');
        }

        final updateData = <String, dynamic>{
          'updated_at': now,
        };

        if (name != null) updateData['name'] = name;
        if (description != null) updateData['description'] = description;
        if (amount != null) updateData['amount'] = amount;
        if (startDate != null) updateData['start_date'] = Timestamp.fromDate(startDate);
        if (endDate != null) updateData['end_date'] = Timestamp.fromDate(endDate);
        if (dueDate != null) updateData['due_date'] = Timestamp.fromDate(dueDate);
        if (isActive != null) updateData['is_active'] = isActive;

        await periodRef.update(updateData);

        // If amount changed, update all pending payments
        if (amount != null) {
          final paymentsSnapshot = await FirebaseFirestore.instance.maintenancePayments
              .where('period_id', isEqualTo: periodId)
              .where('status', isEqualTo: 'pending')
              .get();

          final batch = FirebaseFirestore.instance.batch();
          for (final paymentDoc in paymentsSnapshot.docs) {
            batch.update(paymentDoc.reference, {'amount': amount});
          }
          await batch.commit();
        }

        // Log activity
        final activityDoc = FirebaseFirestore.instance.activities.doc();
        await activityDoc.set({
          'id': activityDoc.id,
          'message': '🔄 Maintenance period updated: ${name ?? periodDoc.data()!['name']}',
          'type': 'maintenance_period_update',
          'timestamp': now,
        });

        final updatedPeriodDoc = await periodRef.get();
        return MaintenancePeriodModel.fromJson(updatedPeriodDoc.data()!);
      },
    );
  }

  @override
  FirebaseResult<void> deleteMaintenancePeriod({
    required String periodId,
  }) {
    return Result<void>().tryCatch(
      run: () async {
        final now = Timestamp.now();
        final periodRef = FirebaseFirestore.instance.maintenance.doc(periodId);
        final periodDoc = await periodRef.get();

        if (!periodDoc.exists) {
          throw Exception('Maintenance period not found');
        }

        final periodName = periodDoc.data()!['name'];

        // Delete all related payments
        final paymentsSnapshot = await FirebaseFirestore.instance.maintenancePayments
            .where('period_id', isEqualTo: periodId)
            .get();

        final batch = FirebaseFirestore.instance.batch();
        for (final paymentDoc in paymentsSnapshot.docs) {
          batch.delete(paymentDoc.reference);
        }

        // Delete the period
        batch.delete(periodRef);
        await batch.commit();

        // Log activity
        final activityDoc = FirebaseFirestore.instance.activities.doc();
        await activityDoc.set({
          'id': activityDoc.id,
          'message': '🗑️ Maintenance period deleted: $periodName',
          'type': 'maintenance_period_delete',
          'timestamp': now,
        });
      },
    );
  }

  @override
  FirebaseResult<MaintenancePaymentModel> recordPayment({
    required String periodId,
    required String userId,
    required String userName,
    required String userVillaNumber,
    required String userLineNumber,
    required String collectedBy,
    required String collectorName,
    required double amount,
    required double amountPaid,
    required DateTime paymentDate,
    required String paymentMethod,
    PaymentStatus status = PaymentStatus.paid,
    String? notes,
    String? receiptNumber,
  }) {
    return Result<MaintenancePaymentModel>().tryCatch(
      run: () async {
        final now = Timestamp.now();
        
        // Find existing payment record
        final paymentsSnapshot = await FirebaseFirestore.instance.maintenancePayments
            .where('period_id', isEqualTo: periodId)
            .where('user_id', isEqualTo: userId)
            .limit(1)
            .get();

        if (paymentsSnapshot.docs.isEmpty) {
          throw Exception('Payment record not found');
        }

        final paymentDoc = paymentsSnapshot.docs.first;
        final paymentRef = paymentDoc.reference;
        final previousAmountPaid = (paymentDoc.data()['amount_paid'] as num?)?.toDouble() ?? 0.0;

        // Determine payment status
        PaymentStatus paymentStatus = status;
        if (amountPaid >= amount) {
          paymentStatus = PaymentStatus.paid;
        } else if (amountPaid > 0) {
          paymentStatus = PaymentStatus.partiallyPaid;
        }

        // Update payment record
        await paymentRef.update({
          'collected_by': collectedBy,
          'collector_name': collectorName,
          'amount_paid': amountPaid,
          'payment_date': Timestamp.fromDate(paymentDate),
          'payment_method': paymentMethod,
          'status': _statusToString(paymentStatus),
          'notes': notes,
          'receipt_number': receiptNumber,
          'updated_at': now,
        });

        // Update maintenance period totals
        final periodRef = FirebaseFirestore.instance.maintenance.doc(periodId);
        final periodDoc = await periodRef.get();

        if (periodDoc.exists) {
          final totalCollected = (periodDoc.data()!['total_collected'] as num?)?.toDouble() ?? 0.0;
          final totalPending = (periodDoc.data()!['total_pending'] as num?)?.toDouble() ?? 0.0;
          
          // Calculate the difference in payment
          final paymentDifference = amountPaid - previousAmountPaid;
          
          await periodRef.update({
            'total_collected': totalCollected + paymentDifference,
            'total_pending': totalPending - paymentDifference > 0 
                ? totalPending - paymentDifference 
                : 0.0,
            'updated_at': now,
          });
        }

        // Log activity
        final activityDoc = FirebaseFirestore.instance.activities.doc();
        await activityDoc.set({
          'id': activityDoc.id,
          'message': '💵 Maintenance payment recorded: ₹$amountPaid by $userName',
          'type': 'maintenance_payment',
          'timestamp': now,
        });

        final updatedPaymentDoc = await paymentRef.get();
        return MaintenancePaymentModel.fromJson(updatedPaymentDoc.data()!);
      },
    );
  }

  String _statusToString(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return 'paid';
      case PaymentStatus.partiallyPaid:
        return 'partially_paid';
      case PaymentStatus.overdue:
        return 'overdue';
      case PaymentStatus.pending:
      default:
        return 'pending';
    }
  }

  @override
  FirebaseResult<List<MaintenancePaymentModel>> getPaymentsForPeriod({
    required String periodId,
  }) {
    return Result<List<MaintenancePaymentModel>>().tryCatch(
      run: () async {
        final paymentsSnapshot = await FirebaseFirestore.instance.maintenancePayments
            .where('period_id', isEqualTo: periodId)
            .get();

        final payments = paymentsSnapshot.docs
            .map((doc) => MaintenancePaymentModel.fromJson(doc.data()))
            .toList();

        return payments;
      },
    );
  }

  @override
  FirebaseResult<List<MaintenancePaymentModel>> getPaymentsForUser({
    required String userId,
  }) {
    return Result<List<MaintenancePaymentModel>>().tryCatch(
      run: () async {
        final paymentsSnapshot = await FirebaseFirestore.instance.maintenancePayments
            .where('user_id', isEqualTo: userId)
            .orderBy('created_at', descending: true)
            .get();

        final payments = paymentsSnapshot.docs
            .map((doc) => MaintenancePaymentModel.fromJson(doc.data()))
            .toList();

        return payments;
      },
    );
  }

  @override
  FirebaseResult<List<MaintenancePaymentModel>> getPaymentsForLine({
    required String periodId,
    required String lineNumber,
  }) {
    return Result<List<MaintenancePaymentModel>>().tryCatch(
      run: () async {
        final paymentsSnapshot = await FirebaseFirestore.instance.maintenancePayments
            .where('period_id', isEqualTo: periodId)
            .where('user_line_number', isEqualTo: lineNumber)
            .get();

        final payments = paymentsSnapshot.docs
            .map((doc) => MaintenancePaymentModel.fromJson(doc.data()))
            .toList();

        return payments;
      },
    );
  }

  @override
  FirebaseResult<Map<String, dynamic>> getPaymentStatistics({
    required String periodId,
  }) {
    return Result<Map<String, dynamic>>().tryCatch(
      run: () async {
        final paymentsSnapshot = await FirebaseFirestore.instance.maintenancePayments
            .where('period_id', isEqualTo: periodId)
            .get();

        int totalUsers = paymentsSnapshot.docs.length;
        int paidCount = 0;
        int partiallyPaidCount = 0;
        int pendingCount = 0;
        int overdueCount = 0;
        double totalAmount = 0.0;
        double totalCollected = 0.0;
        double totalPending = 0.0;

        for (final doc in paymentsSnapshot.docs) {
          final data = doc.data();
          final status = data['status'] as String?;
          final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
          final amountPaid = (data['amount_paid'] as num?)?.toDouble() ?? 0.0;

          totalAmount += amount;
          totalCollected += amountPaid;
          totalPending += (amount - amountPaid);

          switch (status) {
            case 'paid':
              paidCount++;
              break;
            case 'partially_paid':
              partiallyPaidCount++;
              break;
            case 'overdue':
              overdueCount++;
              break;
            case 'pending':
            default:
              pendingCount++;
              break;
          }
        }

        return {
          'total_users': totalUsers,
          'paid_count': paidCount,
          'partially_paid_count': partiallyPaidCount,
          'pending_count': pendingCount,
          'overdue_count': overdueCount,
          'total_amount': totalAmount,
          'total_collected': totalCollected,
          'total_pending': totalPending,
          'collection_percentage': totalUsers > 0 
              ? (paidCount / totalUsers) * 100 
              : 0.0,
        };
      },
    );
  }

  @override
  FirebaseResult<MaintenancePaymentModel> updatePaymentStatus({
    required String paymentId,
    required PaymentStatus status,
    double? amountPaid,
    String? notes,
  }) {
    return Result<MaintenancePaymentModel>().tryCatch(
      run: () async {
        final now = Timestamp.now();
        final paymentRef = FirebaseFirestore.instance.maintenancePayments.doc(paymentId);
        final paymentDoc = await paymentRef.get();

        if (!paymentDoc.exists) {
          throw Exception('Payment record not found');
        }

        final updateData = <String, dynamic>{
          'status': _statusToString(status),
          'updated_at': now,
        };

        if (amountPaid != null) updateData['amount_paid'] = amountPaid;
        if (notes != null) updateData['notes'] = notes;

        await paymentRef.update(updateData);

        // Update maintenance period totals if amount paid changed
        if (amountPaid != null) {
          final periodId = paymentDoc.data()!['period_id'] as String?;
          final previousAmountPaid = (paymentDoc.data()!['amount_paid'] as num?)?.toDouble() ?? 0.0;
          final paymentDifference = amountPaid - previousAmountPaid;

          if (periodId != null) {
            final periodRef = FirebaseFirestore.instance.maintenance.doc(periodId);
            final periodDoc = await periodRef.get();

            if (periodDoc.exists) {
              final totalCollected = (periodDoc.data()!['total_collected'] as num?)?.toDouble() ?? 0.0;
              final totalPending = (periodDoc.data()!['total_pending'] as num?)?.toDouble() ?? 0.0;

              await periodRef.update({
                'total_collected': totalCollected + paymentDifference,
                'total_pending': totalPending - paymentDifference > 0 
                    ? totalPending - paymentDifference 
                    : 0.0,
                'updated_at': now,
              });
            }
          }
        }

        final updatedPaymentDoc = await paymentRef.get();
        return MaintenancePaymentModel.fromJson(updatedPaymentDoc.data()!);
      },
    );
  }
}
