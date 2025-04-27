import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseMethods {
  Future addUser(String userId, Map<String, dynamic> userInfoMap) {
    return FirebaseFirestore.instance
        .collection("User")
        .doc(userId)
        .set(userInfoMap);
  }

  Future<Map<String, dynamic>?> getUser(String userId) async {
    DocumentSnapshot snapshot =
        await FirebaseFirestore.instance.collection("User").doc(userId).get();
    return snapshot.data() as Map<String, dynamic>?;
  }
}
