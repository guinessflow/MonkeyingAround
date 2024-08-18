import 'dart:async';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '/services/firebase_service.dart';
import '/utils/database_helper.dart';


class AddCultureScreen extends StatefulWidget {
  final VoidCallback? backButton;

  const AddCultureScreen({super.key, this.backButton});

  @override
  _AddCultureScreenState createState() => _AddCultureScreenState();
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


class _AddCultureScreenState extends State<AddCultureScreen> {

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirebaseService _firebaseService = FirebaseService();
  String _cultureName = '';
  File? _cultureImage;
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

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }


  String sanitizeFilename(String filename) {
    String sanitized = filename.replaceAll(' ', '_');
    sanitized = sanitized.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
    return sanitized;
  }

  Future<void> _pickImage() async {
    final pickedFileTemp = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFileTemp != null) {
      setState(() {
        pickedFile = pickedFileTemp;
        _cultureImage = File(pickedFile!.path);
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final existingCultures = await _firebaseService.cultures
          .where('name', isEqualTo: _cultureName)
          .get();

      if (existingCultures.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Culture already exists. Please use a different name.'),
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

          // Remote file upload
          final storageRef = FirebaseStorage.instance.ref();
          final ref = storageRef.child('files/Cultures/$sanitizedFilename$extension');
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
                  content: Text('Image upload failed. Please try again.'),
                ),
              );
            },
          );

          await uploadTask;

          String imageRemoteUrl = await ref.getDownloadURL();

          final localPath = path.join(await _localPath, '$sanitizedFilename$extension');
          final File localFile = File(localPath);
          await localFile.writeAsBytes(await File(pickedFile!.path).readAsBytes());

          final timestamp = DateTime.now().millisecondsSinceEpoch;

          await _firebaseService.addCulture({
            'name': _cultureName,
            'image_remote': imageRemoteUrl,
            'image_local': localPath,
            'timestamp': timestamp,
          });

          await DatabaseHelper.instance.addCulture({
            'name': _cultureName,
            'image_remote': imageRemoteUrl,
            'image_local': localPath,
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
            content: Text('Please select a culture image'),
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
        title: const Text('Add Culture'),
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
                decoration: const InputDecoration(labelText: 'Culture Name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an culture name';
                  }
                  return null;
                },
                onSaved: (value) {
                  _cultureName = value!.trim();
                },
              ),
              const SizedBox(height: 16),
              _cultureImage == null
                  ? const Text('No image selected.')
                  : Image.file(_cultureImage!, height: 100, width: 100),
              TextButton(
                onPressed: _pickImage,
                child: const Text('Select Culture Image'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Add Culture'),
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
