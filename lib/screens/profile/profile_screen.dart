import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../welcome/welcome_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color primaryRed = Color(0xFFE31E24);

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final districtController = TextEditingController(text: 'Chandpur');
  final upazilaController = TextEditingController();

  String bloodGroup = '';
  DateTime? lastDonationDate;
  bool isDonor = false;
  bool isAvailable = false;
  bool isLoading = true;
  bool isSaving = false;
  bool isLoggingOut = false;

  final List<String> bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-',
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

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    districtController.dispose();
    upazilaController.dispose();
    super.dispose();
  }

  String get formattedDate {
    if (lastDonationDate == null) return 'Not provided';
    final d = lastDonationDate!;
    return '${d.day}/${d.month}/${d.year}';
  }

  Future<void> _loadProfile() async {
    final user = _auth.currentUser;

    if (user == null) {
      if (mounted) setState(() => isLoading = false);
      return;
    }

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!mounted) return;

      final data = doc.data();

      nameController.text =
          (data?['fullName'] ?? data?['name'] ?? '').toString();
      emailController.text =
          (data?['email'] ?? user.email ?? '').toString();
      phoneController.text = (data?['phone'] ?? '').toString();
      districtController.text =
          (data?['district'] ?? 'Chandpur').toString();
      upazilaController.text =
          (data?['upazila'] ?? data?['location'] ?? '').toString();
      bloodGroup = (data?['bloodGroup'] ?? '').toString();
      isDonor = data?['isDonor'] == true;
      isAvailable = data?['isAvailable'] == true;

      final savedDate = data?['lastDonationDate'];
      if (savedDate is Timestamp) {
        lastDonationDate = savedDate.toDate();
      } else if (savedDate is String) {
        lastDonationDate = DateTime.tryParse(savedDate);
      }

      setState(() => isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _showMessage('Could not load profile: $e');
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log Out?'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => isLoggingOut = true);

    try {
      await _auth.signOut();
      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const WelcomeScreen(),
        ),
            (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoggingOut = false);
      _showMessage('Logout failed. Please try again.');
    }
  }

  Future<void> _selectDonationDate(
      BuildContext dialogContext,
      StateSetter setDialogState,
      ) async {
    final picked = await showDatePicker(
      context: dialogContext,
      initialDate: lastDonationDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Select Last Donation Date',
    );

    if (picked != null) {
      setState(() => lastDonationDate = picked);
      setDialogState(() {});
    }
  }

  bool _isEligibleToDonate() {
    if (lastDonationDate == null) return false;

    final now = DateTime.now();
    final d = lastDonationDate!;
    final cutoff = DateTime(now.year, now.month - 4, now.day);

    return !d.isAfter(cutoff);
  }

  Future<void> _setAvailability(bool value) async {
    final user = _auth.currentUser;

    if (user == null) {
      _showMessage('Please log in first.');
      return;
    }

    if (!isDonor) {
      _showMessage('Please register as a donor first.');
      return;
    }

    if (value && !_isEligibleToDonate()) {
      _showMessage(
        'Please check your last donation date. You must meet the 4-month '
            'interval before marking yourself available.',
      );
      return;
    }

    setState(() => isAvailable = value);

    try {
      final availableValue = value && _isEligibleToDonate();
      final userRef = _firestore.collection('users').doc(user.uid);
      final donorRef = _firestore.collection('donors').doc(user.uid);
      final batch = _firestore.batch();

      batch.set(
        userRef,
        {
          'isAvailable': availableValue,
          'availabilityUpdatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      batch.set(
        donorRef,
        {
          'uid': user.uid,
          'isAvailable': availableValue,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await batch.commit();

      if (!mounted) return;
      setState(() => isAvailable = availableValue);
      _showMessage(
        availableValue
            ? 'You are now marked as available.'
            : 'You are now marked as unavailable.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => isAvailable = !value);
      _showMessage('Could not update availability: $e');
    }
  }

  Future<void> _saveProfile() async {
    final user = _auth.currentUser;

    if (user == null) {
      _showMessage('Please log in first.');
      return;
    }

    if (nameController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty) {
      _showMessage('Please enter your name and phone number.');
      return;
    }

    if (isDonor &&
        (bloodGroup.isEmpty || upazilaController.text.trim().isEmpty)) {
      _showMessage('Donor registration needs blood group and upazila.');
      return;
    }

    setState(() => isSaving = true);

    final profileData = <String, dynamic>{
      'uid': user.uid,
      'fullName': nameController.text.trim(),
      'name': nameController.text.trim(),
      'email': emailController.text.trim(),
      'phone': phoneController.text.trim(),
      'district': districtController.text.trim(),
      'upazila': upazilaController.text.trim(),
      'bloodGroup': bloodGroup,
      'isDonor': isDonor,
      'isAvailable': isDonor && isAvailable && _isEligibleToDonate(),
      'lastDonationDate': lastDonationDate == null
          ? null
          : Timestamp.fromDate(lastDonationDate!),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      final batch = _firestore.batch();
      final userRef = _firestore.collection('users').doc(user.uid);
      final donorRef = _firestore.collection('donors').doc(user.uid);

      batch.set(
        userRef,
        {
          ...profileData,
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (isDonor) {
        batch.set(
          donorRef,
          {
            'uid': user.uid,
            'name': nameController.text.trim(),
            'bloodGroup': bloodGroup,
            'location': upazilaController.text.trim(),
            'phone': phoneController.text.trim(),
            'isAvailable': isAvailable && _isEligibleToDonate(),
            'lastDonationDate': lastDonationDate == null
                ? null
                : Timestamp.fromDate(lastDonationDate!),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      } else {
        batch.delete(donorRef);
      }

      await batch.commit();

      if (!mounted) return;
      setState(() => isSaving = false);
      Navigator.pop(context);
      _showMessage('Profile saved successfully!');
    } catch (e) {
      if (!mounted) return;
      setState(() => isSaving = false);
      _showMessage('Could not save profile: $e');
    }
  }

  Future<void> _editProfile() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _editField(nameController, 'Full Name'),
                _editField(emailController, 'Email'),
                _editField(phoneController, 'Phone Number'),
                _editField(districtController, 'District'),
                DropdownButtonFormField<String>(
                  value: locations.contains(upazilaController.text)
                      ? upazilaController.text
                      : null,
                  decoration: const InputDecoration(labelText: 'Upazila'),
                  items: locations.map((location) {
                    return DropdownMenuItem(
                      value: location,
                      child: Text(location),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      upazilaController.text = value ?? '';
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: bloodGroups.contains(bloodGroup) ? bloodGroup : null,
                  decoration: const InputDecoration(labelText: 'Blood Group'),
                  items: bloodGroups.map((group) {
                    return DropdownMenuItem(
                      value: group,
                      child: Text(group),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() => bloodGroup = value ?? '');
                  },
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _selectDonationDate(
                    dialogContext,
                    setDialogState,
                  ),
                  icon: const Icon(Icons.calendar_month),
                  label: Text(
                    lastDonationDate == null
                        ? 'Choose Last Donation Date'
                        : formattedDate,
                  ),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: isDonor,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Register as a blood donor'),
                  subtitle: const Text(
                    'Allow my donor details to appear in Find Donors.',
                  ),
                  onChanged: (value) {
                    setDialogState(() => isDonor = value ?? false);
                  },
                ),
                if (isDonor && !_isEligibleToDonate())
                  const Text(
                    'Last donation date is missing or less than four months ago. '
                        'You will not be listed as currently available.',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryRed,
                foregroundColor: Colors.white,
              ),
              child: isSaving
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (mounted) setState(() {});
  }

  Widget _editField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 16),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String title, String value) {
    return Card(
      elevation: 0,
      color: const Color(0xFFFFEEEE),
      margin: const EdgeInsets.only(bottom: 9),
      child: ListTile(
        leading: Icon(icon, color: primaryRed),
        title: Text(
          title,
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        subtitle: Text(
          value.isEmpty ? 'Not provided' : value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryRed,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 16),
            const CircleAvatar(
              radius: 52,
              backgroundColor: Color(0xFFFFE5E5),
              child: Icon(Icons.person, size: 60, color: primaryRed),
            ),
            const SizedBox(height: 14),
            Text(
              nameController.text.isEmpty
                  ? 'Your Name'
                  : nameController.text,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Donate Blood Community',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _editProfile,
                icon: const Icon(Icons.edit),
                label: const Text('Edit Profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            _sectionTitle('Personal Information'),
            _infoTile(Icons.person_outline, 'Full Name', nameController.text),
            _infoTile(Icons.email_outlined, 'Email', emailController.text),
            _infoTile(Icons.phone_outlined, 'Phone Number', phoneController.text),
            _sectionTitle('Donor Information'),
            _infoTile(Icons.bloodtype, 'Blood Group', bloodGroup),
            _infoTile(Icons.location_on_outlined, 'District', districtController.text),
            _infoTile(Icons.map_outlined, 'Upazila', upazilaController.text),
            _infoTile(Icons.calendar_month, 'Last Donation Date', formattedDate),
            _infoTile(
              Icons.volunteer_activism,
              'Donor Registration',
              isDonor ? 'Registered' : 'Not registered',
            ),

            // Donor availability toggle
            if (isDonor)
              Card(
                elevation: 0,
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 9),
                child: SwitchListTile(
                  activeColor: primaryRed,
                  title: const Text(
                    'Available for Donation',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    !_isEligibleToDonate()
                        ? 'Unavailable: last donation date is missing or less than 4 months ago.'
                        : isAvailable
                        ? 'You may receive matching blood request notifications.'
                        : 'Turn on when you are ready to donate.',
                  ),
                  value: isAvailable && _isEligibleToDonate(),
                  onChanged: isSaving
                      ? null
                      : (value) => _setAvailability(value),
                ),
              )
            else
              Card(
                elevation: 0,
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 9),
                child: const ListTile(
                  leading: Icon(Icons.info_outline, color: primaryRed),
                  title: Text('Donor availability'),
                  subtitle: Text('Register as a donor to manage availability.'),
                ),
              ),

            const SizedBox(height: 28),

            // LOGOUT BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: isLoggingOut ? null : _logout,
                icon: isLoggingOut
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.logout),
                label: Text(isLoggingOut ? 'Logging out...' : 'Log Out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryRed,
                  side: const BorderSide(color: primaryRed),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
