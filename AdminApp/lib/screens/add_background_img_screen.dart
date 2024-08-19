import 'dart:async';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '/services/firebase_service.dart';


class AddBackgroundImgScreen extends StatefulWidget {
  final VoidCallback? backButton;

<<<<<<< Updated upstream
  const AddBackgroundImgScreen({Key? key, this.backButton}) : super(key: key);
=======
  const AddBackgroundImgScreen({super.key, this.backButton});
>>>>>>> Stashed changes

  @override
  _AddBackgroundImgScreenState createState() => _AddBackgroundImgScreenState();
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

class _AddBackgroundImgScreenState extends State<AddBackgroundImgScreen> with ChangeNotifier {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirebaseService _firebaseService = FirebaseService();
  String _backgroundImgName = '';
  File? _backgroundImg;
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  XFile? pickedFile;
  final bool _isUploading = false;
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

  Future<void> _pickImage() async {
    final pickedFileTemp = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFileTemp != null) {
      setState(() {
        pickedFile = pickedFileTemp;
        _backgroundImg = File(pickedFile!.path); // Add this line to update _categoryIcon
      });
    }
  }


  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final existingBackgrounds =
      await _firebaseService.categories.where('id', isEqualTo: _backgroundImgName).get();

      if (existingBackgrounds.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Background image already exists. Please use a different name.')),
        );
        return;
      }

      if (pickedFile != null) {
        String baseFilename = path.basenameWithoutExtension(pickedFile!.path);
        String sanitizedFilename = sanitizeFilename(baseFilename);
        String extension = path.extension(pickedFile!.path);

        try {
          // Remote file upload
          final storageRef = FirebaseStorage.instance.ref();
          final ref = storageRef.child('files/Background/$sanitizedFilename$extension');
          final uploadTask = ref.putFile(File(pickedFile!.path));

          uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
            if (snapshot.state == TaskState.running) {
              double progress = snapshot.bytesTransferred / snapshot.totalBytes;
              _uploadProgressStreamController.add(progress);
            }
          });

          final TaskSnapshot taskSnapshot = await uploadTask;

          // Local file save
          final sanitizedBackgroundImgName = sanitizeFilename(_backgroundImgName);
          final localPath = path.join(await _localPath, '$sanitizedBackgroundImgName$extension');
          final File localFile = File(localPath);
          await localFile.writeAsBytes(await File(pickedFile!.path).readAsBytes());

          if (taskSnapshot.state == TaskState.success) {
            final String backImgRemoteUrl = await taskSnapshot.ref.getDownloadURL();
            print('BackImg Remote URL: $backImgRemoteUrl');
            print('BackImg Local URL: $localPath');
            print('Background Img Name: $_backgroundImgName');

            final timestamp = DateTime.now().millisecondsSinceEpoch;

            await _firebaseService.addBackgroundImg({
              'id': _backgroundImgName,
              'back_img_remote_url': backImgRemoteUrl,
              'back_img_local_url': localPath,
              'timestamp': timestamp,
            });

            // Save the category to the local SQLite database
            // Replace this with the actual method to save the category to your local database
          /*  await DatabaseHelper.instance.addBackgroundImg({
              'id': _backgroundImgName,
              'back_img_remote_url': backImgRemoteUrl,
              'back_img_local_url': localPath,
              'timestamp': timestamp,
            });
*/
            Navigator.pop(context, true);
            return;
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Background image upload failed. Please try again.')),
            );
          }
        } catch (e) {
          print(e);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Background image upload failed. Please try again.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a background image')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Background Image'),
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
                decoration: const InputDecoration(labelText: 'Background Image Name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a background image name';
                  }
                  return null;
                },
                onSaved: (value) {
                  _backgroundImgName = value!.trim();
                },
              ),
              const SizedBox(height: 16),
              _backgroundImg == null
                  ? const Text('No background image selected.')
                  : Image.file(_backgroundImg!, height: 100, width: 100),
              TextButton(
                onPressed: _pickImage,
                child: const Text('Select Background Image'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Add Background Image'),
              ),
              UploadProgressIndicator(progressStream: _uploadProgressStreamController.stream),
            ],
          ),
        ),
      ),
    );
  }
}