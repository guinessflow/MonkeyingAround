import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '/utils/database_helper.dart';
import 'add_category_screen.dart';

class CategoriesScreen extends StatefulWidget {
  final Function backButton;

  const CategoriesScreen({super.key, required this.backButton});

  @override
  _CategoriesScreenState createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final FocusNode _focusNode = FocusNode();
  final Map<String, bool> _isEditing = {};
  final Map<String, TextEditingController> _controllers = {};
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final Map<String, double> _uploadProgress = {};

  @override
  void dispose() {
    _focusNode.dispose();
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
        final ref = storageRef.child('files/Categories/$sanitizedFilename$extension');
        final uploadTask = ref.putFile(file);

        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          double progress = snapshot.bytesTransferred / snapshot.totalBytes;
          setState(() {
            _uploadProgress[id] = progress;
          });
        });

        await uploadTask;

        String imageURL = await ref.getDownloadURL();

        final sanitizedCategoryName = sanitizeFilename(data['name']);
        final localPath = path.join(await getLocalPath(), '$sanitizedFilename$extension');
        await file.copy(localPath);

        await FirebaseFirestore.instance
            .collection('categories')
            .doc(id)
            .update({
          'icon_remote': imageURL,
          'icon_local': localPath,
          'timestamp': FieldValue.serverTimestamp(),
        });

        await DatabaseHelper.updateCategory({
          'id': id,
          'name': data['name'],
          'icon_remote': imageURL,
          'icon_local': localPath,
          'timestamp': DateTime.now().toIso8601String(),
        });

        setState(() {
          _uploadProgress.remove(id);
          data['icon_local'] = localPath;
          data['icon_remote'] = imageURL;
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

    CollectionReference categories =
    FirebaseFirestore.instance.collection('categories');
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _controllers.forEach((key, controller) async {
          String currentName = await categories.doc(key).get().then(
                  (doc) => (doc.data() as Map<String, dynamic>)['name'] ?? '');
          if (currentName != controller.text) {
            await categories.doc(key).update({
              'name': controller.text,
              'timestamp': FieldValue.serverTimestamp(),
            });
          }
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => widget.backButton(),
        ),
      ),
      body: Stack(
        children: [
          Column(
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
                          builder: (context) => const AddCategoryScreen(),
                        ),
                      );
                      if (result != null && result) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text(
                              'Category added successfully')),
                        );
                      }
                    },
                    child: const Text('Add New Category'),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _uploadProgress.isNotEmpty
                    ? LinearProgressIndicator(
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
                      ? categories.orderBy('timestamp', descending: true).snapshots()
                      : categories
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
                          DataColumn(label: Text('Category Name')),
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
                          _controllers[id] ??=
                              TextEditingController(text: data['name']);
                          return DataRow(
                            cells: [
                              DataCell(
                                Container(
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                    children: [
                                      if (data['icon_remote'] != null)
                                        Padding(
                                          padding:
                                          const EdgeInsets.only(right: 8.0),
                                          child: Image(
                                            image: CachedNetworkImageProvider(
                                                data['icon_remote']),
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
                                              await categories.doc(id).update({
                                                'name': value,
                                                'timestamp':
                                                FieldValue.serverTimestamp(),
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
                                      icon: Icon(
                                          editing ? Icons.save : Icons.edit),
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
                                              title: const Text(
                                                  'Confirm Deletion'),
                                              content: const Text(
                                                  'Are you sure you want to delete this category?'),
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
                                                    await categories.doc(id).delete();
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
        ],
      ),
    );
  }
}

