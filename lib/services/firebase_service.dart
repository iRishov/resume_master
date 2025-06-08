// ignore_for_file: unnecessary_import

import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  User? get currentUser => _auth.currentUser;

  // User Management
  Future<void> addUserToDatabase(
    User user, {
    String? role,
    String? name,
  }) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'name': name ?? user.displayName,
        'photoUrl': user.photoURL,
        'role': role ?? 'job_seeker', // Default to job seeker if not specified
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
      // Validate user exists
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      // Validate required fields
      if (!resumeData.containsKey('personalInfo')) {
        throw Exception('Resume must contain personal information');
      }

      // Add metadata
      final data = {
        ...resumeData,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Save to Firestore
      await _firestore.collection('resumes').add(data);
    } on FirebaseException catch (e) {
      debugPrint('Firebase error saving resume: ${e.code} - ${e.message}');
      throw Exception('Firebase error: ${getErrorMessage(e)}');
    } catch (e) {
      debugPrint('Error saving resume: $e');
      throw Exception('Failed to save resume: $e');
    }
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getUserResumes(
    String userId,
  ) async {
    try {
      // First check if the user exists
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      // Then fetch resumes with proper error handling
      final snapshot =
          await _firestore
              .collection('resumes')
              .where('userId', isEqualTo: userId)
              .get();

      // Validate the data
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (!data.containsKey('userId') || data['userId'] != userId) {
          debugPrint('Warning: Resume ${doc.id} has invalid userId');
        }
        if (!data.containsKey('updatedAt')) {
          debugPrint('Warning: Resume ${doc.id} missing updatedAt field');
        }
      }

      return snapshot;
    } on FirebaseException catch (e) {
      debugPrint('Firebase error fetching resumes: ${e.code} - ${e.message}');
      throw Exception('Firebase error: ${getErrorMessage(e)}');
    } catch (e) {
      debugPrint('Error fetching resumes: $e');
      throw Exception('Failed to fetch resumes: $e');
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getResume(
    String resumeId,
  ) async {
    try {
      return await _firestore.collection('resumes').doc(resumeId).get();
    } catch (e) {
      throw Exception('Failed to fetch resume: $e');
    }
  }

  Future<void> updateResume(String resumeId, Map<String, dynamic> data) async {
    try {
      // Validate resume exists
      final resumeDoc =
          await _firestore.collection('resumes').doc(resumeId).get();
      if (!resumeDoc.exists) {
        throw Exception('Resume not found');
      }

      // Add update timestamp
      final updateData = {...data, 'updatedAt': FieldValue.serverTimestamp()};

      // Update in Firestore
      await _firestore.collection('resumes').doc(resumeId).update(updateData);
    } on FirebaseException catch (e) {
      debugPrint('Firebase error updating resume: ${e.code} - ${e.message}');
      throw Exception('Firebase error: ${getErrorMessage(e)}');
    } catch (e) {
      debugPrint('Error updating resume: $e');
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

  // Function to delete only the user's resumes
  Future<void> deleteAllResumes(String userId) async {
    try {
      final userResumes =
          await _firestore
              .collection('resumes')
              .where('userId', isEqualTo: userId)
              .get();

      debugPrint(
        'Attempting to delete ${userResumes.docs.length} resumes for user $userId',
      );
      if (userResumes.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (var doc in userResumes.docs) {
          debugPrint('Adding resume ${doc.id} to batch for deletion.');
          batch.delete(doc.reference);
        }
        await batch.commit();
        debugPrint('Batch delete of resumes committed.');
      } else {
        debugPrint('No resumes found for user $userId to delete.');
      }
    } on FirebaseException catch (e) {
      debugPrint(
        'Firebase error deleting all resumes: ${e.code} - ${e.message}',
      );
      throw Exception('Firebase error deleting resumes: ${getErrorMessage(e)}');
    } catch (e) {
      debugPrint('Error deleting all resumes: $e');
      throw Exception('Failed to delete all resumes: $e');
    }
  }

  // File Storage
  Future<String> uploadImage(File imageFile, String userId) async {
    try {
      // Validate file exists
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }

      // Validate file size (max 5MB)
      final fileSize = await imageFile.length();
      if (fileSize > 5 * 1024 * 1024) {
        throw Exception('Image file size must be less than 5MB');
      }

      // Create storage reference with proper path
      final storageRef = _storage.ref();
      final profileImagesRef = storageRef.child('profile_images');
      final userRef = profileImagesRef.child(userId);
      final imageRef = userRef.child(
        '${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      debugPrint('Uploading image to path: ${imageRef.fullPath}');

      // Set metadata for better organization
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'userId': userId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // Upload file with metadata
      final uploadTask = await imageRef.putFile(imageFile, metadata);
      debugPrint(
        'Upload completed. Bytes transferred: ${uploadTask.bytesTransferred}',
      );

      // Get download URL
      final downloadUrl = await imageRef.getDownloadURL();
      debugPrint('Download URL obtained: $downloadUrl');

      if (downloadUrl.isEmpty) {
        throw Exception('Failed to get download URL for uploaded image');
      }

      return downloadUrl;
    } on FirebaseException catch (e) {
      debugPrint('Firebase error during upload: ${e.code} - ${e.message}');
      throw Exception('Firebase error: ${getErrorMessage(e)}');
    } catch (e) {
      debugPrint('Error uploading image: $e');
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
