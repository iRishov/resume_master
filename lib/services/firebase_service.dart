import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<String> uploadImage(File imageFile, String userId) async {
    try {
      final ref = _storage.ref().child('profile_images/$userId.jpg');
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  static Future<void> saveResume({
    required String userId,
    required Map<String, dynamic> resumeData,
  }) async {
    try {
      await _firestore.collection('resumes').doc(userId).set(resumeData);
    } catch (e) {
      throw Exception('Failed to save resume: $e');
    }
  }
} 