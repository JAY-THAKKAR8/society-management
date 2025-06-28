import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:society_management/broadcasting/model/broadcast_model.dart';
import 'package:society_management/broadcasting/repository/i_broadcast_repository.dart';
import 'package:society_management/utility/failure.dart';

/// Implementation of broadcast repository
@LazySingleton(as: IBroadcastRepository)
class BroadcastRepository implements IBroadcastRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _broadcastsCollection = 'broadcasts';
  static const String _usersCollection = 'users';
  static const String _broadcastReadsCollection = 'broadcast_reads';

  @override
  Future<Either<Failure, BroadcastModel>> createBroadcast({
    required String title,
    required String message,
    required BroadcastType type,
    required BroadcastPriority priority,
    required BroadcastTarget target,
    String? targetLineNumber,
    required String createdBy,
    required String creatorName,
    DateTime? scheduledAt,
    List<String> attachmentUrls = const [],
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      // Get recipient count
      final recipientsResult = await getBroadcastRecipients(
        target: target,
        targetLineNumber: targetLineNumber,
      );

      final totalRecipients = recipientsResult.fold(
        (failure) => 0,
        (recipients) => recipients.length,
      );

      final broadcast = BroadcastModel(
        title: title,
        message: message,
        type: type,
        priority: priority,
        target: target,
        targetLineNumber: targetLineNumber,
        createdBy: createdBy,
        creatorName: creatorName,
        createdAt: DateTime.now(),
        scheduledAt: scheduledAt,
        status: scheduledAt != null ? BroadcastStatus.scheduled : BroadcastStatus.draft,
        attachmentUrls: attachmentUrls,
        metadata: metadata,
        totalRecipients: totalRecipients,
      );

      final docRef = await _firestore.collection(_broadcastsCollection).add(broadcast.toFirestore());

      final createdBroadcast = broadcast.copyWith(id: docRef.id);

      log('Broadcast created successfully: ${docRef.id}');
      return Right(createdBroadcast);
    } catch (e) {
      log('Error creating broadcast: $e');
      return Left(Failure('Failed to create broadcast: $e'));
    }
  }

  @override
  Future<Either<Failure, List<BroadcastModel>>> getBroadcasts({
    BroadcastType? type,
    BroadcastPriority? priority,
    BroadcastTarget? target,
    BroadcastStatus? status,
    String? createdBy,
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(_broadcastsCollection);

      // Apply filters
      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }
      if (priority != null) {
        query = query.where('priority', isEqualTo: priority.name);
      }
      if (target != null) {
        query = query.where('target', isEqualTo: target.name);
      }
      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }
      if (createdBy != null) {
        query = query.where('created_by', isEqualTo: createdBy);
      }
      if (fromDate != null) {
        query = query.where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate));
      }
      if (toDate != null) {
        query = query.where('created_at', isLessThanOrEqualTo: Timestamp.fromDate(toDate));
      }

      // Order by creation date (newest first)
      query = query.orderBy('created_at', descending: true);

      // Apply limit
      if (limit != null) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.get();
      final broadcasts = querySnapshot.docs.map((doc) => BroadcastModel.fromFirestore(doc)).toList();

      return Right(broadcasts);
    } catch (e) {
      log('Error getting broadcasts: $e');
      return Left(Failure('Failed to get broadcasts: $e'));
    }
  }

  @override
  Future<Either<Failure, BroadcastModel>> getBroadcastById({
    required String broadcastId,
  }) async {
    try {
      final doc = await _firestore.collection(_broadcastsCollection).doc(broadcastId).get();

      if (!doc.exists) {
        return const Left(Failure('Broadcast not found'));
      }

      final broadcast = BroadcastModel.fromFirestore(doc);
      return Right(broadcast);
    } catch (e) {
      log('Error getting broadcast by ID: $e');
      return Left(Failure('Failed to get broadcast: $e'));
    }
  }

  @override
  Future<Either<Failure, BroadcastModel>> updateBroadcast({
    required String broadcastId,
    String? title,
    String? message,
    BroadcastType? type,
    BroadcastPriority? priority,
    BroadcastTarget? target,
    String? targetLineNumber,
    DateTime? scheduledAt,
    BroadcastStatus? status,
    List<String>? attachmentUrls,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (title != null) updateData['title'] = title;
      if (message != null) updateData['message'] = message;
      if (type != null) updateData['type'] = type.name;
      if (priority != null) updateData['priority'] = priority.name;
      if (target != null) updateData['target'] = target.name;
      if (targetLineNumber != null) updateData['target_line_number'] = targetLineNumber;
      if (scheduledAt != null) updateData['scheduled_at'] = Timestamp.fromDate(scheduledAt);
      if (status != null) updateData['status'] = status.name;
      if (attachmentUrls != null) updateData['attachment_urls'] = attachmentUrls;
      if (metadata != null) updateData['metadata'] = metadata;

      await _firestore.collection(_broadcastsCollection).doc(broadcastId).update(updateData);

      // Get updated broadcast
      final result = await getBroadcastById(broadcastId: broadcastId);
      return result;
    } catch (e) {
      log('Error updating broadcast: $e');
      return Left(Failure('Failed to update broadcast: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteBroadcast({
    required String broadcastId,
  }) async {
    try {
      await _firestore.collection(_broadcastsCollection).doc(broadcastId).delete();

      log('Broadcast deleted successfully: $broadcastId');
      return const Right(null);
    } catch (e) {
      log('Error deleting broadcast: $e');
      return Left(Failure('Failed to delete broadcast: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> sendBroadcast({
    required String broadcastId,
  }) async {
    try {
      await _firestore.collection(_broadcastsCollection).doc(broadcastId).update({
        'status': BroadcastStatus.sent.name,
        'sent_at': Timestamp.now(),
      });

      log('Broadcast sent successfully: $broadcastId');
      return const Right(null);
    } catch (e) {
      log('Error sending broadcast: $e');
      return Left(Failure('Failed to send broadcast: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> scheduleBroadcast({
    required String broadcastId,
    required DateTime scheduledAt,
  }) async {
    try {
      await _firestore.collection(_broadcastsCollection).doc(broadcastId).update({
        'scheduled_at': Timestamp.fromDate(scheduledAt),
        'status': BroadcastStatus.scheduled.name,
      });

      log('Broadcast scheduled successfully: $broadcastId');
      return const Right(null);
    } catch (e) {
      log('Error scheduling broadcast: $e');
      return Left(Failure('Failed to schedule broadcast: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> cancelBroadcast({
    required String broadcastId,
  }) async {
    try {
      await _firestore.collection(_broadcastsCollection).doc(broadcastId).update({
        'status': BroadcastStatus.cancelled.name,
        'cancelled_at': Timestamp.now(),
      });

      log('Broadcast cancelled successfully: $broadcastId');
      return const Right(null);
    } catch (e) {
      log('Error cancelling broadcast: $e');
      return Left(Failure('Failed to cancel broadcast: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getBroadcastStats({
    required String broadcastId,
  }) async {
    try {
      // Get broadcast details
      final broadcastResult = await getBroadcastById(broadcastId: broadcastId);
      if (broadcastResult.isLeft()) {
        return broadcastResult.fold(
          (failure) => Left(failure),
          (broadcast) => const Right({}),
        );
      }

      final broadcast = broadcastResult.getOrElse(() => throw Exception('Broadcast not found'));

      // Get read count
      final readSnapshot =
          await _firestore.collection(_broadcastReadsCollection).where('broadcast_id', isEqualTo: broadcastId).get();

      final stats = {
        'total_recipients': broadcast.totalRecipients,
        'delivered_count': broadcast.deliveredCount,
        'read_count': readSnapshot.docs.length,
        'delivery_rate': broadcast.totalRecipients > 0
            ? (broadcast.deliveredCount / broadcast.totalRecipients * 100).toStringAsFixed(1)
            : '0.0',
        'read_rate': broadcast.totalRecipients > 0
            ? (readSnapshot.docs.length / broadcast.totalRecipients * 100).toStringAsFixed(1)
            : '0.0',
      };

      return Right(stats);
    } catch (e) {
      log('Error getting broadcast stats: $e');
      return Left(Failure('Failed to get broadcast stats: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> markBroadcastAsRead({
    required String broadcastId,
    required String userId,
  }) async {
    try {
      await _firestore.collection(_broadcastReadsCollection).doc('${broadcastId}_$userId').set({
        'broadcast_id': broadcastId,
        'user_id': userId,
        'read_at': Timestamp.now(),
      });

      log('Broadcast marked as read: $broadcastId by $userId');
      return const Right(null);
    } catch (e) {
      log('Error marking broadcast as read: $e');
      return Left(Failure('Failed to mark broadcast as read: $e'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getBroadcastRecipients({
    required BroadcastTarget target,
    String? targetLineNumber,
  }) async {
    try {
      Query query = _firestore.collection(_usersCollection);

      switch (target) {
        case BroadcastTarget.all:
          // No additional filter needed
          break;
        case BroadcastTarget.line:
          if (targetLineNumber != null) {
            query = query.where('line_number', isEqualTo: targetLineNumber);
          }
          break;
        case BroadcastTarget.admins:
          query = query.where('role', whereIn: ['admin', 'admins']);
          break;
        case BroadcastTarget.lineHeads:
          query = query.where('role', whereIn: ['line_head', 'line head']);
          break;
        case BroadcastTarget.members:
          query = query.where('role', whereIn: ['line_member', 'member']);
          break;
      }

      final querySnapshot = await query.get();
      final userIds = querySnapshot.docs.map((doc) => doc.id).toList();

      return Right(userIds);
    } catch (e) {
      log('Error getting broadcast recipients: $e');
      return Left(Failure('Failed to get broadcast recipients: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateDeliveryStatus({
    required String broadcastId,
    required int deliveredCount,
    required int readCount,
  }) async {
    try {
      await _firestore.collection(_broadcastsCollection).doc(broadcastId).update({
        'delivered_count': deliveredCount,
        'read_count': readCount,
        'last_updated': Timestamp.now(),
      });

      return const Right(null);
    } catch (e) {
      log('Error updating delivery status: $e');
      return Left(Failure('Failed to update delivery status: $e'));
    }
  }

  @override
  Future<Either<Failure, List<BroadcastModel>>> getRecentBroadcasts({
    int limit = 10,
  }) async {
    return getBroadcasts(limit: limit);
  }

  @override
  Future<Either<Failure, List<BroadcastModel>>> searchBroadcasts({
    required String query,
    BroadcastType? type,
    BroadcastPriority? priority,
    int? limit,
  }) async {
    try {
      Query firestoreQuery = _firestore.collection(_broadcastsCollection);

      // Apply filters
      if (type != null) {
        firestoreQuery = firestoreQuery.where('type', isEqualTo: type.name);
      }
      if (priority != null) {
        firestoreQuery = firestoreQuery.where('priority', isEqualTo: priority.name);
      }

      // Order by creation date
      firestoreQuery = firestoreQuery.orderBy('created_at', descending: true);

      // Apply limit
      if (limit != null) {
        firestoreQuery = firestoreQuery.limit(limit);
      }

      final querySnapshot = await firestoreQuery.get();
      final broadcasts = querySnapshot.docs
          .map((doc) => BroadcastModel.fromFirestore(doc))
          .where((broadcast) =>
              broadcast.title.toLowerCase().contains(query.toLowerCase()) ||
              broadcast.message.toLowerCase().contains(query.toLowerCase()))
          .toList();

      return Right(broadcasts);
    } catch (e) {
      log('Error searching broadcasts: $e');
      return Left(Failure('Failed to search broadcasts: $e'));
    }
  }

  @override
  Future<Either<Failure, List<BroadcastModel>>> getUserBroadcasts({
    required String userId,
    BroadcastType? type,
    bool? isRead,
    int? limit,
  }) async {
    try {
      // This is a simplified implementation
      // In a real app, you'd need to implement proper user-specific broadcast filtering
      return getBroadcasts(type: type, limit: limit);
    } catch (e) {
      log('Error getting user broadcasts: $e');
      return Left(Failure('Failed to get user broadcasts: $e'));
    }
  }
}
