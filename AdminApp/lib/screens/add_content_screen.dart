import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/services/firebase_service.dart';

class AddContentScreen extends StatefulWidget {
  final String? contentId;
  final VoidCallback? backButton;
  final bool isEditing;

  const AddContentScreen(
<<<<<<< Updated upstream
      {Key? key, this.contentId, this.backButton, this.isEditing = false})
      : super(key: key);
=======
      {super.key, this.contentId, this.backButton, this.isEditing = false});
>>>>>>> Stashed changes

  @override
  _AddContentScreenState createState() => _AddContentScreenState();
}

class _AddContentScreenState extends State<AddContentScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _cultureController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  bool _isCategoryContent = true;
  bool _isCultureContent = false;
<<<<<<< Updated upstream
  bool _isAuthorContent = false;
=======
  final bool _isAuthorContent = false;
>>>>>>> Stashed changes
  String _contentText = '';
  String _selectedCategory = '';
  String _selectedAuthor = '';
  String _selectedCulture = '';
  bool _isLoading = false; // New state variable for loading indicator

  @override
  void dispose() {
    _contentController.dispose();
    _authorController.dispose();
    _categoryController.dispose();
    _cultureController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true; // Show loading indicator when starting the submission
      });

      _formKey.currentState!.save();
      List<String> contents = _contentText.trim().split('\n');
      for (String content in contents) {
        Map<String, dynamic> data = {
          'content': content,
          'timestamp': FieldValue.serverTimestamp(),
        };

        if (_isAuthorContent) {
          data['author_id'] = _selectedAuthor;
        } else if (_isCategoryContent) {
          data['category_id'] = _selectedCategory;
        } else if (_isCultureContent) {
          data['culture_id'] = _selectedCulture;
        }

        await _firebaseService.addContent(
          data,
          _isAuthorContent,
          _isCategoryContent,
          _isCultureContent,
        );
      }

      setState(() {
        _isLoading = false; // Hide loading indicator after submission
      });

      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Content'),
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
        child: Stack(
          children: [
            Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    controller: _contentController,
                    decoration: const InputDecoration(
                      labelText: 'Content (one per line)',
                    ),
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter at least one line of content';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _contentText = value!;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Select Type'),
                    value: _isCategoryContent ? 'Category' : 'Culture',
                    items: const [
                      DropdownMenuItem<String>(
                        value: 'Category',
                        child: Text('Category'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'Culture',
                        child: Text('Culture'),
                      ),
                    ],
                    onChanged: (String? newValue) {
                      setState(() {
                        _isCategoryContent = newValue == 'Category';
                        _isCultureContent = newValue == 'Culture';
                        _selectedCategory = '';
                        _selectedCulture = '';
                      });
                    },
                    validator: (String? value) {
                      if (value == null) {
                        return 'Please select a type';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_isAuthorContent)
                    StreamBuilder<QuerySnapshot>(
                      stream: _firebaseService.getAuthors(),
                      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (snapshot.hasData) {
                          return _buildDropdown(
                            snapshot,
                            'Author',
                            _selectedAuthor,
                                (value) {
                              setState(() {
                                _selectedAuthor = value!;
                              });
                            },
                                (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select an author';
                              }
                              return null;
                            },
                          );
                        } else if (snapshot.hasError) {
                          return const Text('Error loading authors');
                        } else {
                          return const Text('No authors available');
                        }
                      },
                    )
                  else if (_isCategoryContent)
                    StreamBuilder<QuerySnapshot>(
                      stream: _firebaseService.getCategories(),
                      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (snapshot.hasData) {
                          return _buildDropdown(
                            snapshot,
                            'Category',
                            _selectedCategory,
                                (value) {
                              setState(() {
                                _selectedCategory = value!;
                              });
                            },
                                (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a category';
                              }
                              return null;
                            },
                          );
                        } else if (snapshot.hasError) {
                          return const Text('Error loading categories');
                        } else {
                          return const Text('No categories available');
                        }
                      },
                    )
                  else if (_isCultureContent)
                      StreamBuilder<QuerySnapshot>(
                        stream: _firebaseService.getCultures(),
                        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          } else if (snapshot.hasData) {
                            return _buildDropdown(
                              snapshot,
                              'Culture',
                              _selectedCulture,
                                  (value) {
                                setState(() {
                                  _selectedCulture = value!;
                                });
                              },
                                  (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select a culture';
                                }
                                return null;
                              },
                            );
                          } else if (snapshot.hasError) {
                            return const Text('Error loading cultures');
                          } else {
                            return const Text('No cultures available');
                          }
                        },
                      ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    child: const Text('Add Content'),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
<<<<<<< Updated upstream
                child: Center(
=======
                child: const Center(
>>>>>>> Stashed changes
                  child: CircularProgressIndicator(
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(
      AsyncSnapshot<QuerySnapshot> snapshot,
      String labelText,
      String selectedValue,
      void Function(String?) onChanged,
      String? Function(String?) validator,
      ) {
    if (snapshot.hasData) {
      List<DropdownMenuItem<String>> items = snapshot.data!.docs.map((doc) {
        return DropdownMenuItem<String>(
          value: doc.id,
          child: Text(doc['name']),
        );
      }).toList();

      return DropdownButtonFormField<String>(
        decoration: InputDecoration(labelText: labelText),
        value: selectedValue.isNotEmpty ? selectedValue : null,
        items: items,
        onChanged: onChanged,
        validator: validator,
      );
    } else if (snapshot.hasError) {
      return const Text('Error loading data');
    } else {
      return const CircularProgressIndicator();
    }
  }
}

