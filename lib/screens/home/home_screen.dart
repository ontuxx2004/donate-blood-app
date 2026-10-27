import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../blood_request/blood_request_screen.dart';
import '../requests/requests_screen.dart';
import '../requests/all_requests_screen.dart';
import '../donors/donors_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color primaryRed = Color(0xFFE31E24);
  static const Color lightRed = Color(0xFFFFE8E8);

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
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE31E24), Color(0xFFEF3035)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: () {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) {
                          return const Stream<
                              DocumentSnapshot<Map<String, dynamic>>>.empty();
                        }
                        return FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .snapshots();
                      }(),
                      builder: (context, snapshot) {
                        final data = snapshot.data?.data();
                        final rawName = (data?['fullName'] ??
                            data?['name'] ??
                            FirebaseAuth.instance.currentUser?.displayName ??
                            '')
                            .toString()
                            .trim();

                        final displayName =
                        rawName.isEmpty ? 'Donor' : rawName.split(RegExp(r'\\s+')).first;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, $displayName 👋',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 23,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'Thank you for being a lifesaver!',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const Icon(
                    Icons.notifications_none,
                    color: Colors.white,
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 25),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildEmergencyCard(context),
                const SizedBox(height: 22),
                _buildSectionTitle('Quick Actions'),
                const SizedBox(height: 12),
                _buildQuickActions(context),
                const SizedBox(height: 24),
                _buildSectionTitle('Emergency Blood Requests'),
                const SizedBox(height: 12),
                _buildEmergencyRequests(context),
                const SizedBox(height: 20),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.warning_rounded, color: primaryRed, size: 35),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emergency Blood Request',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Someone needs your help urgently',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BloodRequestScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryRed,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Request Blood Now →',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyRequests(BuildContext context) {
    return Column(
      children: [
        // Blood group and Chandpur Upazila filters
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: selectedBloodGroup,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Blood Group',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
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
                decoration: InputDecoration(
                  labelText: 'Location',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
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
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('blood_requests')
              .where('isEmergency', isEqualTo: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _messageCard(
                'Could not load emergency requests. Check Firestore permissions.',
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: primaryRed),
                ),
              );
            }

            final docs = snapshot.data?.docs.toList() ?? [];

            // Filter by selected blood group and Upazila.
            docs.removeWhere((doc) {
              final data = doc.data();
              final bloodGroup = (data['bloodGroup'] ?? '')
                  .toString()
                  .trim()
                  .toUpperCase();
              final location = (data['location'] ?? '')
                  .toString()
                  .trim()
                  .toLowerCase();

              final matchesBloodGroup = selectedBloodGroup == 'All' ||
                  bloodGroup == selectedBloodGroup.toUpperCase();
              final matchesLocation = selectedLocation == 'All Chandpur' ||
                  location == selectedLocation.toLowerCase();

              return !matchesBloodGroup || !matchesLocation;
            });

            // Unmanaged requests first, managed requests last.
            // Newest requests appear first within each group.
            docs.sort((a, b) {
              final aData = a.data();
              final bData = b.data();

              final aStatus =
              (aData['status'] ?? 'pending').toString().toLowerCase();
              final bStatus =
              (bData['status'] ?? 'pending').toString().toLowerCase();

              final aManaged =
                  aData['isManaged'] == true || aStatus == 'completed';
              final bManaged =
                  bData['isManaged'] == true || bStatus == 'completed';

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
              return _messageCard(
                'No matching emergency requests right now.',
              );
            }

            return Column(
              children: docs.map((doc) {
                return _requestCard(context, doc.data());
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _requestCard(
      BuildContext context,
      Map<String, dynamic> data,
      ) {
    final bloodGroup = (data['bloodGroup'] ?? 'Unknown').toString();
    final hospital =
    (data['hospital'] ?? 'Hospital not provided').toString();
    final location =
    (data['location'] ?? 'Location not provided').toString();
    final units = (data['units'] ?? '1').toString();
    final phone = (data['phone'] ?? '').toString();
    final patient = (data['patientName'] ?? 'Patient').toString();
    final status = (data['status'] ?? 'pending').toString();
    final managed =
        data['isManaged'] == true || status == 'completed';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: managed ? Colors.green.shade100 : lightRed,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.035),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
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
                  color: managed ? Colors.green.shade50 : lightRed,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  bloodGroup,
                  style: TextStyle(
                    color: managed ? Colors.green : primaryRed,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  managed ? 'MANAGED' : 'URGENT',
                  style: TextStyle(
                    color: managed ? Colors.green : primaryRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
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
          if (managed) ...[
            const SizedBox(height: 10),
            const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 18),
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
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => showRequesterContact(
                  context,
                  phone,
                  patient,
                ),
                icon: const Icon(Icons.phone),
                label: const Text('View Contact Number'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryRed,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _messageCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: Color(0xFF222222),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _quickAction(
            icon: Icons.people_alt,
            color: Colors.blue,
            title: 'Find Donors',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const DonorsScreen(),
              ),
            ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _quickAction(
            icon: Icons.water_drop,
            color: primaryRed,
            title: 'Request Blood',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const BloodRequestScreen(),
              ),
            ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _quickAction(
            icon: Icons.description,
            color: Colors.deepPurple,
            title: 'My Requests',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const RequestsScreen(),
              ),
            ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _quickAction(
            icon: Icons.list_alt,
            color: Colors.deepPurple,
            title: 'All Requests',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AllRequestsScreen(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _quickAction({
    required IconData icon,
    required Color color,
    required String title,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 95,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 39,
              height: 39,
              decoration: BoxDecoration(
                color: color.withOpacity(.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
