import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:society_management/auth/service/auth_service.dart';
import 'package:society_management/constants/app_constants.dart';
import 'package:society_management/dashboard/repository/i_dashboard_stats_repository.dart';
import 'package:society_management/extentions/firestore_extentions.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/maintenance/model/maintenance_payment_model.dart';
import 'package:society_management/maintenance/repository/i_maintenance_repository.dart';
import 'package:society_management/users/repository/i_user_repository.dart';

/// Service to fetch society data for AI analysis
class SocietyDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Use lazy getters to avoid initialization issues
  AuthService get _authService => getIt<AuthService>();
  IDashboardStatsRepository get _statsRepository => getIt<IDashboardStatsRepository>();
  IMaintenanceRepository get _maintenanceRepository => getIt<IMaintenanceRepository>();
  IUserRepository get _userRepository => getIt<IUserRepository>();

  /// Get current user information with proper role formatting
  Future<Map<String, dynamic>> getCurrentUserInfo() async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) {
        return {'error': 'No user is currently logged in'};
      }

      // Format role properly for display
      String displayRole = currentUser.role ?? 'Member';
      switch (displayRole.toLowerCase()) {
        case 'line_head':
        case 'linehead':
          displayRole = 'Line Head';
          break;
        case 'admin':
        case 'admins':
          displayRole = 'Admin';
          break;
        case 'line head + member':
          displayRole = 'Line Head + Member';
          break;
        default:
          displayRole = 'Member';
      }

      // Format line number for display
      String? displayLineNumber;
      if (currentUser.lineNumber != null) {
        switch (currentUser.lineNumber) {
          case AppConstants.firstLine:
            displayLineNumber = 'Line 1';
            break;
          case AppConstants.secondLine:
            displayLineNumber = 'Line 2';
            break;
          case AppConstants.thirdLine:
            displayLineNumber = 'Line 3';
            break;
          case AppConstants.fourthLine:
            displayLineNumber = 'Line 4';
            break;
          case AppConstants.fifthLine:
            displayLineNumber = 'Line 5';
            break;
          default:
            displayLineNumber = currentUser.lineNumber;
        }
      }

      return {
        'id': currentUser.id,
        'name': currentUser.name,
        'email': currentUser.email,
        'role': displayRole,
        'rawRole': currentUser.role, // Keep original for logic
        'lineNumber': displayLineNumber,
        'rawLineNumber': currentUser.lineNumber, // Keep original for queries
        'villaNumber': currentUser.villNumber,
        'mobileNumber': currentUser.mobileNumber,
        'isAdmin': currentUser.role?.toLowerCase() == 'admin' || currentUser.role?.toLowerCase() == 'admins',
        'isLineHead': currentUser.role?.toLowerCase().contains('line') ?? false,
        'isMember': currentUser.role?.toLowerCase() == 'member' ||
            (currentUser.role?.toLowerCase().contains('member') ?? false),
      };
    } catch (e) {
      return {'error': 'Error fetching current user: $e'};
    }
  }

  /// Get society dashboard statistics
  Future<Map<String, dynamic>> getSocietyStats() async {
    try {
      final result = await _statsRepository.getDashboardStats();

      return result.fold(
        (failure) => {'error': failure.message},
        (stats) => {
          'totalMembers': stats.totalMembers,
          'totalExpenses': stats.totalExpenses,
          'maintenanceCollected': stats.maintenanceCollected,
          'maintenancePending': stats.maintenancePending,
          'activeMaintenance': stats.activeMaintenance,
          'updatedAt': stats.updatedAt,
        },
      );
    } catch (e) {
      return {'error': 'Error fetching society stats: $e'};
    }
  }

  /// Get active maintenance periods
  Future<Map<String, dynamic>> getActiveMaintenancePeriods() async {
    try {
      final result = await _maintenanceRepository.getActiveMaintenancePeriods();

      return result.fold(
        (failure) => {'error': failure.message},
        (periods) => {
          'count': periods.length,
          'periods': periods
              .map((period) => {
                    'id': period.id,
                    'name': period.name,
                    'amount': period.amount,
                    'startDate': period.startDate?.toString(),
                    'dueDate': period.dueDate?.toString(),
                    'status': 'active',
                  })
              .toList(),
        },
      );
    } catch (e) {
      return {'error': 'Error fetching maintenance periods: $e'};
    }
  }

  /// Get user's pending maintenance payments
  Future<Map<String, dynamic>> getUserPendingPayments() async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) {
        return {'error': 'No user is currently logged in'};
      }

      final userId = currentUser.id;
      if (userId == null) {
        return {'error': 'User ID is null'};
      }

      // Get all active maintenance periods
      final periodsResult = await _maintenanceRepository.getActiveMaintenancePeriods();

      return await periodsResult.fold(
        (failure) async => {'error': failure.message},
        (periods) async {
          final pendingPayments = <Map<String, dynamic>>[];

          for (final period in periods) {
            if (period.id == null) continue;

            // Get user's payment for this period
            final paymentsSnapshot = await _firestore.maintenancePayments
                .where('period_id', isEqualTo: period.id)
                .where('user_id', isEqualTo: userId)
                .get();

            for (final doc in paymentsSnapshot.docs) {
              final payment = MaintenancePaymentModel.fromJson(doc.data());

              // Only include pending or partially paid payments
              if (payment.status == PaymentStatus.pending ||
                  payment.status == PaymentStatus.partiallyPaid ||
                  payment.status == PaymentStatus.overdue) {
                pendingPayments.add({
                  'periodId': payment.periodId,
                  'periodName': period.name,
                  'amount': payment.amount,
                  'amountPaid': payment.amountPaid,
                  'amountDue': (payment.amount ?? 0) - (payment.amountPaid ?? 0),
                  'status': payment.status.toString().split('.').last,
                  'dueDate': period.dueDate?.toString(),
                });
              }
            }
          }

          return {
            'count': pendingPayments.length,
            'payments': pendingPayments,
            'totalDue': pendingPayments.fold(0.0, (total, payment) => total + (payment['amountDue'] as double? ?? 0.0)),
          };
        },
      );
    } catch (e) {
      return {'error': 'Error fetching pending payments: $e'};
    }
  }

  /// Get line members for line heads or all members for admins
  Future<Map<String, dynamic>> getLineMembers() async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) {
        return {'error': 'No user is currently logged in'};
      }

      List<Map<String, dynamic>> members = [];

      if (currentUser.role?.toLowerCase() == 'admin' || currentUser.role?.toLowerCase() == 'admins') {
        // Admin can see all members
        final allUsersSnapshot = await _firestore.users.get();
        for (final userDoc in allUsersSnapshot.docs) {
          final userData = userDoc.data();
          if (userData['role']?.toLowerCase() != 'admin' && userData['role']?.toLowerCase() != 'admins') {
            members.add({
              'id': userData['id'],
              'name': userData['name'],
              'email': userData['email'],
              'role': _formatRole(userData['role']),
              'lineNumber': _formatLineNumber(userData['lineNumber']),
              'villaNumber': userData['villNumber'],
              'mobileNumber': userData['mobileNumber'],
            });
          }
        }
      } else if (currentUser.role?.toLowerCase().contains('line') == true) {
        // Line head can see their line members
        final lineUsersSnapshot = await _firestore.users.where('lineNumber', isEqualTo: currentUser.lineNumber).get();

        for (final userDoc in lineUsersSnapshot.docs) {
          final userData = userDoc.data();
          members.add({
            'id': userData['id'],
            'name': userData['name'],
            'email': userData['email'],
            'role': _formatRole(userData['role']),
            'lineNumber': _formatLineNumber(userData['lineNumber']),
            'villaNumber': userData['villNumber'],
            'mobileNumber': userData['mobileNumber'],
          });
        }
      }

      return {
        'members': members,
        'totalMembers': members.length,
        'lineNumber': _formatLineNumber(currentUser.lineNumber),
      };
    } catch (e) {
      return {'error': 'Error fetching line members: $e'};
    }
  }

  /// Get comprehensive maintenance information for current user's context
  Future<Map<String, dynamic>> getMaintenanceInfo() async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) {
        return {'error': 'No user is currently logged in'};
      }

      final activePeriods = await getActiveMaintenancePeriods();
      final userPayments = await getUserPendingPayments();

      Map<String, dynamic> result = {
        'activePeriods': activePeriods,
        'userPayments': userPayments,
      };

      // For line heads, get line-specific maintenance data
      if (currentUser.role?.toLowerCase().contains('line') == true && currentUser.lineNumber != null) {
        final lineMaintenanceData = await _getLineMaintenanceData(currentUser.lineNumber!);
        result['lineMaintenanceData'] = lineMaintenanceData;
      }

      // For admins, get society-wide maintenance data
      if (currentUser.role?.toLowerCase() == 'admin' || currentUser.role?.toLowerCase() == 'admins') {
        final societyMaintenanceData = await _getSocietyMaintenanceData();
        result['societyMaintenanceData'] = societyMaintenanceData;
      }

      return result;
    } catch (e) {
      return {'error': 'Error fetching maintenance info: $e'};
    }
  }

  /// Get user's pending payments as a list for reminder service
  Future<List<Map<String, dynamic>>> getUserPendingPaymentsList() async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) return [];

      final userId = currentUser.id;
      if (userId == null) return [];

      // Get all payment records for the current user
      final paymentsSnapshot = await _firestore.maintenancePayments.where('user_id', isEqualTo: userId).get();

      List<Map<String, dynamic>> pendingPayments = [];

      for (final paymentDoc in paymentsSnapshot.docs) {
        final paymentData = paymentDoc.data();
        final amount = (paymentData['amount'] as num?)?.toDouble() ?? 0;
        final amountPaid = (paymentData['amount_paid'] as num?)?.toDouble() ?? 0;
        final status = paymentData['status'] as String?;

        // Check if payment is pending
        if (status != 'paid' && amount > amountPaid) {
          pendingPayments.add({
            'id': paymentDoc.id,
            'amount': amount,
            'amount_paid': amountPaid,
            'status': status,
            'period_id': paymentData['period_id'],
            'period_name': paymentData['period_name'] ?? 'Unknown Period',
            'due_date': paymentData['due_date'],
            'user_name': paymentData['user_name'],
          });
        }
      }

      return pendingPayments;
    } catch (e) {
      debugPrint('Error fetching user pending payments: $e');
      return [];
    }
  }

  /// Get all society data for AI analysis
  Future<Map<String, dynamic>> getAllSocietyData() async {
    debugPrint('=== Starting getAllSocietyData ===');

    final userInfo = await getCurrentUserInfo();
    debugPrint('User info fetched: ${userInfo.toString()}');

    final stats = await getSocietyStats();
    debugPrint('Society stats fetched: ${stats.toString()}');

    final maintenanceInfo = await getMaintenanceInfo();
    debugPrint('Maintenance info fetched: ${maintenanceInfo.toString()}');

    final lineMembers = await getLineMembers();
    debugPrint('Line members fetched: ${lineMembers.toString()}');

    final result = {
      'currentUser': userInfo,
      'societyStats': stats,
      'maintenanceInfo': maintenanceInfo,
      'lineMembers': lineMembers,
      'timestamp': DateTime.now().toIso8601String(),
    };

    debugPrint('=== Final getAllSocietyData result ===');
    debugPrint(result.toString());

    return result;
  }

  /// Helper method to format role for display
  String _formatRole(String? role) {
    if (role == null) return 'Member';

    switch (role.toLowerCase()) {
      case 'line_head':
      case 'linehead':
        return 'Line Head';
      case 'admin':
      case 'admins':
        return 'Admin';
      case 'line head + member':
        return 'Line Head + Member';
      default:
        return 'Member';
    }
  }

  /// Helper method to format line number for display
  String? _formatLineNumber(String? lineNumber) {
    if (lineNumber == null) return null;

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
        return lineNumber;
    }
  }

  /// Get line-specific maintenance data for line heads
  Future<Map<String, dynamic>> _getLineMaintenanceData(String lineNumber) async {
    try {
      debugPrint('Fetching line maintenance data for line: $lineNumber');

      // Query maintenance payments using the correct field name
      final linePaymentsSnapshot =
          await _firestore.maintenancePayments.where('user_line_number', isEqualTo: lineNumber).get();

      debugPrint('Found ${linePaymentsSnapshot.docs.length} payment records for line $lineNumber');

      double totalCollected = 0;
      double totalPending = 0;
      int fullyPaidCount = 0;
      int pendingCount = 0;
      List<Map<String, dynamic>> paymentDetails = [];

      for (final paymentDoc in linePaymentsSnapshot.docs) {
        final paymentData = paymentDoc.data();
        final amountPaid = (paymentData['amount_paid'] as num?)?.toDouble() ?? 0;
        final amount = (paymentData['amount'] as num?)?.toDouble() ?? 0;
        final status = paymentData['status'] as String?;
        final userName = paymentData['user_name'] as String? ?? paymentData['userName'] as String? ?? 'Unknown';
        final periodId = paymentData['period_id'] as String? ?? paymentData['periodId'] as String?;

        totalCollected += amountPaid;
        if (amount > 0) {
          totalPending += (amount - amountPaid);
        }

        final isPaid = status == 'paid' || (amount > 0 && amountPaid >= amount);
        if (isPaid) {
          fullyPaidCount++;
        } else {
          pendingCount++;
        }

        // Add payment details for AI context
        paymentDetails.add({
          'userName': userName,
          'amount': amount,
          'amountPaid': amountPaid,
          'amountDue': amount - amountPaid,
          'status': status ?? (isPaid ? 'paid' : 'pending'),
          'periodId': periodId,
        });

        debugPrint('Payment: $userName - Paid: ₹$amountPaid, Total: ₹$amount, Status: $status');
      }

      // Also get line members count from users collection
      final lineMembersSnapshot = await _firestore.users.where('lineNumber', isEqualTo: lineNumber).get();

      final totalLineMembers = lineMembersSnapshot.docs.length;

      debugPrint(
          'Line $lineNumber summary: Collected: ₹$totalCollected, Pending: ₹$totalPending, Paid: $fullyPaidCount, Pending: $pendingCount, Total Members: $totalLineMembers');

      return {
        'lineNumber': _formatLineNumber(lineNumber),
        'rawLineNumber': lineNumber,
        'totalCollected': totalCollected,
        'totalPending': totalPending,
        'fullyPaidCount': fullyPaidCount,
        'pendingCount': pendingCount,
        'totalMembers': totalLineMembers,
        'paymentRecords': linePaymentsSnapshot.docs.length,
        'paymentDetails': paymentDetails,
        'collectionPercentage': totalLineMembers > 0 ? (fullyPaidCount / totalLineMembers * 100) : 0,
      };
    } catch (e) {
      debugPrint('Error fetching line maintenance data: $e');
      return {'error': 'Error fetching line maintenance data: $e'};
    }
  }

  /// Get society-wide maintenance data for admins
  Future<Map<String, dynamic>> _getSocietyMaintenanceData() async {
    try {
      final allPaymentsSnapshot = await _firestore.maintenancePayments.get();

      double totalCollected = 0;
      double totalPending = 0;
      int fullyPaidCount = 0;
      int pendingCount = 0;
      Map<String, Map<String, dynamic>> lineWiseData = {};

      for (final paymentDoc in allPaymentsSnapshot.docs) {
        final paymentData = paymentDoc.data();
        final amountPaid = (paymentData['amount_paid'] as num?)?.toDouble() ?? 0;
        final amount = (paymentData['amount'] as num?)?.toDouble() ?? 0;
        final status = paymentData['status'] as String?;
        final userLineNumber = paymentData['user_line_number'] as String?;

        totalCollected += amountPaid;
        totalPending += (amount - amountPaid);

        if (status == 'paid' || amountPaid >= amount) {
          fullyPaidCount++;
        } else {
          pendingCount++;
        }

        // Line-wise breakdown
        if (userLineNumber != null) {
          final formattedLineNumber = _formatLineNumber(userLineNumber) ?? userLineNumber;
          if (!lineWiseData.containsKey(formattedLineNumber)) {
            lineWiseData[formattedLineNumber] = {
              'collected': 0.0,
              'pending': 0.0,
              'fullyPaid': 0,
              'pendingMembers': 0,
            };
          }

          lineWiseData[formattedLineNumber]!['collected'] += amountPaid;
          lineWiseData[formattedLineNumber]!['pending'] += (amount - amountPaid);

          if (status == 'paid' || amountPaid >= amount) {
            lineWiseData[formattedLineNumber]!['fullyPaid']++;
          } else {
            lineWiseData[formattedLineNumber]!['pendingMembers']++;
          }
        }
      }

      return {
        'totalCollected': totalCollected,
        'totalPending': totalPending,
        'fullyPaidCount': fullyPaidCount,
        'pendingCount': pendingCount,
        'totalMembers': fullyPaidCount + pendingCount,
        'lineWiseData': lineWiseData,
      };
    } catch (e) {
      return {'error': 'Error fetching society maintenance data: $e'};
    }
  }

  /// Get user's payment history
  Future<List<Map<String, dynamic>>> getUserPaymentHistory() async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) return [];

      final userId = currentUser.id;
      if (userId == null) return [];

      // Get all payment records for the current user
      final paymentsSnapshot = await _firestore.maintenancePayments.where('user_id', isEqualTo: userId).get();

      List<Map<String, dynamic>> paymentHistory = [];

      for (final paymentDoc in paymentsSnapshot.docs) {
        final paymentData = paymentDoc.data();
        paymentHistory.add({
          'period_name': paymentData['period_name'] ?? 'Unknown Period',
          'amount': paymentData['amount'] ?? 0,
          'amount_paid': paymentData['amount_paid'] ?? 0,
          'status': paymentData['status'] ?? 'pending',
          'payment_date': paymentData['payment_date'] ?? 'Not recorded',
          'due_date': paymentData['due_date'] ?? '',
        });
      }

      // Sort by most recent first
      paymentHistory.sort((a, b) {
        final aDate = a['payment_date'] as String;
        final bDate = b['payment_date'] as String;
        return bDate.compareTo(aDate);
      });

      return paymentHistory;
    } catch (e) {
      debugPrint('Error fetching payment history: $e');
      return [];
    }
  }

  /// Get line head information for a specific line
  Future<Map<String, dynamic>?> getLineHeadInfo(int lineNumber) async {
    try {
      final lineNumberStr = lineNumber.toString();
      final usersSnapshot = await _firestore.users
          .where('lineNumber', isEqualTo: lineNumberStr)
          .where('role', whereIn: ['Line Head', 'Line head', 'line head']).get();

      if (usersSnapshot.docs.isNotEmpty) {
        final lineHeadData = usersSnapshot.docs.first.data();
        return {
          'name': lineHeadData['name'] ?? 'Unknown',
          'phone': lineHeadData['phone'] ?? 'Not available',
          'email': lineHeadData['email'] ?? 'Not available',
          'line_number': lineHeadData['lineNumber'] ?? lineNumberStr,
        };
      }

      return null;
    } catch (e) {
      debugPrint('Error fetching line head info: $e');
      return null;
    }
  }

  /// Get user's complaints
  Future<List<Map<String, dynamic>>> getUserComplaints() async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null) return [];

      final userEmail = currentUser.email;
      if (userEmail == null) return [];

      final complaintsSnapshot = await _firestore.complaints
          .where('user_email', isEqualTo: userEmail)
          .orderBy('submitted_date', descending: true)
          .get();

      return complaintsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? 'No title',
          'description': data['description'] ?? 'No description',
          'category': data['category'] ?? 'General',
          'status': data['status'] ?? 'pending',
          'submitted_date': data['submitted_date'] ?? 'Unknown date',
          'resolved_date': data['resolved_date'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching user complaints: $e');
      return [];
    }
  }

  /// Get upcoming events
  Future<List<Map<String, dynamic>>> getUpcomingEvents() async {
    try {
      final now = DateTime.now();
      final eventsSnapshot = await _firestore.events
          .where('event_date', isGreaterThanOrEqualTo: now.toIso8601String())
          .orderBy('event_date')
          .limit(10)
          .get();

      return eventsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? 'Event',
          'description': data['description'] ?? 'No description',
          'event_date': data['event_date'] ?? 'Date TBD',
          'location': data['location'] ?? 'Society premises',
          'organizer': data['organizer'] ?? 'Society management',
          'category': data['category'] ?? 'General',
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching upcoming events: $e');
      return [];
    }
  }

  /// Get society expenses
  Future<List<Map<String, dynamic>>> getSocietyExpenses() async {
    try {
      final expensesSnapshot = await _firestore.expenses.orderBy('date', descending: true).limit(50).get();

      return expensesSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'description': data['description'] ?? 'No description',
          'amount': data['amount'] ?? 0,
          'category': data['category'] ?? 'Other',
          'date': data['date'] ?? 'Unknown date',
          'approved_by': data['approved_by'] ?? 'Unknown',
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching society expenses: $e');
      return [];
    }
  }
}
