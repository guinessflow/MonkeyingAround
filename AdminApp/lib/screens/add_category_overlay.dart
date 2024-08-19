import 'package:flutter/material.dart';
import '/services/firebase_service.dart';

class AddCategoryOverlay extends StatefulWidget {
  final VoidCallback onClose;

<<<<<<< Updated upstream
  const AddCategoryOverlay({Key? key, required this.onClose}) : super(key: key);
=======
  const AddCategoryOverlay({super.key, required this.onClose});
>>>>>>> Stashed changes

  @override
  _AddCategoryOverlayState createState() => _AddCategoryOverlayState();
}

class _AddCategoryOverlayState extends State<AddCategoryOverlay> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirebaseService _firebaseService = FirebaseService();
  String _categoryName = '';

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      await _firebaseService.addCategory({'name': _categoryName});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category added successfully')),
      );
      widget.onClose();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Category Name'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a category name';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _categoryName = value!.trim();
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: _submitForm,
                          child: const Text('Add Category'),
                        ),
                        TextButton(
                          onPressed: widget.onClose,
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
