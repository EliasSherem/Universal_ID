import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const UniversalIdApp());
}

class UniversalIdApp extends StatelessWidget {
  const UniversalIdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Universal ID MX',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D1117), // Premium dark layout
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF10B981), // Emerald 500
          surface: Color(0xFF161B22),
        ),
      ),
      home: const WalletScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final TextEditingController _curpController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _profile;
  String? _error;

  Future<void> _validateCurp() async {
    final curp = _curpController.text.trim().toUpperCase();
    if (curp.length != 18) {
      setState(() => _error = "CURP must be exactly 18 characters");
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _profile = null;
    });

    try {
      // Automatically switch to Android emulator localhost IP if needed.
      String baseUrl = 'http://127.0.0.1:8080';
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        baseUrl = 'http://10.0.2.2:8080';
      }
      
      final uri = Uri.parse('$baseUrl/api/validate/curp');
      
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'curp': curp}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _profile = data['result']['profile'];
        });
      } else {
        setState(() => _error = data['error'] ?? "Validation failed");
      }
    } catch (e) {
      setState(() => _error = "Network error. Is the backend running? $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Universal ID Wallet', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_profile == null) ...[
                const Icon(Icons.fingerprint, size: 80, color: Color(0xFF10B981)),
                const SizedBox(height: 24),
                const Text(
                  'Verify Your Identity',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter your official CURP to retrieve your government-validated profile.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60, fontSize: 16),
                ),
                const SizedBox(height: 48),
                TextField(
                  controller: _curpController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'CURP',
                    hintText: 'e.g., VAMG940505HDFRRN04',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.badge),
                    errorText: _error,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _validateCurp,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Validate with Government', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ] else ...[
                // Success View
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ]
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.verified_user, color: Color(0xFF10B981), size: 64),
                      const SizedBox(height: 16),
                      const Text('Identity Validated', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                      const SizedBox(height: 24),
                      _buildProfileRow('Full Name', _profile!['canonical_full_name'] ?? '---'),
                      const Divider(color: Colors.white12, height: 24),
                      _buildProfileRow('CURP', _profile!['canonical_curp'] ?? '---'),
                      const Divider(color: Colors.white12, height: 24),
                      _buildProfileRow('Date of Birth', _profile!['canonical_date_of_birth'] ?? '---'),
                      const Divider(color: Colors.white12, height: 24),
                      _buildProfileRow('Sex Marker', _profile!['canonical_sex_marker'] ?? '---'),
                      const Divider(color: Colors.white12, height: 24),
                      _buildProfileRow('State of Birth', _profile!['canonical_state_of_birth'] ?? '---'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _profile = null;
                      _curpController.clear();
                    });
                  },
                  child: const Text('Start Over', style: TextStyle(color: Colors.white60)),
                )
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 14)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
