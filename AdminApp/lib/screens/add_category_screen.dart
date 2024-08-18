import 'dart:async';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '/services/firebase_service.dart';
import '/utils/database_helper.dart';


class AddCategoryScreen extends StatefulWidget {
  final VoidCallback? backButton;

  const AddCategoryScreen({super.key, this.backButton});

  @override
  _AddCategoryScreenState createState() => _AddCategoryScreenState();
}

class UploadProgressIndicator extends StatefulWidget {
  final Stream<double> progressStream;

  const UploadProgressIndicator({super.key, required this.progressStream});

  @override
  _UploadProgressIndicatorState createState() => _UploadProgressIndicatorState();
}

class _UploadProgressIndicatorState extends State<UploadProgressIndicator> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<double>(
      stream: widget.progressStream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          double progress = snapshot.data!;
          return Text('${(progress * 100).toStringAsFixed(0)}% uploaded');
        }
        return Container();
      },
    );
  }
}

class _AddCategoryScreenState extends State<AddCategoryScreen> with ChangeNotifier {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirebaseService _firebaseService = FirebaseService();
  String _categoryName = '';
  File? _categoryIcon;
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  XFile? pickedFile;
  bool _isUploading = false;
  final StreamController<double> _uploadProgressStreamController = StreamController<double>();

  @override
  void dispose() {
    _uploadProgressStreamController.close();
    super.dispose();
  }


  Future<File?> _saveFileToLocal(XFile file, String fileName) async {
    final appDir = await getApplicationDocumentsDirectory();
    final localPath = '${appDir.path}/$fileName';
    final savedFile = await File(file.path).copy(localPath);
    return savedFile;
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }



  String sanitizeFilename(String filename) {
    String sanitized = filename.replaceAll(' ', '_');
    sanitized = sanitized.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
    return sanitized;
  }

  Future<void> _pickIcon() async {
    final pickedFileTemp = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFileTemp != null) {
      setState(() {
        pickedFile = pickedFileTemp;
        _categoryIcon = File(pickedFile!.path); // Add this line to update _categoryIcon
      });
    }
  }


  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final existingCategories = await _firebaseService.categories
          .where('name', isEqualTo: _categoryName)
          .get();

      if (existingCategories.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Category already exists. Please use a different name.'),
          ),
        );
        return;
      }

      if (pickedFile != null) {
        String baseFilename = path.basenameWithoutExtension(pickedFile!.path);
        String sanitizedFilename = sanitizeFilename(baseFilename);
        String extension = path.extension(pickedFile!.path);

        try {
          setState(() {
            _isUploading = true; // Set the flag to true when starting the upload
          });

          final storageRef = FirebaseStorage.instance.ref();
          final ref = storageRef.child('files/Categories/$sanitizedFilename$extension');
          final uploadTask = ref.putFile(File(pickedFile!.path));

          uploadTask.snapshotEvents.listen(
                (TaskSnapshot snapshot) {
              double progress =
                  snapshot.bytesTransferred / snapshot.totalBytes;
              _uploadProgressStreamController.add(progress);
            },
            onDone: () {
              setState(() {
                _isUploading = false; // Set the flag to false when the upload is completed
              });
            },
            onError: (error) {
              setState(() {
                _isUploading = false; // Set the flag to false if there is an error
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Icon upload failed. Please try again.'),
                ),
              );
            },
          );

          await uploadTask;

          String iconRemoteUrl = await ref.getDownloadURL();
          print('Icon Remote URL: $iconRemoteUrl');

          final sanitizedCategoryName = sanitizeFilename(_categoryName);
          final localPath =
          path.join(await _localPath, '$sanitizedFilename$extension');

          final File localFile = File(localPath);
          await localFile.writeAsBytes(await File(pickedFile!.path).readAsBytes());

          final timestamp = DateTime.now().millisecondsSinceEpoch;

          await _firebaseService.addCategory({
            'name': _categoryName,
            'icon_remote': iconRemoteUrl,
            'icon_local': localPath,
            'timestamp': timestamp,
          });

          await DatabaseHelper.instance.addCategory({
            'name': _categoryName,
            'icon_remote': iconRemoteUrl,
            'icon_local': localPath,
            'timestamp': timestamp,
          });
        } catch (e) {
          print(e);
          setState(() {
            _isUploading = false; // Set the flag to false in case of an exception
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a category image'),
          ),
        );
        return;
      }

      Navigator.pop(context, true);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Category'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.backButton != null) {
              widget.backButton!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
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
              _categoryIcon == null
                  ? const Text('No icon selected.')
                  : Image.file(_categoryIcon!, height: 100, width: 100),
              TextButton(
                onPressed: _pickIcon,
                child: const Text('Select Category Icon'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Add Category'),
              ),
              if (_isUploading)
                const CircularProgressIndicator(),
              UploadProgressIndicator(progressStream: _uploadProgressStreamController.stream),
            ],
          ),
        ),
      ),
    );
  }
}