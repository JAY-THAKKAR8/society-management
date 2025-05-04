import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
        'maintenance_periods',
        'maintenance_payments',
        'expenses',
        'expense_categories',
        'complaints',
        'activities',
        'notifications',
        'dashboard_stats',
        'dashboard_counts',
        'dashboard_data',
        'stats',
        'counts',
        'summary_data',
        'line_stats',
        'user_stats',
        'expense_stats',
        'maintenance_stats',
        // Add any other collections you want to clear
      ];

      // Delete all documents in each collection
      for (final collectionName in collections) {
        final querySnapshot = await firestore.collection(collectionName).get();

        for (final doc in querySnapshot.docs) {
          await doc.reference.delete();
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
