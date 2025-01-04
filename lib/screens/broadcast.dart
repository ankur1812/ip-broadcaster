import 'dart:io'; // For Process class to execute shell commands
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';


class BroadcastScreen extends StatefulWidget {
  const BroadcastScreen({Key? key}) : super(key: key);

  @override
  _BroadcastScreenState createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  String? _localIP = "Fetching...";
  String _httpMode = "https";
  String _port = "80";
  final NetworkInfo _networkInfo = NetworkInfo(); // Initialize NetworkInfo

  @override
  void initState() {
    super.initState();
    _getLocalIP();
  }

  Future<void> _getLocalIP() async {
    try {
      // Attempt to get the Wi-Fi IP via network_info_plus first
      String? wifiIP = await _networkInfo.getWifiIP();

      if (wifiIP != null) {
        setState(() {
          _localIP = wifiIP;
        });
      } else {
        // fallback to platform-specific logic
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
        var result = await Process.run('ipconfig', []);
        if (result.exitCode == 0) {
          // Extract IPv4 address using regex
          RegExp ipv4Regex = RegExp(r'IPv4 Address[^\d]*(\d+\.\d+\.\d+\.\d+)');
          var match = ipv4Regex.firstMatch(result.stdout);
          if (match != null) return match.group(1);
        }
      }
    } catch (e) {
      // print("Error fetching IP address: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text('Local IP Finder')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // const Divider(),
            Container(
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                'Your Local IP is: \n$_httpMode://$_localIP:$_port',
                style: const TextStyle(fontSize: 24),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 16.0),
              child: QrImageView(
                data: '$_httpMode://$_localIP:$_port',
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            Row (
              children: [
                SizedBox(
                  width: 100.0,
                  child: DropdownButton<String>(
                    value: _httpMode,
                    items: [
                      DropdownMenuItem(value: "http", child: Text("HTTP")),
                      DropdownMenuItem(value: "https", child: Text("HTTPS")),
                    ],
                    onChanged: (newValue) {
                      setState(() {
                        _httpMode = newValue!;
                      });
                    },
                  )
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 100.0,
                  child: 
                  TextField(
                  decoration: const InputDecoration(
                    labelText: "Port",
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (text) {
                    setState(() {
                      _port = text; // Update state with input value
                    });
                  },
                )),
              ],
            ),
          ],
        ),
      )
    );
  }
}
