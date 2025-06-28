import 'package:dartz/dartz.dart';
import 'package:society_management/broadcasting/model/broadcast_model.dart';
import 'package:society_management/utility/failure.dart';

/// Interface for broadcast repository
abstract class IBroadcastRepository {
  /// Create a new broadcast message
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
  });

  /// Get all broadcasts with optional filtering
  Future<Either<Failure, List<BroadcastModel>>> getBroadcasts({
    BroadcastType? type,
    BroadcastPriority? priority,
    BroadcastTarget? target,
    BroadcastStatus? status,
    String? createdBy,
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
  });

  /// Get broadcast by ID
  Future<Either<Failure, BroadcastModel>> getBroadcastById({
    required String broadcastId,
  });

  /// Update broadcast
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
  });

  /// Delete broadcast
  Future<Either<Failure, void>> deleteBroadcast({
    required String broadcastId,
  });

  /// Send broadcast immediately
  Future<Either<Failure, void>> sendBroadcast({
    required String broadcastId,
  });

  /// Schedule broadcast for later
  Future<Either<Failure, void>> scheduleBroadcast({
    required String broadcastId,
    required DateTime scheduledAt,
  });

  /// Cancel scheduled broadcast
  Future<Either<Failure, void>> cancelBroadcast({
    required String broadcastId,
  });

  /// Get broadcast statistics
  Future<Either<Failure, Map<String, dynamic>>> getBroadcastStats({
    required String broadcastId,
  });

  /// Mark broadcast as read by user
  Future<Either<Failure, void>> markBroadcastAsRead({
    required String broadcastId,
    required String userId,
  });

  /// Get user's broadcast history
  Future<Either<Failure, List<BroadcastModel>>> getUserBroadcasts({
    required String userId,
    BroadcastType? type,
    bool? isRead,
    int? limit,
  });

  /// Get broadcast recipients
  Future<Either<Failure, List<String>>> getBroadcastRecipients({
    required BroadcastTarget target,
    String? targetLineNumber,
  });

  /// Update broadcast delivery status
  Future<Either<Failure, void>> updateDeliveryStatus({
    required String broadcastId,
    required int deliveredCount,
    required int readCount,
  });

  /// Get recent broadcasts for dashboard
  Future<Either<Failure, List<BroadcastModel>>> getRecentBroadcasts({
    int limit = 10,
  });

  /// Search broadcasts
  Future<Either<Failure, List<BroadcastModel>>> searchBroadcasts({
    required String query,
    BroadcastType? type,
    BroadcastPriority? priority,
    int? limit,
  });
}
