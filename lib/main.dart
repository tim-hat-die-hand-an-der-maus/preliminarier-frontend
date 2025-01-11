import 'package:flutter/material.dart';

import 'package:frontend/app.dart';

void main() {
  runApp(TimApp(
    apiBaseUrl: Uri.https('tim-api.bembel.party'),
  ));
}
