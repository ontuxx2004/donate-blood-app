import 'package:flutter/material.dart';

import '../../models/blood_request_model.dart';
import '../../services/blood_request_firestore_service.dart';

class BloodRequestScreen extends StatefulWidget {
  const BloodRequestScreen({super.key});

  @override
  State<BloodRequestScreen> createState() => _BloodRequestScreenState();
}

class _BloodRequestScreenState extends State<BloodRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  final BloodRequestFirestoreService _firestoreService =
  BloodRequestFirestoreService();

  String? selectedBloodGroup;
  String? selectedUnits;
  String? selectedUpazila;

  final List<String> chandpurUpazilas = const [
    'Chandpur Sadar',
    'Faridganj',
    'Hajiganj',
    'Kachua',
    'Matlab North',
    'Matlab South',
    'Shahrasti',
    'Haimchar',
  ];
  bool isEmergency = false;

  final patientNameController = TextEditingController();
  final hospitalController = TextEditingController();
  final phoneController = TextEditingController();
  final noteController = TextEditingController();

  final List<String> bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  final List<String> units = [
    '1 Unit',
    '2 Units',
    '3 Units',
    '4 Units',
  ];

  @override
  void dispose() {
    patientNameController.dispose();
    hospitalController.dispose();
    phoneController.dispose();
    noteController.dispose();
    super.dispose();
  }

  InputDecoration inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: const Color(0xFFE31E24),
      ),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE31E24),
          width: 1.5,
        ),
      ),
    );
  }

  // =========================================================
  // SUBMIT REQUEST TO FIRESTORE
  // =========================================================

  Future<void> submitBloodRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedBloodGroup == null ||
        selectedUnits == null ||
        selectedUpazila == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select blood group, units and Upazila.')),
      );
      return;
    }

    final request = BloodRequestModel(
      patientName: patientNameController.text.trim(),
      bloodGroup: selectedBloodGroup!,
      units: selectedUnits!,
      hospital: hospitalController.text.trim(),
      location: selectedUpazila!,
      phone: phoneController.text.trim(),
      note: noteController.text.trim(),
      isEmergency: isEmergency,
      createdAt: DateTime.now(),
    );

    try {
      await _firestoreService.createRequest(request);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Blood request submitted successfully!',
          ),
          backgroundColor: Color(0xFFE31E24),
          duration: Duration(seconds: 2),
        ),
      );

      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to submit request: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),

      // =====================================================
      // APP BAR
      // =====================================================

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Request Blood',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.black87,
        ),
      ),

      // =====================================================
      // FORM
      // =====================================================

      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            16,
            8,
            16,
            30,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // =================================================
              // EMERGENCY CARD
              // =================================================

              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isEmergency
                      ? const Color(0xFFFFEBEE)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isEmergency
                        ? const Color(0xFFE31E24)
                        : Colors.grey.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE0E3),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.warning_rounded,
                        color: Color(0xFFE31E24),
                      ),
                    ),

                    const SizedBox(width: 12),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Emergency Request',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Turn this on if blood is needed urgently.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Switch(
                      value: isEmergency,
                      activeThumbColor:
                      const Color(0xFFE31E24),
                      onChanged: (value) {
                        setState(() {
                          isEmergency = value;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // =================================================
              // BLOOD INFORMATION
              // =================================================

              const Text(
                'Blood Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [

                  // Blood Group
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedBloodGroup,
                      decoration: inputDecoration(
                        label: 'Blood Group',
                        icon: Icons.bloodtype_outlined,
                      ),
                      items: bloodGroups.map((group) {
                        return DropdownMenuItem<String>(
                          value: group,
                          child: Text(
                            group,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedBloodGroup = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Select group';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Required Units
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedUnits,
                      decoration: inputDecoration(
                        label: 'Required Units',
                        icon: Icons.water_drop_outlined,
                      ),
                      items: units.map((unit) {
                        return DropdownMenuItem<String>(
                          value: unit,
                          child: Text(unit),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedUnits = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Select units';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // =================================================
              // PATIENT INFORMATION
              // =================================================

              const Text(
                'Patient Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              // Patient Name
              TextFormField(
                controller: patientNameController,
                decoration: inputDecoration(
                  label: 'Patient Name',
                  hint: 'Enter patient name',
                  icon: Icons.person_outline,
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Enter patient name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12),

              // Contact Number
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: inputDecoration(
                  label: 'Contact Number',
                  hint: '01XXXXXXXXX',
                  icon: Icons.phone_outlined,
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Enter contact number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // =================================================
              // HOSPITAL & LOCATION
              // =================================================

              const Text(
                'Hospital & Location',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              // Hospital
              TextFormField(
                controller: hospitalController,
                decoration: inputDecoration(
                  label: 'Hospital Name',
                  hint: 'Enter hospital name',
                  icon: Icons.local_hospital_outlined,
                ),
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty) {
                    return 'Enter hospital name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12),

              // Chandpur Upazila dropdown
              DropdownButtonFormField<String>(
                value: selectedUpazila,
                isExpanded: true,
                decoration: inputDecoration(
                  label: 'Select Upazila',
                  hint: 'Choose an Upazila',
                  icon: Icons.location_on_outlined,
                ),
                items: chandpurUpazilas.map((upazila) {
                  return DropdownMenuItem<String>(
                    value: upazila,
                    child: Text(upazila),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedUpazila = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select an Upazila';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // =================================================
              // ADDITIONAL INFORMATION
              // =================================================

              const Text(
                'Additional Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: noteController,
                maxLines: 4,
                decoration: inputDecoration(
                  label: 'Additional Note',
                  hint: 'Add any important information...',
                  icon: Icons.notes_outlined,
                ),
              ),

              const SizedBox(height: 28),

              // =================================================
              // SUBMIT BUTTON
              // =================================================

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: submitBloodRequest,
                  icon: const Icon(
                    Icons.send_rounded,
                  ),
                  label: const Text(
                    'Submit Blood Request',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(0xFFE31E24),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
