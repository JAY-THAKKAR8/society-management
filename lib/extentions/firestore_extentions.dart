import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:society_management/utility/app_typednfs.dart';

extension FirestoreExtentionsX on FirebaseFirestore {
  FireStoreCollectionRefrence get users => collection('users');
  FireStoreCollectionRefrence get expenses => collection('expenses');
  FireStoreCollectionRefrence get maintenance => collection('maintenance');
  FireStoreCollectionRefrence get maintenancePayments => collection('maintenance_payments');
  FireStoreCollectionRefrence get dashboardStats => collection('dashboard_stats');
  FireStoreCollectionRefrence get activities => collection('activities');
  FireStoreCollectionRefrence get complaints => collection('complaints');
  FireStoreCollectionRefrence get events => collection('events');
  FireStoreCollectionRefrence get adminDashboardStats => collection('admin_dashboard_stats');
  FireStoreCollectionRefrence get lineHeadDashboardStats => collection('line_head_dashboard_stats');
  FireStoreCollectionRefrence get userSpecificStats => collection('user_specific_stats');
}
