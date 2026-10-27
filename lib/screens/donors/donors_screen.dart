
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/donor_firestore_service.dart';

class DonorsScreen extends StatefulWidget {
  const DonorsScreen({super.key});

  @override
  State<DonorsScreen> createState() => _DonorsScreenState();
}

class _DonorsScreenState extends State<DonorsScreen> {
  static const Color primaryRed = Color(0xFFE31E24);

  String? selectedBloodGroup;
  String? selectedLocation;

  final DonorFirestoreService _donorService =
  DonorFirestoreService();

  Stream<QuerySnapshot<Map<String, dynamic>>>? donorStream;

  final List<String> bloodGroups = [
    'A+', 'A-', 'B+', 'B-',
    'AB+', 'AB-', 'O+', 'O-',
  ];

  final List<String> locations = [
    'Chandpur Sadar',
    'Faridganj',
    'Hajiganj',
    'Kachua',
    'Matlab North',
    'Matlab South',
    'Shahrasti',
    'Haimchar',
  ];

  void searchDonors() {
    if (selectedBloodGroup == null || selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select blood group and Chandpur upazila.',
          ),
        ),
      );
      return;
    }

    setState(() {
      donorStream = _donorService.searchDonors(
        bloodGroup: selectedBloodGroup!,
        location: selectedLocation!,
      );
    });
  }

  Future<void> _openContact(String phone, {required bool sms}) async {
    final cleanPhone = phone.trim();
    if (cleanPhone.isEmpty || cleanPhone == 'No phone number') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Donor phone number is not available.')),
      );
      return;
    }

    final uri = Uri(scheme: sms ? 'sms' : 'tel', path: cleanPhone);
    try {
      final launched = await launchUrl(uri);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open ${sms ? 'SMS' : 'phone'} app.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open contact app: $e')),
      );
    }
  }

  Widget donorCard(Map<String, dynamic> donor) {
    final String name =
    (donor['name'] ?? 'Unknown Donor').toString();

    final String bloodGroup =
    (donor['bloodGroup'] ?? 'Unknown').toString();

    final String location =
    (donor['location'] ?? 'Unknown').toString();

    final String phone =
    (donor['phone'] ?? 'No phone number').toString();

    final bool isAvailable = donor['isAvailable'] == true;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: const BoxDecoration(
              color: primaryRed,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              bloodGroup,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.phone_outlined,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        phone,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isAvailable ? Icons.check_circle : Icons.do_not_disturb_on,
                color: isAvailable ? Colors.green : Colors.red,
                size: 22,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 82,
                height: 34,
                child: ElevatedButton.icon(
                  onPressed: isAvailable
                      ? () => _openContact(phone, sms: false)
                      : null,
                  icon: const Icon(Icons.call, size: 14),
                  label: const Text('Call', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryRed,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade600,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 82,
                height: 34,
                child: OutlinedButton.icon(
                  onPressed: isAvailable
                      ? () => _openContact(phone, sms: true)
                      : null,
                  icon: const Icon(Icons.sms_outlined, size: 14),
                  label: const Text('SMS', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryRed,
                    disabledForegroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                ),
              ),
              if (!isAvailable) ...[
                const SizedBox(height: 4),
                const Text(
                  'Not ready',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget buildDonorResults() {
    if (donorStream == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.people_outline,
              size: 55,
              color: Colors.grey,
            ),
            SizedBox(height: 12),
            Text(
              'Search for donors',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Select a blood group and Chandpur upazila to find matching donors.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: donorStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(30),
            child: Center(
              child: CircularProgressIndicator(
                color: primaryRed,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final allDonors = snapshot.data?.docs ?? [];

        final matchingDonors = allDonors.where((doc) {
          final data = doc.data();

          return data['bloodGroup']?.toString().trim() ==
              selectedBloodGroup?.trim() &&
              data['location']?.toString().trim() ==
                  selectedLocation?.trim();
        }).toList();

        if (matchingDonors.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.person_search,
                  size: 55,
                  color: Colors.grey,
                ),
                const SizedBox(height: 12),
                const Text(
                  'No donors found',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${selectedBloodGroup ?? ''} donor in '
                      '${selectedLocation ?? ''} was not found.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: matchingDonors.map((doc) {
            return donorCard(doc.data());
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Find Donors',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryRed,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.bloodtype,
                    color: Colors.white,
                    size: 40,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Find Blood Donors',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Find available donors near you in Chandpur.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Search Donors',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedBloodGroup,
              decoration: InputDecoration(
                labelText: 'Blood Group',
                prefixIcon: const Icon(
                  Icons.bloodtype_outlined,
                  color: primaryRed,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              items: bloodGroups.map((group) {
                return DropdownMenuItem(
                  value: group,
                  child: Text(group),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => selectedBloodGroup = value);
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: selectedLocation,
              decoration: InputDecoration(
                labelText: 'Chandpur Upazila',
                prefixIcon: const Icon(
                  Icons.location_on_outlined,
                  color: primaryRed,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              items: locations.map((location) {
                return DropdownMenuItem(
                  value: location,
                  child: Text(location),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => selectedLocation = value);
              },
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: searchDonors,
                icon: const Icon(Icons.search),
                label: const Text(
                  'Find Donors',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryRed,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Available Donors',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            buildDonorResults(),
          ],
        ),
      ),
    );
  }
}
