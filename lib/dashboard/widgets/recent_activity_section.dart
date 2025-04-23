import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:society_management/dashboard/model/activity_model.dart';
import 'package:society_management/dashboard/widgets/recent_activity_item.dart';
import 'package:society_management/extentions/firestore_extentions.dart';

class RecentActivitySection extends StatefulWidget {
  const RecentActivitySection({super.key});

  @override
  RecentActivitySectionState createState() => RecentActivitySectionState();
}

class RecentActivitySectionState extends State<RecentActivitySection> {
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
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Fetch recent activities from Firestore
      final activitiesSnapshot =
          await FirebaseFirestore.instance.activities.orderBy('timestamp', descending: true).limit(5).get();

      if (activitiesSnapshot.docs.isEmpty) {
        setState(() {
          _activities = [];
          _isLoading = false;
        });
        return;
      }

      final activities = activitiesSnapshot.docs.map((doc) {
        try {
          return ActivityModel.fromJson(doc.data());
        } catch (e) {
          // If there's an error parsing a specific activity, create a fallback one
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
              "Recent Activity",
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
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    "Error loading activities",
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _fetchActivities,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          )
        else if (_activities == null || _activities!.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "No recent activities",
                style: theme.textTheme.bodyMedium,
              ),
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
