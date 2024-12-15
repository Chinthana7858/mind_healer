import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mind_healer/views/other/first_screen.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>;
      } else {
        return await getPsychiatristData(userId);
      }
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getPsychiatristData(String userId) async {
    try {
      final DocumentSnapshot userDoc =
          await _firestore.collection('psychiatrists').doc(userId).get();
      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>;
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching psychiatrist data: $e');
      return null;
    }
  }

  Stream<QuerySnapshot> getPsychiatrists() {
    return _firestore.collection('psychiatrists').snapshots();
  }

  Stream<QuerySnapshot> getSpecialistPsychiatrists() {
    return _firestore
        .collection('psychiatrists')
        .where('specialist', isEqualTo: 'true')
        .snapshots();
  }

  Stream<QuerySnapshot> getNonSpecialistPsychiatrists() {
    return _firestore
        .collection('psychiatrists')
        .where('specialist', isEqualTo: 'false')
        .snapshots();
  }

  Future<List<QueryDocumentSnapshot>> searchPsychiatrists(String query) async {
    try {
      final QuerySnapshot result = await _firestore
          .collection('psychiatrists')
          .where('lowercasename', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('lowercasename',
              isLessThanOrEqualTo: query.toLowerCase() + '\uf8ff')
          .get();
      print("result");
      print(result.docs);
      return result.docs;
    } catch (e) {
      print('Error searching psychiatrists: $e');
      return [];
    }
  }

  Future<void> addFavoritePsychiatrist(
      String userId, String psychiatristId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'favoritePsychiatrists': FieldValue.arrayUnion([psychiatristId])
      });
    } catch (e) {
      print('Error adding favorite psychiatrist: $e');
    }
  }

  Future<void> removeFavoritePsychiatrist(
      String userId, String psychiatristId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'favoritePsychiatrists': FieldValue.arrayRemove([psychiatristId])
      });
    } catch (e) {
      print('Error removing favorite psychiatrist: $e');
    }
  }

  Future<List<String>> getFavoritePsychiatrists(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        return List<String>.from(data['favoritePsychiatrists'] ?? []);
      }
    } catch (e) {
      print('Error fetching favorite psychiatrists: $e');
    }
    return [];
  }

  Future<void> updateUserData(
      String userId, Map<String, dynamic> newData) async {
    try {
      await _firestore.collection('users').doc(userId).update(newData);
      print('User data updated successfully');
    } catch (e) {
      print('Error updating user data: $e');
      throw e; // Rethrow the exception to handle it in the caller function
    }
  }

  Future<void> updatePsychiatristData(
      String userId, Map<String, dynamic> newData) async {
    try {
      await _firestore.collection('psychiatrists').doc(userId).update(newData);
      print('Psychiatrist data updated successfully');
    } catch (e) {
      print('Error updating user data: $e');
      throw e; // Rethrow the exception to handle it in the caller function
    }
  }

  Future<void> createPsychiatristUserData(
      String userId, Map<String, dynamic> userData) async {
    try {
      await _firestore.collection('psychiatrists').doc(userId).set(userData);
      print('User data created successfully');
    } catch (e) {
      print('Error creating user data: $e');
      throw e; // Rethrow the exception to handle it in the caller function
    }
  }

  Future<void> createUserData(
      String userId, Map<String, dynamic> userData) async {
    try {
      await _firestore.collection('users').doc(userId).set(userData);
      print('User data created successfully');
    } catch (e) {
      print('Error creating user data: $e');
      throw e; // Rethrow the exception to handle it in the caller function
    }
  }

  Future<void> deletePsychiatristData(
      BuildContext context, String userId) async {
    try {
      // First, delete user from Firebase Authentication
      User? user = await _auth.currentUser;
      if (user != null) {
        await user.delete();
      }

      // Then, delete psychiatrist data from Firestore
      await _firestore.collection('psychiatrists').doc(userId).delete();

      // Optionally, navigate to another screen after deletion
      Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      print('Error deleting psychiatrist data: $e');
      throw e;
    }
  }

  Future<void> deleteUserData(BuildContext context, String userId) async {
    try {
      // Delete user document from Firestore
      await _firestore.collection('users').doc(userId).delete();

      // Delete user from Firebase Authentication
      User? user = await _auth.currentUser;
      if (user != null) {
        await user.delete();
      }

      // Navigate to a new screen after deletion
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => FirstScreen()),
        (Route<dynamic> route) => false, // Clear all routes in the stack
      );
    } catch (e) {
      print('Error deleting user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete profile: $e')),
      );
      throw e; // Rethrow the exception to handle it in the caller function
    }
  }
}
