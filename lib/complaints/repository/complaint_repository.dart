import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as path;
import 'package:society_management/complaints/model/complaint_model.dart';
import 'package:society_management/complaints/repository/i_complaint_repository.dart';
import 'package:society_management/extentions/firestore_extentions.dart';
import 'package:society_management/utility/app_typednfs.dart';
import 'package:society_management/utility/result.dart';

@Injectable(as: IComplaintRepository)
class ComplaintRepository extends IComplaintRepository {
  ComplaintRepository(super.firestore);

  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Helper method to convert status enum to string
  String _statusToString(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.pending:
        return 'pending';
      case ComplaintStatus.inProgress:
        return 'in_progress';
      case ComplaintStatus.resolved:
        return 'resolved';
      case ComplaintStatus.rejected:
        return 'rejected';
    }
  }

  @override
  FirebaseResult<String> uploadComplaintImage(String userId, String filePath) {
    return Result<String>().tryCatch(
      run: () async {
        final File file = File(filePath);
        final fileName = path.basename(file.path);
        final destination = 'complaints/$userId/${DateTime.now().millisecondsSinceEpoch}_$fileName';

        final ref = _storage.ref().child(destination);
        final uploadTask = ref.putFile(file);
        final snapshot = await uploadTask;

        // Get download URL
        final downloadUrl = await snapshot.ref.getDownloadURL();
        return downloadUrl;
      },
    );
  }

  @override
  FirebaseResult<ComplaintModel> addComplaint({
    required String userId,
    required String userName,
    required String? userVillaNumber,
    required String? userLineNumber,
    required String title,
    required String description,
    String? imageUrl,
  }) {
    return Result<ComplaintModel>().tryCatch(
      run: () async {
        final now = Timestamp.now();

        // Create a new complaints collection if it doesn't exist
        final complaintsCollection = firestore.collection('complaints');
        final complaintDoc = complaintsCollection.doc();

        final complaint = {
          'id': complaintDoc.id,
          'user_id': userId,
          'user_name': userName,
          'user_villa_number': userVillaNumber,
          'user_line_number': userLineNumber,
          'title': title,
          'description': description,
          'status': 'pending',
          'admin_response': null,
          'image_url': imageUrl,
          'created_at': now,
          'updated_at': now,
        };

        await complaintDoc.set(complaint);

        // Log activity
        final activityDoc = firestore.activities.doc();
        await activityDoc.set({
          'id': activityDoc.id,
          'message': '📝 New complaint submitted by $userName: $title',
          'type': 'complaint',
          'timestamp': now,
        });

        return ComplaintModel.fromJson(complaint);
      },
    );
  }

  @override
  FirebaseResult<List<ComplaintModel>> getAllComplaints() {
    return Result<List<ComplaintModel>>().tryCatch(
      run: () async {
        final complaintsSnapshot =
            await firestore.collection('complaints').orderBy('created_at', descending: true).get();

        final complaints = complaintsSnapshot.docs.map((doc) => ComplaintModel.fromJson(doc.data())).toList();

        return complaints;
      },
    );
  }

  @override
  FirebaseResult<List<ComplaintModel>> getComplaintsForUser({
    required String userId,
  }) {
    return Result<List<ComplaintModel>>().tryCatch(
      run: () async {
        final complaintsSnapshot = await firestore
            .collection('complaints')
            .where('user_id', isEqualTo: userId)
            .orderBy('created_at', descending: true)
            .get();

        final complaints = complaintsSnapshot.docs.map((doc) => ComplaintModel.fromJson(doc.data())).toList();

        return complaints;
      },
    );
  }

  @override
  FirebaseResult<ComplaintModel> updateComplaintStatus({
    required String complaintId,
    required ComplaintStatus status,
    String? adminResponse,
  }) {
    return Result<ComplaintModel>().tryCatch(
      run: () async {
        final now = Timestamp.now();
        final complaintRef = firestore.collection('complaints').doc(complaintId);
        final complaintDoc = await complaintRef.get();

        if (!complaintDoc.exists) {
          throw Exception('Complaint not found');
        }

        final updateData = {
          'status': _statusToString(status),
          'updated_at': now,
        };

        if (adminResponse != null) {
          updateData['admin_response'] = adminResponse;
        }

        await complaintRef.update(updateData);

        // Log activity
        final activityDoc = firestore.activities.doc();
        final complaintData = complaintDoc.data()!;
        final userName = complaintData['user_name'] as String?;
        final title = complaintData['title'] as String?;

        await activityDoc.set({
          'id': activityDoc.id,
          'message': '🔄 Complaint status updated to ${_statusToString(status)}: $title by $userName',
          'type': 'complaint_update',
          'timestamp': now,
        });

        // Get updated complaint
        final updatedDoc = await complaintRef.get();
        return ComplaintModel.fromJson(updatedDoc.data()!);
      },
    );
  }

  @override
  FirebaseResult<ComplaintModel> updateComplaint(ComplaintModel complaint) {
    return Result<ComplaintModel>().tryCatch(
      run: () async {
        if (complaint.id == null) {
          throw Exception('Complaint ID cannot be null');
        }

        final now = Timestamp.now();
        final complaintRef = firestore.collection('complaints').doc(complaint.id);
        final complaintDoc = await complaintRef.get();

        if (!complaintDoc.exists) {
          throw Exception('Complaint not found');
        }

        // Convert the complaint to JSON and update the timestamp
        final updateData = complaint.toJson();
        updateData['updated_at'] = now;

        await complaintRef.update(updateData);

        // Log activity
        final activityDoc = firestore.activities.doc();
        final statusMessage = complaint.statusDisplayName;

        await activityDoc.set({
          'id': activityDoc.id,
          'message': '🔄 Complaint updated to $statusMessage: ${complaint.title} by ${complaint.userName}',
          'type': 'complaint_update',
          'timestamp': now,
        });

        // Get updated complaint
        final updatedDoc = await complaintRef.get();
        return ComplaintModel.fromJson(updatedDoc.data()!);
      },
    );
  }
}
