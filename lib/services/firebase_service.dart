// ignore_for_file: unnecessary_import

import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  User? get currentUser => _auth.currentUser;

  // User Management
  Future<void> addUserToDatabase(User user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'name': user.displayName,
        'photoUrl': user.photoURL,
        'lastSignInTime': DateTime.now(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to add user to database: $e');
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserData(String uid) async {
    try {
      return await _firestore.collection('users').doc(uid).get();
    } catch (e) {
      throw Exception('Failed to fetch user data: $e');
    }
  }

  Future<void> updateUserField(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user field: $e');
    }
  }

  // Resume Management
  Future<void> saveResumeData(
    String userId,
    Map<String, dynamic> resumeData,
  ) async {
    try {
      await _firestore.collection('resumes').add({
        ...resumeData,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to save resume data: $e');
    }
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getUserResumes(
    String userId,
  ) async {
    try {
      return await _firestore
          .collection('resumes')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
    } catch (e) {
      throw Exception('Failed to fetch user resumes: $e');
    }
  }

  Future<void> updateResume(String resumeId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('resumes').doc(resumeId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update resume: $e');
    }
  }

  Future<void> deleteResume(String resumeId) async {
    try {
      await _firestore.collection('resumes').doc(resumeId).delete();
    } catch (e) {
      throw Exception('Failed to delete resume: $e');
    }
  }

  // File Storage
  Future<String> uploadImage(File imageFile, String userId) async {
    try {
      final ref = _storage.ref().child(
        'profile_images/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      final uploadTask = await ref.putFile(imageFile);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<String> uploadResumeFile(
    File file,
    String userId,
    String resumeId,
  ) async {
    try {
      final ref = _storage.ref().child(
        'resumes/$userId/$resumeId/${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      final uploadTask = await ref.putFile(file);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload resume file: $e');
    }
  }

  Future<void> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  // Error Handling
  String getErrorMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'You don\'t have permission to perform this action';
      case 'not-found':
        return 'The requested resource was not found';
      case 'already-exists':
        return 'A resource with this ID already exists';
      case 'failed-precondition':
        return 'Operation cannot be performed in the current state';
      case 'aborted':
        return 'Operation was aborted';
      case 'unavailable':
        return 'Service is currently unavailable';
      default:
        return 'An error occurred: ${e.message}';
    }
  }
}
