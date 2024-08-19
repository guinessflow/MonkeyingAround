import 'package:flutter/material.dart';

class EditAuthorsScreen extends StatelessWidget {
  final VoidCallback? backButton;

  const EditAuthorsScreen({Key? key, this.backButton}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Authors'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: backButton,
        ),
      ),
      body: const Center(child: Text('Edit Authors Screen')),
    );
  }
}
