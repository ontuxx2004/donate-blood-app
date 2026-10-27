
import 'package:cloud_firestore/cloud_firestore.dart';

class DonorFirestoreService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> searchDonors({
    required String bloodGroup,
    required String location,
  }) {
    return _firestore
        .collection('donors')
        .snapshots();
  }
}
