import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  final VoidCallback? backButton;

  const PrivacyScreen({Key? key, this.backButton}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: backButton,
        ),
      ),
      body: const Center(child: Text('Privacy Screen')),
    );
  }
}
