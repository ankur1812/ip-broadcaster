import 'dart:io'; // For Process class to execute shell commands
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class BroadcastScreen extends StatefulWidget {
  const BroadcastScreen({Key? key}) : super(key: key);

  @override
  _BroadcastScreenState createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  String? _localIP = "Fetching...";
  String _httpMode = "https";
  String _port = "";
  String _finalUrl = "Loading...";
  late TextEditingController _portController;
  final NetworkInfo _networkInfo = NetworkInfo(); // Initialize NetworkInfo

  @override
  void initState() {
    super.initState();
    _portController = TextEditingController(text: _port); 
    _getLocalIP();
    _loadUserPreferences();
  }

  Future<void> _getLocalIP() async {
    try {
      // Attempt to get the Wi-Fi IP via network_info_plus first
      String? wifiIP = await _networkInfo.getWifiIP();

      if (wifiIP != null) {
        setState(() {
          _localIP = wifiIP;
          updateFinalUrl();
        });
      } else {
        // fallback to platform-specific logic
        String? ipAddress = await _getPlatformSpecificIP();
        setState(() {
          _localIP = ipAddress ?? "Could not fetch local IP.";
          updateFinalUrl();
        });
      }
    } catch (e) {
      setState(() {
        _localIP = "Error: $e";
        updateFinalUrl();
      });
    }
  }

  void updateFinalUrl() {
    setState(() {
      _finalUrl = '$_httpMode://$_localIP';
      if (_port != "") _finalUrl += ':$_port';
    });
    _saveHttpMode(_httpMode);
    _savePort(_port);
  }

  void _saveHttpMode(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('httpMode', value);
  }

  void _savePort(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('port', value);
  }

  void _loadUserPreferences() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    _httpMode = prefs.getString('httpMode') ?? "https";
    _port = prefs.getString('port') ?? "";
    _portController.text = _port; 
  });
}

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url); 
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw 'Could not launch $url';
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
      appBar: AppBar(
        title: const Text(
          'Broadcast my IP!',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 36, 89, 168),
        // iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              'Your Local IP',
              style: const TextStyle(
                fontSize: 16,
                color: Color.fromARGB(255, 36, 89, 168)
              ),
            ),

            Container(
              margin: const EdgeInsets.only(bottom: 24.0),
              child: InkWell(
                onTap: () => _launchURL(_finalUrl), // URL to open
                child: Text(
                  _finalUrl,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    // decoration: TextDecoration.underline, 
                  )
                ),
              ),              
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 28.0),
              child: QrImageView(
                data: _finalUrl,
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            Row (
              children: [
                const SizedBox(width: 8),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Protocol", 
                      style: TextStyle(color: Color.fromARGB(255, 36, 89, 168))
                    ),
                    SizedBox(
                      width: 85.0,
                      height: 60.0,
                      child: DropdownButton<String>(
                        value: _httpMode,
                        items: [
                          DropdownMenuItem(value: "http", child: Text("HTTP")),
                          DropdownMenuItem(value: "https", child: Text("HTTPS")),
                        ],
                        onChanged: (newValue) {
                          setState(() {
                            _httpMode = newValue!;
                            updateFinalUrl();
                          });
                        },
                      ),
                    )
                  ],
                ),

                const SizedBox(width: 24),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Add port?", 
                      style: TextStyle(color: Color.fromARGB(255, 36, 89, 168))
                    ),
                    SizedBox(
                      width: 75.0,
                      child: 
                        TextField(
                          controller: _portController,
                          decoration: const InputDecoration(
                            // labelText: "Add port?",
                            // border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number, // Shows a numeric keyboard
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (text) {
                            setState(() {
                              _port = text;
                              updateFinalUrl();
                            });
                          },
                        )
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      )
    );
  }
}
