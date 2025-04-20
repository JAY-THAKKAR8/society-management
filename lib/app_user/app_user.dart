// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  const AppUser({
    this.id,
    this.companyName,
    this.companyEmail,
    this.companyMobile,
    this.fcmTokens = const <String>[],
    this.profilePhoto,
    this.documentSnapshot,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String?,
      companyName: json['company_name'] as String?,
      companyEmail: json['company_email'] as String?,
      companyMobile: json['company_mobile'] as String?,
      profilePhoto: json['profile_photo'] as Uint8List?,
      fcmTokens: (json['fcm_tokens'] as List<dynamic>?)?.cast<String>() ?? <String>[],
      documentSnapshot: json['documentSnapshot'] as DocumentSnapshot<Object?>?,
    );
  }

  factory AppUser.empty() => const AppUser();

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return AppUser.fromJson(doc.data()!).copyWith(
      id: doc.id,
      documentSnapshot: doc,
    );
  }

  final String? id;
  final String? companyName;
  final String? companyEmail;
  final String? companyMobile;
  final Uint8List? profilePhoto;
  final List<String> fcmTokens;
  final DocumentSnapshot? documentSnapshot;

  AppUser copyWith({
    String? id,
    String? companyName,
    String? companyEmail,
    String? companyMobile,
    Uint8List? profilePhoto,
    List<String>? fcmTokens,
    DocumentSnapshot? documentSnapshot,
  }) {
    return AppUser(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      companyEmail: companyEmail ?? this.companyEmail,
      companyMobile: companyMobile ?? this.companyMobile,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      fcmTokens: fcmTokens ?? this.fcmTokens,
      documentSnapshot: documentSnapshot ?? this.documentSnapshot,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'company_name': companyName,
        'company_email': companyEmail,
        'profile_photo': profilePhoto,
        'company_mobile': companyMobile,
        'fcm_tokens': fcmTokens,
      };

  @override
  List<Object?> get props {
    return [
      id,
      companyName,
      companyEmail,
      companyMobile,
      profilePhoto,
      fcmTokens,
      documentSnapshot,
    ];
  }
}
