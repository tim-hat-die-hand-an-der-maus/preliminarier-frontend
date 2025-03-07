import 'package:flutter/material.dart';

import 'package:frontend/app.dart';

void main() {
  runApp(TimApp(apiBaseUrl: Uri.http('localhost:8080')));
}
