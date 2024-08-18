import 'dart:async';
import 'package:flutter/material.dart';
import '/models/database_helper.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({Key? key}) : super(key: key);

  @override
  _StartScreenState createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  String _appName = '';
  String _selectedFontFamily = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAppSettings();
    Timer(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/main');
      }
    });
  }

  void _fetchAppSettings() async {
    try {
      Map<String, dynamic> appSettings = await DatabaseHelper.fetchAppSettings();

      setState(() {
        _appName = appSettings['appName']; // Update the app name
        _selectedFontFamily = appSettings['fontFamily'];
        _isLoading = false; // Set loading state to false when data is loaded
      });
    } catch (error) {
      setState(() {
        _isLoading = false; // Set loading state to false on error
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              _appName, // Use the dynamic app name here
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFamily: _selectedFontFamily,
              ),
            ),
            SizedBox(height: 20),
            // Additional widgets as needed
          ],
        ),
      ),
    );
  }
}
