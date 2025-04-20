import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:injectable/injectable.dart';

@module
abstract class FirebaseInjectableModule {
  @lazySingleton
  FirebaseFirestore get firestore => FirebaseFirestore.instance;
}

@module
abstract class FirebaseAuthInjectableModule {
  @lazySingleton
  FirebaseAuth get firestoreAuth => FirebaseAuth.instance;
}

@module
abstract class FirebaseStorageInjectableModule {
  @lazySingleton
  FirebaseStorage get firestoreStorage => FirebaseStorage.instance;
}

@module
abstract class FirebaseFunctionsInjectableModule {
  @lazySingleton
  FirebaseFunctions get firestoreStorage => FirebaseFunctions.instance;
}
