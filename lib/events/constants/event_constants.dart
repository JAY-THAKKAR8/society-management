/// Constants for event categories and statuses
class EventConstants {
  // Event categories
  static const String categoryMeeting = 'Meeting';
  static const String categoryCelebration = 'Celebration';
  static const String categoryMaintenance = 'Maintenance';
  static const String categoryEmergency = 'Emergency';
  static const String categoryGeneral = 'General';
  static const String categoryOther = 'Other';

  // Event statuses
  static const String statusUpcoming = 'upcoming';
  static const String statusOngoing = 'ongoing';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';

  // Event approval statuses
  static const String approvalPending = 'pending';
  static const String approvalApproved = 'approved';
  static const String approvalRejected = 'rejected';

  // Event visibility options
  static const String visibilitySociety = 'society'; // Visible to all society members
  static const String visibilityLine = 'line'; // Visible only to members of a specific line
  static const String visibilityPrivate = 'private'; // Visible only to creator and attendees

  // Recurring patterns
  static const String recurringDaily = 'daily';
  static const String recurringWeekly = 'weekly';
  static const String recurringMonthly = 'monthly';
  static const String recurringYearly = 'yearly';

  // Get all event categories
  static List<String> get allCategories => [
        categoryMeeting,
        categoryCelebration,
        categoryMaintenance,
        categoryEmergency,
        categoryGeneral,
        categoryOther,
      ];

  // Get all event statuses
  static List<String> get allStatuses => [
        statusUpcoming,
        statusOngoing,
        statusCompleted,
        statusCancelled,
      ];

  // Get all recurring patterns
  static List<String> get allRecurringPatterns => [
        recurringDaily,
        recurringWeekly,
        recurringMonthly,
        recurringYearly,
      ];

  // Get all approval statuses
  static List<String> get allApprovalStatuses => [
        approvalPending,
        approvalApproved,
        approvalRejected,
      ];

  // Get all visibility options
  static List<String> get allVisibilityOptions => [
        visibilitySociety,
        visibilityLine,
        visibilityPrivate,
      ];

  // Get color for event category
  static int getCategoryColor(String category) {
    switch (category) {
      case categoryMeeting:
        return 0xFF2196F3; // Blue
      case categoryCelebration:
        return 0xFFE91E63; // Pink
      case categoryMaintenance:
        return 0xFF4CAF50; // Green
      case categoryEmergency:
        return 0xFFF44336; // Red
      case categoryGeneral:
        return 0xFF9C27B0; // Purple
      case categoryOther:
        return 0xFF607D8B; // Blue Grey
      default:
        return 0xFF9E9E9E; // Grey
    }
  }

  // Get icon for event category
  static String getCategoryIcon(String category) {
    switch (category) {
      case categoryMeeting:
        return 'group';
      case categoryCelebration:
        return 'celebration';
      case categoryMaintenance:
        return 'build';
      case categoryEmergency:
        return 'warning';
      case categoryGeneral:
        return 'event';
      case categoryOther:
        return 'more_horiz';
      default:
        return 'event';
    }
  }
}
