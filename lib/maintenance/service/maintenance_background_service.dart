import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:society_management/maintenance/service/auto_maintenance_service.dart';
import 'package:society_management/utility/utility.dart';

/// Service for running maintenance-related background tasks
class MaintenanceBackgroundService {
  static final MaintenanceBackgroundService _instance = MaintenanceBackgroundService._internal();
  factory MaintenanceBackgroundService() => _instance;

  MaintenanceBackgroundService._internal();

  Timer? _dailyCheckTimer;
  bool _isInitialized = false;

  /// Initialize the background service
  void initialize() {
    if (_isInitialized) return;

    _isInitialized = true;

    // Run immediately on startup
    _checkForAutomaticPeriodCreation();

    // Schedule daily check
    _scheduleDailyCheck();
  }

  /// Force an immediate check for maintenance period creation
  /// This can be called manually to trigger the check
  Future<void> forceCheck() async {
    if (kDebugMode) {
      print('Forcing maintenance period check...');
    }
    await _checkForAutomaticPeriodCreation();
  }

  /// Schedule a daily check for automatic period creation
  void _scheduleDailyCheck() {
    // Cancel any existing timer
    _dailyCheckTimer?.cancel();

    // Calculate time until next check (midnight)
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final timeUntilMidnight = nextMidnight.difference(now);

    // Schedule the first check at midnight
    _dailyCheckTimer = Timer(timeUntilMidnight, () {
      // Run the check
      _checkForAutomaticPeriodCreation();

      // Then schedule daily checks every 24 hours
      _dailyCheckTimer = Timer.periodic(const Duration(days: 1), (_) {
        _checkForAutomaticPeriodCreation();
      });
    });
  }

  /// Check if it's time to create a new maintenance period
  Future<void> _checkForAutomaticPeriodCreation() async {
    try {
      final autoService = AutoMaintenanceService();
      final result = await autoService.checkAndCreatePeriod();

      result.fold(
        (failure) {
          if (kDebugMode) {
            print('Error in automatic maintenance period creation: ${failure.message}');
          }
        },
        (period) {
          if (period != null) {
            Utility.toast(
              message: 'New maintenance period automatically created for ${period.name}',
            );
            if (kDebugMode) {
              print('Automatically created maintenance period: ${period.name}');
            }
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Exception in automatic maintenance period check: $e');
      }
    }
  }

  /// Dispose the service
  void dispose() {
    _dailyCheckTimer?.cancel();
    _isInitialized = false;
  }
}
