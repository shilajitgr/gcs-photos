import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';

import 'app.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    // Background sync and upload tasks will be registered here.
    return true;
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );

  runApp(
    const ProviderScope(
      child: CGSPhotosApp(),
    ),
  );
}
