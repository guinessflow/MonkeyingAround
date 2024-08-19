import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '/utils/database_helper.dart';
import 'add_author_screen.dart';

void defaultBackButton() {}

class AuthorsScreen extends StatefulWidget {
  final Function backButton;

<<<<<<< Updated upstream
  const AuthorsScreen({Key? key, this.backButton = defaultBackButton}) : super(key: key);
=======
  const AuthorsScreen({super.key, this.backButton = defaultBackButton});
>>>>>>> Stashed changes

  @override
  _AuthorsScreenState createState() => _AuthorsScreenState();
}

class _AuthorsScreenState extends State<AuthorsScreen> {
  final FocusNode _focusNode = FocusNode();
  final Map<String, bool> _isEditing = {};
  final Map<String, TextEditingController> _controllers = {};
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final Map<String, double> _uploadProgress = {};

  @override
  void dispose() {
    super.dispose();
  }

  void _toggleEditing(String id, bool value) {
    setState(() {
      _isEditing[id] = value;
    });
  }

  Future<String> getLocalPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    return appDir.path;
  }

  String sanitizeFilename(String filename) {
    // Replace spaces with underscores
    String sanitized = filename.replaceAll(' ', '_');

    // Remove any non-alphanumeric characters (except underscores)
    sanitized = sanitized.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');

    return sanitized;
  }

  Future<void> _pickImageAndSave(String id, Map<String, dynamic> data) async {
    final ImagePicker picker = ImagePicker();
    XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      File file = File(image.path);

      // Sanitize the filename
      String baseFilename = path.basenameWithoutExtension(file.path);
      String sanitizedFilename = sanitizeFilename(baseFilename);
      String extension = path.extension(file.path);

      try {
        // Remote file upload
        final storageRef = FirebaseStorage.instance.ref();
        final ref = storageRef.child('files/Authors/$sanitizedFilename$extension');
        final uploadTask = ref.putFile(file);

        uploadTask.snapshotEvents.listen((TaskSnapshot event) {
          double progress = event.bytesTransferred.toDouble() / event.totalBytes.toDouble();
          setState(() {
            _uploadProgress[id] = progress;
          });
        });

        await uploadTask;

        String imageRemoteUrl = await ref.getDownloadURL();

        final sanitizedAuthorName = sanitizeFilename(data['name']);
        final localPath = path.join(await getLocalPath(), '$sanitizedFilename$extension');
        await file.copy(localPath);

        await FirebaseFirestore.instance.collection('authors').doc(id).update({
          'image_remote': imageRemoteUrl,
          'image_local': localPath,
          'timestamp': FieldValue.serverTimestamp(),
        });

        await DatabaseHelper.updateAuthor({
          'id': id,
          'name': data['name'],
          'image_remote': imageRemoteUrl,
          'image_local': localPath,
          'timestamp': DateTime.now().toIso8601String(),
        });

        setState(() {
          _uploadProgress.remove(id);
          data['image_local'] = localPath;
          data['image_remote'] = imageRemoteUrl;
        });
      } catch (e) {
        print(e);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload image')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    void clearSearch() {
      setState(() {
        _searchController.clear();
        _searchQuery = '';
      });
      FocusScope.of(context).unfocus();
    }

    CollectionReference authors =
    FirebaseFirestore.instance.collection('authors');

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _controllers.forEach((key, controller) async {
          String currentName = await authors.doc(key).get().then(
                (doc) => (doc.data() as Map<String, dynamic>)['name'] ?? '',
          );
          if (currentName != controller.text) {
            await authors.doc(key).update({
              'name': controller.text,
              'timestamp': FieldValue.serverTimestamp(),
            });
          }
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Authors'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => widget.backButton(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16.0, vertical: 8.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  bool? result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddAuthorScreen(),
                    ),
                  );
                  if (result != null && result) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Author added successfully'),
                      ),
                    );
                  }
                },
                child: const Text('Add New Author'),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _uploadProgress.isNotEmpty
                ? CircularProgressIndicator(
              value: _uploadProgress.values.reduce((a, b) => a + b) /
                  _uploadProgress.length,
            )
                : const SizedBox.shrink(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _uploadProgress.isNotEmpty
                ? Text(
              '${((_uploadProgress.values.reduce((a, b) => a + b) / _uploadProgress.length) * 100).toStringAsFixed(1)}%',
            )
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _searchQuery.isEmpty
                  ? authors.orderBy('timestamp', descending: true).snapshots()
                  : authors
                  .orderBy('name')
                  .startAt([_searchQuery])
                  .endAt(['$_searchQuery\uf8ff'])
                  .snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return const Text('Something went wrong');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                return SingleChildScrollView(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Author Name')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: snapshot.data!.docs.map((
                        DocumentSnapshot document,
                        ) {
                      Map<String, dynamic> data =
                      document.data() as Map<String, dynamic>;
                      String id = document.id;
                      bool editing = _isEditing[id] ?? false;

                      TextEditingController controller =
                      _controllers[id] ??= TextEditingController(text: data['name']);
                      return DataRow(
                        cells: [
                          DataCell(
                            Container(
                              alignment: Alignment.centerLeft,
                              child: Row(
                                children: [
                                  if (data['image_remote'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8.0),
                                      child: Image(
                                        image: CachedNetworkImageProvider(data['image_remote']),
                                        width: 24,
                                        height: 24,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  Expanded(
                                    child: Container(
                                      child: editing
                                          ? TextFormField(
                                        controller: controller,
                                        focusNode: _focusNode,
                                        onFieldSubmitted: (value) async {
                                          await authors.doc(id).update({
                                            'name': value,
                                            'timestamp': FieldValue.serverTimestamp(),
                                          });
                                          _toggleEditing(id, false);
                                        },
                                      )
                                          : FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(data['name']),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(editing ? Icons.save : Icons.edit),
                                  onPressed: () {
                                    if (editing) {
                                      FocusScope.of(context).unfocus();
                                    }
                                    _toggleEditing(id, !editing);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.image),
                                  onPressed: () async {
                                    await _pickImageAndSave(id, data);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () async {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text('Confirm Deletion'),
                                          content: const Text('Are you sure you want to delete this author?'),
                                          actions: [
                                            TextButton(
                                              child: const Text('Cancel'),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                            TextButton(
                                              child: const Text('Delete'),
                                              onPressed: () async {
                                                Navigator.of(context).pop();
                                                await authors.doc(id).delete();
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
