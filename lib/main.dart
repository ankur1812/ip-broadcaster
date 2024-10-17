import 'dart:io'; // For Process class to execute shell commands
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';

void main() {
  runApp(const BroadcastIPApp());
}

class BroadcastIPApp extends StatefulWidget {
  const BroadcastIPApp({Key? key}) : super(key: key);

  @override
  _BroadcastIPAppState createState() => _BroadcastIPAppState();
}

class _BroadcastIPAppState extends State<BroadcastIPApp> {
  String? _localIP = "Fetching...";
  final NetworkInfo _networkInfo = NetworkInfo(); // Initialize NetworkInfo

  @override
  void initState() {
    super.initState();
    _getLocalIP(); // Fetch the local IP address on startup
  }

  Future<void> _getLocalIP() async {
    try {
      // Attempt to get the Wi-Fi IP via network_info_plus first
      String? wifiIP = await _networkInfo.getWifiIP();

      if (wifiIP != null) {
        setState(() {
          _localIP = wifiIP; // Use network_info_plus if available
        });
      } else {
        // If wifiIP is null, fallback to platform-specific logic
        String? ipAddress = await _getPlatformSpecificIP();
        setState(() {
          _localIP = ipAddress ?? "Could not fetch local IP.";
        });
      }
    } catch (e) {
      setState(() {
        _localIP = "Error: $e";
      });
    }
  }

  // Platform-specific logic to get the IP address
  Future<String?> _getPlatformSpecificIP() async {
    try {
      if (Platform.isLinux || Platform.isMacOS) {
        // Use ifconfig or ip command on Unix-based systems
        var result = await Process.run('ifconfig', []);
        if (result.exitCode == 0) {
          // Extract inet address (IPv4) using regex
          RegExp inetRegex = RegExp(r'inet (\d+\.\d+\.\d+\.\d+)');
          var match = inetRegex.firstMatch(result.stdout);
          if (match != null) return match.group(1);
        }
      } else if (Platform.isWindows) {
        // Use ipconfig on Windows
        var result = await Process.run('ipconfig', []);
        if (result.exitCode == 0) {
          // Extract IPv4 address using regex
          RegExp ipv4Regex = RegExp(r'IPv4 Address[^\d]*(\d+\.\d+\.\d+\.\d+)');
          var match = ipv4Regex.firstMatch(result.stdout);
          if (match != null) return match.group(1);
        }
      }
    } catch (e) {
      print("Error fetching IP address: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Local IP Finder')),
        body: Center(
          child: Text(
            'Local IP: $_localIP',
            style: const TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}
