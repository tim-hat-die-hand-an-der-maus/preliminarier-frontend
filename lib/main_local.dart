import 'package:flutter/material.dart';

import 'app.dart';

void main() {
  runApp(TimApp(
    apiBaseUrl: Uri.http('localhost:8080'),
  ));
}
