import 'package:flutter/material.dart';

import 'package:medify/app/my_app.dart';
import 'package:medify/core/di/injection_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDependencies();
  runApp(MyApp(key: myAppKey));
}
