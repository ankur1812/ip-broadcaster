// import 'dart:io';
import 'package:flutter/material.dart';
// import 'package:window_manager/window_manager.dart';
import 'package:window_size/window_size.dart';
import 'screens/broadcast.dart';

// void windowManagerSizeUpdate () async {
//   // Implements resize unctionality using package:window_manager
//   await windowManager.ensureInitialized();
//   WindowOptions windowOptions = const WindowOptions(
//     size: Size(800, 600),
//     center: true,
//     minimumSize: Size(800,  800),
//     maximumSize: Size(800, 800),
//   );
//   windowManager.waitUntilReadyToShow(windowOptions, () async {
//     await windowManager.show();
//     await windowManager.focus();
//   });
// }

void windowSizeUpdate () async {
  // Implements resize unctionality using package:window_size
  setWindowTitle("Broadcast my IP");
  setWindowMinSize(const Size(600, 700)); // Minimum size
  setWindowMaxSize(const Size(600, 700)); // Maximum size
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  windowSizeUpdate();
  // windowManagerSizeUpdate();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Find My IP',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.redAccent),
        useMaterial3: true,
      ),
      home: BroadcastScreen(),
    );
  }
}
