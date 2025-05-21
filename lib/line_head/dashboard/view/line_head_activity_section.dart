import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:society_management/dashboard/model/activity_model.dart';
import 'package:society_management/extentions/firestore_extentions.dart';
import 'package:society_management/line_head/dashboard/view/recent_activity_item.dart';

class LineHeadActivitySection extends StatefulWidget {
  final String? lineNumber;

  const LineHeadActivitySection({
    super.key,
    this.lineNumber,
  });

  @override
  LineHeadActivitySectionState createState() => LineHeadActivitySectionState();
}

class LineHeadActivitySectionState extends State<LineHeadActivitySection> {
  List<ActivityModel>? _activities;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchActivities();
  }

  // Public method to refresh activities from outside
  void refreshActivities() {
    _fetchActivities();
  }

  Future<void> _fetchActivities() async {
    if (widget.lineNumber == null) {
      setState(() {
        _isLoading = false;
        _activities = [];
        _errorMessage = 'Line number not provided';
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Add a delay to ensure the loading state is visible
      await Future.delayed(const Duration(milliseconds: 500));

      // Fetch line-specific activities from Firestore with timeout
      final activitiesSnapshot = await FirebaseFirestore.instance.activities
          .where('line_number', isEqualTo: widget.lineNumber)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get()
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw 'Connection timeout. Please check your internet connection.';
        },
      );

      // If no line-specific activities, show empty state
      if (activitiesSnapshot.docs.isEmpty) {
        if (mounted) {
          setState(() {
            _activities = [];
            _isLoading = false;
          });
        }
        return;
      }

      final activities = activitiesSnapshot.docs.map((doc) {
        try {
          return ActivityModel.fromJson(doc.data());
        } catch (e) {
          return ActivityModel(
            id: doc.id,
            message: 'Activity data error',
            type: 'error',
            timestamp: DateTime.now(),
          );
        }
      }).toList();

      if (mounted) {
        setState(() {
          _activities = activities;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
        // Error is already handled in the UI
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Line Activity",
              style: theme.textTheme.titleLarge,
            ),
            if (_isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _fetchActivities,
                tooltip: 'Refresh activities',
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_errorMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  "Error loading activities",
                  style: theme.textTheme.titleMedium?.copyWith(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage ?? "Please try again",
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _fetchActivities,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Retry', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          )
        else if (_activities == null || _activities!.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.event_note,
                  color: Colors.grey,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  "No Recent Activities",
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "There are no recent activities for your line",
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _fetchActivities,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Refresh', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          )
        else
          ...(_activities ?? []).map(
            (activity) => RecentActivityItem(activity: activity.message ?? 'Unknown activity'),
          ),
      ],
    );
  }
}
