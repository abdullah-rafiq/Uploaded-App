import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import 'cloudinary_service.dart';

class UserService {
  UserService._();

  static final UserService instance = UserService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('users');

  Future<AppUser?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.id, doc.data()!);
  }

  Future<void> updateUser(String id, Map<String, dynamic> data) {
    return _col.doc(id).set(data, SetOptions(merge: true));
  }

  Future<void> addToWallet(String id, num amount) {
    return _col.doc(id).update({
      'walletBalance': FieldValue.increment(amount),
    });
  }

  Future<CloudinaryUploadResult> uploadProfileImage(
      String uid, Uint8List bytes, String fileName) async {
    final result = await CloudinaryService.instance.uploadImage(
      bytes: bytes,
      folder: 'user_profile_images',
      publicId: uid,
      fileName: fileName,
    );
    return result;
  }

  Future<void> updateProfileImageUrl(String uid, String url) {
    return updateUser(uid, {'profileImageUrl': url});
  }

  Stream<AppUser?> watchUser(String id) {
    return _col.doc(id).snapshots().map((snap) {
      if (!snap.exists) return null;
      return AppUser.fromMap(snap.id, snap.data()!);
    });
  }
}
