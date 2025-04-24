import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:society_management/complaints/model/complaint_model.dart';
import 'package:society_management/utility/app_typednfs.dart';

abstract class IComplaintRepository {
  IComplaintRepository(this.firestore);
  
  final FirebaseFirestore firestore;

  /// Add a new complaint
  FirebaseResult<ComplaintModel> addComplaint({
    required String userId,
    required String userName,
    required String? userVillaNumber,
    required String? userLineNumber,
    required String title,
    required String description,
  });

  /// Get all complaints
  FirebaseResult<List<ComplaintModel>> getAllComplaints();

  /// Get complaints for a specific user
  FirebaseResult<List<ComplaintModel>> getComplaintsForUser({
    required String userId,
  });

  /// Update complaint status
  FirebaseResult<ComplaintModel> updateComplaintStatus({
    required String complaintId,
    required ComplaintStatus status,
    String? adminResponse,
  });
}
