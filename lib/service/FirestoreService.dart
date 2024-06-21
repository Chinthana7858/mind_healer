import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  Future<List<QueryDocumentSnapshot>> searchPsychiatrists(String query) async {
    try {
      final QuerySnapshot result = await _firestore
          .collection('psychiatrists')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .get();
      return result.docs;
    } catch (e) {
      print('Error searching psychiatrists: $e');
      return [];
    }
  }
}
