import 'package:flutter/material.dart';
import 'package:rent_mate/config/app_theme.dart';
import 'package:rent_mate/utils/demo_data_generator.dart';

class DataGeneratorScreen extends StatefulWidget {
  const DataGeneratorScreen({super.key});

  @override
  State<DataGeneratorScreen> createState() => _DataGeneratorScreenState();
}

class _DataGeneratorScreenState extends State<DataGeneratorScreen> {
  final DemoDataGenerator _generator = DemoDataGenerator();
  bool _isLoading = false;
  String? _statusMessage;
  bool _success = false;

  Future<void> _generateData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Generating demo data...';
      _success = false;
    });

    try {
      await _generator.generateDemoData();
      
      setState(() {
        _statusMessage = 'Demo data generated successfully!';
        _success = true;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error generating data: ${e.toString()}';
        _success = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demo Data Generator'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.data_array,
                size: 80,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 24),
              Text(
                'Demo Data Generator',
                style: AppTheme.headingStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Use this tool to generate realistic property listings with images for demo purposes.',
                style: AppTheme.captionStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _generateData,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Generate Demo Listings'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const CircularProgressIndicator(),
              if (_statusMessage != null && !_isLoading)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _success ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _success ? Colors.green : Colors.red,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _success ? Icons.check_circle : Icons.error,
                        color: _success ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _statusMessage!,
                          style: TextStyle(
                            color: _success ? Colors.green[800] : Colors.red[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
