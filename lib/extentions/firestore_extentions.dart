import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:society_management/utility/app_typednfs.dart';

extension FirestoreExtentionsX on FirebaseFirestore {
  FireStoreCollectionRefrence get users => collection('users');
  FireStoreCollectionRefrence get expenses => collection('expenses');
  FireStoreCollectionRefrence get maintenance => collection('maintenance');
  FireStoreCollectionRefrence get dashboardStats => collection('dashboard_stats');
  FireStoreCollectionRefrence get activities => collection('activities');
}
