class BloodRequestModel {
  final String patientName;
  final String bloodGroup;
  final String units;
  final String hospital;
  final String location;
  final String phone;
  final String note;
  final bool isEmergency;
  final DateTime createdAt;

  BloodRequestModel({
    required this.patientName,
    required this.bloodGroup,
    required this.units,
    required this.hospital,
    required this.location,
    required this.phone,
    required this.note,
    required this.isEmergency,
    required this.createdAt,
  });
}