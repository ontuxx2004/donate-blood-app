import 'package:flutter/material.dart';

import '../models/blood_request_model.dart';

class BloodRequestStore {
  static final ValueNotifier<List<BloodRequestModel>> requests =
  ValueNotifier<List<BloodRequestModel>>([]);

  static void addRequest(BloodRequestModel request) {
    requests.value = [
      request,
      ...requests.value,
    ];
  }
}