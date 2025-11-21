import 'package:flutter/material.dart';
import '../utils/debug_gerant.dart';

/// Debug screen to diagnose issues
class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  String _output = 'Tap buttons to run diagnostics...\n';
  bool _isLoading = false;

  void _addOutput(String text) {
    setState(() {
      _output += '$text\n';
    });
  }

  Future<void> _checkGerantStatus() async {
    setState(() {
      _isLoading = true;
      _output = 'Checking gerant status...\n';
    });

    try {
      await DebugGerant.checkGerantStatus('benjdidiaomar@gmail.com');
      _addOutput('✓ Check complete');
    } catch (e) {
      _addOutput('✗ Error: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _testFirestore() async {
    setState(() {
      _isLoading = true;
      _output = 'Testing Firestore connection...\n';
    });

    try {
      await DebugGerant.testFirestoreConnection();
      _addOutput('✓ Firestore test complete');
    } catch (e) {
      _addOutput('✗ Error: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _listGerants() async {
    setState(() {
      _isLoading = true;
      _output = 'Listing all gerants...\n';
    });

    try {
      await DebugGerant.listAllGerants();
      _addOutput('✓ List complete');
    } catch (e) {
      _addOutput('✗ Error: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug Console'), centerTitle: true),
      body: Column(
        children: [
          // Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _checkGerantStatus,
                  child: const Text('Check Gerant Status'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testFirestore,
                  child: const Text('Test Firestore'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _listGerants,
                  child: const Text('List All Gerants'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _output = 'Cleared\n';
                    });
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Clear Output'),
                ),
              ],
            ),
          ),
          const Divider(),
          // Output
          Expanded(
            child: Container(
              color: Colors.grey[900],
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                child: Text(
                  _output,
                  style: const TextStyle(
                    color: Colors.green,
                    fontFamily: 'Courier',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
