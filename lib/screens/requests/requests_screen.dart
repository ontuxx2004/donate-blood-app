
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/blood_request_model.dart';
import '../../services/blood_request_firestore_service.dart';

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  static const Color primaryRed = Color(0xFFE31E24);
  static const Color lightRed = Color(0xFFFFE8E8);

  Future<void> _updateManaged(
      BuildContext context,
      String requestId,
      bool managed,
      ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first.')),
      );
      return;
    }

    try {
      final ref = FirebaseFirestore.instance
          .collection('blood_requests')
          .doc(requestId);

      // Confirm that this request belongs to the signed-in user.
      final existing = await ref.get();

      if (!existing.exists ||
          existing.data()?['uid'] != user.uid) {
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You can manage only your own requests.'),
          ),
        );
        return;
      }

      await ref.update({
        'isManaged': managed,
        'status': managed ? 'completed' : 'pending',
        'managedAt': managed ? Timestamp.now() : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            managed
                ? 'Request marked as Managed!'
                : 'Managed status unchecked.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update request: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = BloodRequestFirestoreService();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Requests',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: service.myRequestsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryRed),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load requests:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return _emptyState();
          }

          // Keep completed requests visible so the Managed tick remains.
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();

              final request = _requestFromFirestore(doc);
              final status = (data['status'] ?? 'pending').toString();
              final isManaged =
                  data['isManaged'] == true || status == 'completed';

              return _requestCard(
                context,
                request,
                requestId: doc.id,
                status: status,
                isManaged: isManaged,
                onManagedChanged: (value) =>
                    _updateManaged(context, doc.id, value),
              );
            },
          );
        },
      ),
    );
  }

  BloodRequestModel _requestFromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final data = doc.data()!;

    DateTime createdAt = DateTime.now();
    final timestamp = data['createdAt'];

    if (timestamp is Timestamp) {
      createdAt = timestamp.toDate();
    }

    return BloodRequestModel(
      patientName: (data['patientName'] ?? '').toString(),
      bloodGroup: (data['bloodGroup'] ?? '').toString(),
      units: (data['units'] ?? '').toString(),
      hospital: (data['hospital'] ?? '').toString(),
      location: (data['location'] ?? '').toString(),
      phone: (data['phone'] ?? '').toString(),
      note: (data['note'] ?? '').toString(),
      isEmergency: data['isEmergency'] ?? false,
      createdAt: createdAt,
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bloodtype_outlined,
              color: primaryRed,
              size: 55,
            ),
            SizedBox(height: 16),
            Text(
              'No Blood Requests',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'You have not submitted any blood requests yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _requestCard(
      BuildContext context,
      BloodRequestModel request, {
        required String requestId,
        required String status,
        required bool isManaged,
        required ValueChanged<bool> onManagedChanged,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: lightRed,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.bloodtype,
                  color: primaryRed,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.patientName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request.hospital,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isManaged
                      ? Colors.green.withOpacity(0.1)
                      : const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isManaged
                      ? 'Managed'
                      : status == 'accepted'
                      ? 'Accepted'
                      : 'Pending',
                  style: TextStyle(
                    color: isManaged
                        ? Colors.green
                        : status == 'accepted'
                        ? Colors.green
                        : Colors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _infoItem(Icons.water_drop, request.bloodGroup),
              const SizedBox(width: 22),
              _infoItem(Icons.opacity, request.units),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: Colors.grey,
                size: 19,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  request.location,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.phone_outlined,
                color: Colors.grey,
                size: 19,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  request.phone,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          if (request.isEmergency) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: lightRed,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.warning_rounded,
                    color: primaryRed,
                    size: 18,
                  ),
                  SizedBox(width: 7),
                  Text(
                    'Emergency Blood Request',
                    style: TextStyle(
                      color: primaryRed,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (request.note.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              request.note,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
          const Divider(height: 26),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            activeColor: primaryRed,
            controlAffinity: ListTileControlAffinity.leading,
            value: isManaged,
            title: const Text(
              'Managed',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              isManaged
                  ? 'This request is marked as completed.'
                  : 'Tick when the blood requirement has been fulfilled.',
              style: const TextStyle(fontSize: 12),
            ),
            onChanged: (value) {
              if (value != null) {
                onManagedChanged(value);
              }
            },
          ),
          const SizedBox(height: 4),
          Text(
            'Request submitted',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: primaryRed, size: 18),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
