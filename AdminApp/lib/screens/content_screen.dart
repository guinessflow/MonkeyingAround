import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/services/firebase_service.dart';
import '/services/fcm_notification_manager.dart';
import 'add_content_screen.dart';
import 'home_screen.dart';

void defaultBackButton() {}

class ContentScreen extends StatefulWidget {
  final Function backButton;

  const ContentScreen({super.key, this.backButton = defaultBackButton});

  @override
  _ContentScreenState createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'category';
  String? _selectedItem;
  final List<String> _filterOptions = ['category', 'culture'];
  bool _isEditing = false;
  bool isSending = false;
  String? _editingContentId;
  final TextEditingController _editingContentController = TextEditingController();

  @override
  void dispose() {
    super.dispose();
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


    Stream<QuerySnapshot> contentStream() {
      String? filterField;
      bool isAuthorContent = _selectedFilter == 'author';
      bool isCultureContent = _selectedFilter == 'culture';

      if (_selectedFilter == 'category') {
        filterField = 'category_id';
      } else if (_selectedFilter == 'author') {
        filterField = 'author_id';
      } else if (_selectedFilter == 'culture') {
        filterField = 'culture_id';
      }

      if (_selectedItem != null && filterField != null) {
        return _firebaseService.filterContent(filterField, _selectedItem!, isAuthorContent: isAuthorContent, isCultureContent: isCultureContent);
      } else if (_searchQuery.isNotEmpty) {
        return _firebaseService.searchContent(_searchQuery, isAuthorContent: isAuthorContent, isCultureContent: isCultureContent);
      } else {
        return _firebaseService.getContent(isAuthorContent: isAuthorContent, isCultureContent: isCultureContent);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Content'),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                }
              },
            );
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedFilter,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedFilter = newValue!;
                        _selectedItem = null;
                      });
                    },
                    items: _filterOptions
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 10), // Add a SizedBox for some space between DropdownButtons
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _selectedFilter == 'category'
                        ? _firebaseService.getCategories()
                        : _selectedFilter == 'author'
                        ? _firebaseService.getAuthors()
                        : _firebaseService.getCultures(), // Use getCultures() for the new 'culture' filter
                    builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      return DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedItem,
                        hint: Text('Select $_selectedFilter'),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedItem = newValue;
                          });
                        },
                        items: snapshot.data!.docs.map((DocumentSnapshot document) {
                          Map<String, dynamic> data = document.data() as Map<String, dynamic>;
                          return DropdownMenuItem<String>(
                            value: document.id,
                            child: Text(data['name']),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
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
                      builder: (context) => const AddContentScreen(),
                    ),
                  );
                  if (result != null && result) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Content added successfully')),
                    );
                  }
                },
                child: const Text('Add New Content'),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: contentStream(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  print('Error: ${snapshot.error}');
                }
                if (snapshot.connectionState == ConnectionState.waiting || snapshot.data == null) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (BuildContext context, int index) {
                    DocumentSnapshot document = snapshot.data!.docs[index];
                    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
                    String id = document.id;

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _isEditing && _editingContentId == id
                                ? TextField(
                              controller: _editingContentController,
                              maxLines: null,
                              decoration: const InputDecoration(
                                hintText: 'Edit Content',
                              ),
                            )
                                : Text(data['content'] ?? ''),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                _isEditing && _editingContentId == id
                                    ? IconButton(
                                  icon: const Icon(Icons.save),
                                  onPressed: () async {
                                    Map<String, dynamic> updateData = {
                                      'content': _editingContentController.text,
                                      'timestamp': FieldValue.serverTimestamp(),
                                    };
                                    if (_selectedFilter == 'author') {
                                      await _firebaseService.editAuthorContent(id, updateData);
                                    } else if (_selectedFilter == 'category') {
                                      await _firebaseService.editCategoryContent(id, updateData);
                                    } else if (_selectedFilter == 'culture') { // Add this condition for the new 'culture' filter
                                      await _firebaseService.editCultureContent(id, updateData);
                                    }
                                    setState(() {
                                      _isEditing = false;
                                      _editingContentId = null;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Content updated successfully'),
                                      ),
                                    );
                                  },
                                )
                                    : IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    setState(() {
                                      _isEditing = true;
                                      _editingContentId = id;
                                      _editingContentController.text = data['content'] ?? '';
                                    });
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
                                          content: const Text('Are you sure you want to delete this content?'),
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
                                                await _firebaseService.deleteContent(
                                                  id,
                                                  _selectedFilter == 'author',
                                                  _selectedFilter == 'culture',
                                                );

                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Content deleted successfully')),
                                                );
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.send),
                                  onPressed: () async {
                                    String type = data['type'] ?? '';
                                    String content = data['content'] ?? '';
                                    String? name;
                                    String? image;
                                    String? did;
                                    String? qid;

                                    if (_selectedFilter == 'category') {
                                      type = _selectedFilter;
                                      did = data['category_id'];
                                      DocumentSnapshot categoryDoc = await _firebaseService.getCategoryById(data['category_id']);
                                      name = (categoryDoc.data() as Map<String, dynamic>?)?['name'] ?? '';
                                      image = (categoryDoc.data() as Map<String, dynamic>?)?['icon_remote'] ?? (categoryDoc.data() as Map<String, dynamic>?)?['icon_local'] ?? '';
                                    } else if (_selectedFilter == 'author') {
                                      type = _selectedFilter;
                                      did = data['author_id'];
                                      DocumentSnapshot authorDoc = await _firebaseService.getAuthorById(data['author_id']);
                                      name = (authorDoc.data() as Map<String, dynamic>?)?['name'] ?? '';
                                      image = (authorDoc.data() as Map<String, dynamic>?)?['image_remote'] ?? (authorDoc.data() as Map<String, dynamic>?)?['image_local'] ?? '';
                                    } else if (_selectedFilter == 'culture') { // Add this condition for the new 'culture' filter
                                      type = _selectedFilter;
                                      did = data['culture_id'];
                                      DocumentSnapshot cultureDoc = await _firebaseService.getCultureById(data['culture_id']);
                                      name = (cultureDoc.data() as Map<String, dynamic>?)?['name'] ?? '';
                                      image = (cultureDoc.data() as Map<String, dynamic>?)?['image_remote'] ?? (cultureDoc.data() as Map<String, dynamic>?)?['image_local'] ?? '';
                                    }

                                    // Update the code to use a try-catch block for error handling
                                    try {
                                      setState(() {
                                        isSending = true; // Set the flag to true when starting sending
                                      });
                                      // Show circular progress indicator
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (BuildContext context) {
                                          return const Dialog(
                                            child: Padding(
                                              padding: EdgeInsets.all(20.0),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  CircularProgressIndicator(),
                                                  SizedBox(width: 20.0),
                                                  Text('Sending...'),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      );

                                      await FCMNotificationManager.sendNotification(
                                        firebaseService: FirebaseService(),
                                        qid: id,
                                        did: did,
                                        type: type,
                                        content: content,
                                        name: name,
                                        image: image,
                                      );

                                      // Hide the circular progress indicator
                                      Navigator.pop(context);

                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            content: const Text('The notification has been successfully sent!'),
                                            actions: <Widget>[
                                              TextButton(
                                                child: const Text('Close'),
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    } catch (error) {
                                      // Hide the circular progress indicator
                                      Navigator.pop(context);

                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            content: const Text('Failed to send notification!'),
                                            actions: <Widget>[
                                              TextButton(
                                                child: const Text('Close'),
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    }
                                    finally {
                                      setState(() {
                                        isSending = false;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}