import 'package:flutter/material.dart';

class EditCulturesScreen extends StatelessWidget {
  final VoidCallback? backButton;

  const EditCulturesScreen({Key? key, this.backButton}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Cultures'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: backButton,
        ),
      ),
      body: const Center(child: Text('Edit Cultures Screen')),
    );
  }
}
