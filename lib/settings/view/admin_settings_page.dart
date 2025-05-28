import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:society_management/dashboard/repository/i_dashboard_stats_repository.dart';
import 'package:society_management/injector/injector.dart';
import 'package:society_management/maintenance/view/fix_line_inconsistencies_page.dart';
import 'package:society_management/utility/extentions/navigation_extension.dart';
import 'package:society_management/utility/utility.dart';
import 'package:society_management/widget/common_app_bar.dart';
import 'package:society_management/widget/common_button.dart';
import 'package:society_management/widget/common_card.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  bool _isLoading = false;
  String? _successMessage;
  String? _errorMessage;

  Future<void> _clearAllData() async {
    if (!mounted) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will delete ALL data except user accounts. This action cannot be undone. Are you sure you want to continue?',
          style: TextStyle(color: Colors.red),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All Data'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Double confirmation for safety
    final doubleConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Final Confirmation'),
        content: const Text(
          'ALL DATA WILL BE PERMANENTLY DELETED. This is typically used only for testing. Are you absolutely sure?',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Delete Everything'),
          ),
        ],
      ),
    );

    if (doubleConfirmed != true || !mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final firestore = FirebaseFirestore.instance;

      // List of collections to clear
      final collections = [
        // Maintenance related collections (highest priority)
        'maintenance', // Direct maintenance collection
        'maintenance_periods',
        'maintenance_payments',
        'maintenance_stats',

        // Dashboard stats collections
        'admin_dashboard_stats',
        'line_head_dashboard_stats',
        'user_dashboard_stats',
        'user_specific_stats',
        'dashboard_stats',
        'dashboard_counts',
        'dashboard_data',
        'line_stats',
        'user_stats',
        'stats', // Direct stats collection

        // Other data collections
        'expenses',
        'expense_categories',
        'expense_stats',
        'complaints',
        'activities',
        'notifications',
        'counts',
        'summary_data',
        'events',
        // Add any other collections you want to clear
      ];

      // Delete all documents in each collection
      for (final collectionName in collections) {
        debugPrint('Clearing collection: $collectionName');
        final querySnapshot = await firestore.collection(collectionName).get();

        // Log the number of documents found
        debugPrint('Found ${querySnapshot.docs.length} documents in $collectionName');

        // Use a batch to delete documents in chunks for better performance
        var batch = firestore.batch();
        int count = 0;

        for (final doc in querySnapshot.docs) {
          batch.delete(doc.reference);
          count++;

          // Commit batch every 500 operations to avoid hitting limits
          if (count >= 500) {
            await batch.commit();
            batch = firestore.batch();
            count = 0;
            debugPrint('Committed batch of 500 deletes for $collectionName');
          }
        }

        // Commit any remaining operations
        if (count > 0) {
          await batch.commit();
          debugPrint('Committed final batch of $count deletes for $collectionName');
        }

        // Double-check if the collection is empty
        final verifySnapshot = await firestore.collection(collectionName).get();
        if (verifySnapshot.docs.isNotEmpty) {
          debugPrint(
              'WARNING: Collection $collectionName still has ${verifySnapshot.docs.length} documents after batch delete');

          // Force delete any remaining documents individually
          for (final doc in verifySnapshot.docs) {
            try {
              await doc.reference.delete();
              debugPrint('Forced deletion of document ${doc.id} from $collectionName');
            } catch (e) {
              debugPrint('Error deleting document ${doc.id} from $collectionName: $e');
            }
          }
        } else {
          debugPrint('Successfully cleared collection $collectionName');
        }
      }

      // Specifically check and clear critical collections
      final criticalCollections = ['maintenance', 'admin_dashboard_stats', 'stats'];

      for (final collectionName in criticalCollections) {
        final querySnapshot = await firestore.collection(collectionName).get();
        if (querySnapshot.docs.isNotEmpty) {
          debugPrint(
              'CRITICAL: Collection $collectionName still has ${querySnapshot.docs.length} documents after clearing');

          // Force delete again with individual deletes
          for (final doc in querySnapshot.docs) {
            try {
              await doc.reference.delete();
              debugPrint('Deleted document ${doc.id} from $collectionName');
            } catch (e) {
              debugPrint('Error deleting document ${doc.id} from $collectionName: $e');
            }
          }
        }
      }

      // Create a new activity record to show the data was cleared
      try {
        final activityDoc = firestore.collection('activities').doc();
        await activityDoc.set({
          'id': activityDoc.id,
          'message': '🗑️ All data cleared by admin',
          'type': 'admin_clear_data',
          'timestamp': Timestamp.now(),
        });
      } catch (e) {
        // Ignore errors when creating activity record
        // Silently ignore
      }

      // Force reset of dashboard stats
      try {
        // Manually create empty stats documents to ensure they're completely reset
        final now = Timestamp.now();

        // Reset admin dashboard stats - first check if it exists
        final adminStatsDoc = await firestore.collection('admin_dashboard_stats').doc('stats').get();

        if (adminStatsDoc.exists) {
          // Delete it first to ensure clean slate
          await firestore.collection('admin_dashboard_stats').doc('stats').delete();
          debugPrint('Deleted existing admin_dashboard_stats/stats document');
        }

        // Create a new document with zeroed values
        await firestore.collection('admin_dashboard_stats').doc('stats').set({
          'total_members': 0,
          'total_expenses': 0.0,
          'maintenance_collected': 0.0,
          'maintenance_pending': 0.0,
          'active_maintenance': 0,
          'fully_paid': 0,
          'updated_at': now,
        });
        debugPrint('Created new admin_dashboard_stats/stats document with zeroed values');

        // Import the dashboard repository
        final dashboardStatsRepository = getIt<IDashboardStatsRepository>();

        // Update admin dashboard stats
        await dashboardStatsRepository.updateAdminDashboardStats();

        // Update all line stats
        final usersSnapshot = await firestore.collection('users').get();
        final lineNumbers = usersSnapshot.docs
            .map((doc) => doc.data()['line_number'] as String?)
            .where((line) => line != null)
            .toSet()
            .cast<String>();

        // Reset line head and user dashboard stats
        for (final lineNumber in lineNumbers) {
          // Reset line head dashboard stats
          await firestore.collection('line_head_dashboard_stats').doc(lineNumber).set({
            'total_members': 0,
            'total_expenses': 0.0,
            'maintenance_collected': 0.0,
            'maintenance_pending': 0.0,
            'active_maintenance': 0,
            'fully_paid': 0,
            'line_number': lineNumber,
            'updated_at': now,
          });

          // Reset user dashboard stats
          await firestore.collection('user_dashboard_stats').doc(lineNumber).set({
            'total_members': 0,
            'total_expenses': 0.0,
            'maintenance_collected': 0.0,
            'maintenance_pending': 0.0,
            'active_maintenance': 0,
            'fully_paid': 0,
            'line_number': lineNumber,
            'updated_at': now,
          });

          // Update line stats
          await dashboardStatsRepository.updateLineStats(lineNumber);
        }

        // Reset user-specific stats
        for (final userDoc in usersSnapshot.docs) {
          final userId = userDoc.id;
          await firestore.collection('user_specific_stats').doc(userId).set({
            'total_members': 1,
            'total_expenses': 0.0,
            'maintenance_collected': 0.0,
            'maintenance_pending': 0.0,
            'active_maintenance': 0,
            'fully_paid': 0,
            'line_number': userDoc.data()['line_number'],
            'updated_at': now,
          });
        }

        // Reset the direct stats document
        final statsDoc = await firestore.collection('stats').doc('stats').get();
        if (statsDoc.exists) {
          // Delete it first
          await firestore.collection('stats').doc('stats').delete();
          debugPrint('Deleted existing stats/stats document');
        }

        // Create a new document with zeroed values
        await firestore.collection('stats').doc('stats').set({
          'active_maintenance': 0,
          'fully_paid': 0,
          'maintenance_collected': 0.0,
          'maintenance_pending': 0.0,
          'total_expenses': 0.0,
          'total_members': 0,
          'updated_at': now,
        });
        debugPrint('Created new stats/stats document with zeroed values');

        // Force update of all stats by triggering a maintenance period creation update
        await dashboardStatsRepository.updateDashboardsForMaintenancePeriodCreation();
      } catch (e) {
        // Log but don't fail the operation
        debugPrint('Error resetting dashboard stats: $e');
      }

      setState(() {
        _isLoading = false;
        _successMessage =
            'All data has been cleared successfully. Please refresh the dashboard or log out and log back in.';
      });

      Utility.toast(message: 'All data cleared successfully');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error clearing data: $e';
      });

      Utility.toast(message: 'Error clearing data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Admin Settings',
        showDivider: true,
        onBackTap: () => context.pop(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMaintenanceTools(),
            const SizedBox(height: 24),
            _buildDangerZone(),
            if (_successMessage != null) ...[
              const SizedBox(height: 24),
              _buildSuccessMessage(),
              const SizedBox(height: 16),
              _buildRefreshButton(),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 24),
              _buildErrorMessage(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZone() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            'Danger Zone',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.red,
                ),
          ),
        ),
        CommonCard(
          child: Column(
            children: [
              const ListTile(
                leading: Icon(Icons.delete_forever, color: Colors.red, size: 28),
                title: Text(
                  'Clear All Data',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Delete all app data except user accounts. This is typically used for testing purposes only.',
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: CommonButton(
                  text: 'Clear All Data',
                  isLoading: _isLoading,
                  onTap: _clearAllData,
                  backgroundColor: Colors.red,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Warning: This action cannot be undone. All maintenance periods, payments, expenses, and other data will be permanently deleted.',
                  style: TextStyle(color: Colors.red, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMaintenanceTools() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8, top: 24),
          child: Text(
            'Maintenance Tools',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.blue,
                ),
          ),
        ),
        CommonCard(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.build_circle, color: Colors.blue, size: 28),
                title: const Text(
                  'Fix Line Inconsistencies',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Fix issues where user line numbers don\'t match their maintenance payments and other records.',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  context.push(const FixLineInconsistenciesPage());
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _successMessage!,
              style: const TextStyle(color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshButton() {
    return Center(
      child: CommonButton(
        text: 'Return to Dashboard',
        onTap: () {
          // Pop back to the settings page first
          context.pop();
          // Then pop back to the dashboard
          context.pop();
        },
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.refresh),
      ),
    );
  }
}
