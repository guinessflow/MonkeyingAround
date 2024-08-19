import 'package:flutter/material.dart';

class EditContentScreen extends StatelessWidget {
  final VoidCallback? backButton;

<<<<<<< Updated upstream
  const EditContentScreen({Key? key, this.backButton}) : super(key: key);
=======
  const EditContentScreen({super.key, this.backButton});
>>>>>>> Stashed changes

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Content'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: backButton,
        ),
      ),
      body: const Center(child: Text('Edit Content Screen')),
    );
  }
}
