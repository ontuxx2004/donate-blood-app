
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/blood_request_model.dart';

class BloodRequestFirestoreService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // CREATE BLOOD REQUEST
  Future<void> createRequest(
      BloodRequestModel request,
      ) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User is not logged in.');
    }

    await _firestore.collection('blood_requests').add({
      'uid': user.uid,
      'patientName': request.patientName,
      'bloodGroup': request.bloodGroup,
      'units': request.units,
      'hospital': request.hospital,
      'location': request.location,
      'phone': request.phone,
      'note': request.note,
      'isEmergency': request.isEmergency,
      'status': 'pending',
      'isManaged': false,
      'responders': [],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // GET MY REQUESTS
  Stream<QuerySnapshot<Map<String, dynamic>>> myRequestsStream() {
    final user = _auth.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('blood_requests')
        .where('uid', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // DONOR RESPONDS: I'M AVAILABLE TO DONATE
  Future<void> respondToRequest(String requestId) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Please log in first.');
    }

    final requestRef =
    _firestore.collection('blood_requests').doc(requestId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(requestRef);

      if (!snapshot.exists) {
        throw Exception('Blood request not found.');
      }

      final data = snapshot.data()!;
      final status = data['status'] ?? 'pending';

      if (status == 'completed' || data['isManaged'] == true) {
        throw Exception('This request is already managed.');
      }

      final responders =
      List<String>.from(data['responders'] ?? []);

      if (!responders.contains(user.uid)) {
        responders.add(user.uid);
      }

      transaction.update(requestRef, {
        'responders': responders,
        'status': 'donor_responded',
        'lastRespondedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // REQUEST OWNER MARKS REQUEST AS MANAGED
  Future<void> completeRequest(String requestId) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Please log in first.');
    }

    final requestRef =
    _firestore.collection('blood_requests').doc(requestId);

    final snapshot = await requestRef.get();

    if (!snapshot.exists) {
      throw Exception('Blood request not found.');
    }

    final data = snapshot.data()!;

    if (data['uid'] != user.uid) {
      throw Exception('You can manage only your own request.');
    }

    await requestRef.update({
      'status': 'completed',
      'isManaged': true,
      'managedAt': FieldValue.serverTimestamp(),
    });
  }
}
