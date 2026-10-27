import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const Color primaryRed = Color(0xFFE31E24);

Future<void> showRequesterContact(
    BuildContext context,
    String phone,
    String patientName,
    ) async {
  if (phone.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contact number is not available.'),
      ),
    );
    return;
  }

  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Contact Requester'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Patient: $patientName'),
          const SizedBox(height: 12),
          SelectableText(
            phone,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final uri = Uri(
                  scheme: 'tel',
                  path: phone.trim(),
                );

                try {
                  final opened = await launchUrl(
                    uri,
                    mode: LaunchMode.externalApplication,
                  );

                  if (!opened && dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'No phone dialer available on this device.',
                        ),
                      ),
                    );
                  }
                } catch (_) {
                  if (!dialogContext.mounted) return;
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Could not open phone dialer.'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.call),
              label: const Text('Call Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryRed,
                foregroundColor: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final uri = Uri(
                  scheme: 'sms',
                  path: phone.trim(),
                  queryParameters: {
                    'body':
                    'Assalamu Alaikum, I saw your blood request for $patientName. I am interested in donating blood. Please let me know the details.',
                  },
                );

                try {
                  final opened = await launchUrl(
                    uri,
                    mode: LaunchMode.externalApplication,
                  );

                  if (!opened && dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'No messaging app available on this device.',
                        ),
                      ),
                    );
                  }
                } catch (_) {
                  if (!dialogContext.mounted) return;
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Could not open messaging app.'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.message),
              label: const Text('Send SMS'),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

class AllRequestsScreen extends StatefulWidget {
  const AllRequestsScreen({super.key});

  @override
  State<AllRequestsScreen> createState() => _AllRequestsScreenState();
}

class _AllRequestsScreenState extends State<AllRequestsScreen> {
  String selectedBloodGroup = 'All';
  String selectedLocation = 'All Chandpur';

  static const List<String> bloodGroups = [
    'All', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-',
  ];

  static const List<String> locations = [
    'All Chandpur',
    'Chandpur Sadar',
    'Faridganj',
    'Hajiganj',
    'Kachua',
    'Matlab North',
    'Matlab South',
    'Shahrasti',
    'Haimchar',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text(
          'All Requests',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedBloodGroup,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Blood Group',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                    ),
                    items: bloodGroups.map((group) {
                      return DropdownMenuItem<String>(
                        value: group,
                        child: Text(group),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => selectedBloodGroup = value);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedLocation,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                    ),
                    items: locations.map((place) {
                      return DropdownMenuItem<String>(
                        value: place,
                        child: Text(
                          place,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => selectedLocation = value);
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('blood_requests')
                  .snapshots(),
              builder: (context, snapshot) {
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

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryRed),
                  );
                }

                final docs = snapshot.data?.docs.toList() ?? [];

                // Filter requests by the selected blood group and location.
                docs.removeWhere((doc) {
                  final data = doc.data();
                  final bloodGroup =
                  (data['bloodGroup'] ?? '').toString().trim().toUpperCase();
                  final location =
                  (data['location'] ?? '').toString().trim().toLowerCase();

                  final matchesBloodGroup = selectedBloodGroup == 'All' ||
                      bloodGroup == selectedBloodGroup.toUpperCase();

                  final matchesLocation = selectedLocation == 'All Chandpur' ||
                      location == selectedLocation.toLowerCase();

                  return !matchesBloodGroup || !matchesLocation;
                });

                // Unmanaged requests first; managed requests last.
                // Keep newest-first ordering inside each group.
                docs.sort((a, b) {
                  final aData = a.data();
                  final bData = b.data();

                  final aManaged = aData['isManaged'] == true ||
                      aData['status'] == 'completed';
                  final bManaged = bData['isManaged'] == true ||
                      bData['status'] == 'completed';

                  if (aManaged != bManaged) {
                    return aManaged ? 1 : -1;
                  }

                  final aTime = aData['createdAt'];
                  final bTime = bData['createdAt'];
                  final aDate =
                  aTime is Timestamp ? aTime.toDate() : DateTime(2000);
                  final bDate =
                  bTime is Timestamp ? bTime.toDate() : DateTime(2000);

                  return bDate.compareTo(aDate);
                });

                if (docs.isEmpty) {
                  return const Center(
                    child: Text('No matching blood requests found.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();

                    final patient =
                    (data['patientName'] ?? 'Patient').toString();
                    final bloodGroup =
                    (data['bloodGroup'] ?? 'Unknown').toString();
                    final hospital =
                    (data['hospital'] ?? 'Not provided').toString();
                    final location =
                    (data['location'] ?? 'Not provided').toString();
                    final phone = (data['phone'] ?? '').toString();
                    final units = (data['units'] ?? '1').toString();

                    final isEmergency = data['isEmergency'] == true;
                    final isManaged = data['isManaged'] == true ||
                        data['status'] == 'completed';

                    final status = isManaged
                        ? 'MANAGED'
                        : isEmergency
                        ? 'EMERGENCY'
                        : 'NORMAL REQUEST';

                    final statusColor = isManaged
                        ? Colors.green
                        : isEmergency
                        ? primaryRed
                        : Colors.blueGrey;

                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(
                          color: isManaged
                              ? Colors.green.shade100
                              : isEmergency
                              ? const Color(0xFFFFE8E8)
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isManaged
                                        ? Colors.green.shade50
                                        : const Color(0xFFFFE8E8),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    bloodGroup,
                                    style: TextStyle(
                                      color: isManaged ? Colors.green : primaryRed,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                Text(
                                  '$units unit(s)',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Patient: $patient',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 5),
                            Text('Hospital: $hospital'),
                            const SizedBox(height: 4),
                            Text('Location: $location'),

                            if ((data['note'] ?? '').toString().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text('Note: ${data['note']}'),
                            ],

                            if (isManaged) ...[
                              const SizedBox(height: 10),
                              const Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 18,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Blood request managed',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => showRequesterContact(
                                  context,
                                  phone,
                                  patient,
                                ),
                                icon: const Icon(
                                  Icons.phone,
                                  color: primaryRed,
                                ),
                                label: const Text(
                                  'View Contact Number',
                                  style: TextStyle(color: primaryRed),
                                ),
                                style: OutlinedButton.styleFrom(
                                  shape: const StadiumBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
