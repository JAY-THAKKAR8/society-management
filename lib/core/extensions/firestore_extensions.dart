import 'package:cloud_firestore/cloud_firestore.dart';

/// Extension to add convenient collection references to FirebaseFirestore
extension FirestoreExtensions on FirebaseFirestore {
  /// Reference to the users collection
  CollectionReference<Map<String, dynamic>> get users => collection('users');

  /// Reference to the meetings collection
  CollectionReference<Map<String, dynamic>> get meetings => collection('meetings');

  /// Reference to the maintenance_periods collection
  CollectionReference<Map<String, dynamic>> get maintenancePeriods => collection('maintenance_periods');

  /// Reference to the maintenance_payments collection
  CollectionReference<Map<String, dynamic>> get maintenancePayments => collection('maintenance_payments');

  /// Reference to the complaints collection
  CollectionReference<Map<String, dynamic>> get complaints => collection('complaints');

  /// Reference to the events collection
  CollectionReference<Map<String, dynamic>> get events => collection('events');

  /// Reference to the dashboard_stats collection
  CollectionReference<Map<String, dynamic>> get dashboardStats => collection('dashboard_stats');

  /// Reference to the chat_messages collection
  CollectionReference<Map<String, dynamic>> get chatMessages => collection('chat_messages');
}
