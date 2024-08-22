import 'package:flutter/material.dart';

class EditCategoriesScreen extends StatelessWidget {
  final VoidCallback? backButton;

  const EditCategoriesScreen({Key? key, this.backButton}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Categories'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: backButton,
        ),
      ),
      body: const Center(child: Text('Edit Categories Screen')),
    );
  }
}
