import 'package:flutter/material.dart';

class ContactUsScreen extends StatelessWidget {
  final VoidCallback? backButton;

  const ContactUsScreen({Key? key, this.backButton}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Us'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: backButton,
        ),
      ),
      body: const Center(child: Text('Contact Us Screen')),
    );
  }
}
