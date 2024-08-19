import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationSettingsScreen extends StatefulWidget {
  final VoidCallback backButton;

  const NotificationSettingsScreen({super.key, required this.backButton});

  @override
  _NotificationSettingsScreenState createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final TextEditingController _notificationTypeController = TextEditingController();
  final TextEditingController _topicController = TextEditingController();
  bool _editMode = false;
  String? _selectedRow;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.backButton,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('notifications_settings').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    var documents = snapshot.data!.docs;
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Notification Type')),
                          DataColumn(label: Text('Topic')),
                          DataColumn(label: Text('Action')),
                        ],
                        rows: documents.map((doc) {
                          var data = doc.data() as Map<String, dynamic>;
                          var notificationType = data['notification_type'] ?? '';
                          var topic = data['topic'] ?? '';
                          var documentId = doc.id;
                          return DataRow(
                            selected: _selectedRow == documentId,
                            onSelectChanged: (value) {
                              setState(() {
                                _selectedRow = value != null && value ? documentId : null;
                              });
                            },
                            cells: [
                              DataCell(
                                _editMode && _selectedRow == documentId
                                    ? Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: TextFormField(
                                    controller: _notificationTypeController,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 10.0),
                                    ),
                                    style: const TextStyle(fontSize: 16.0),
                                  ),
                                )
                                    : Text(notificationType),
                              ),
                              DataCell(
                                _editMode && _selectedRow == documentId
                                    ? Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: TextFormField(
                                    controller: _topicController,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 10.0),
                                    ),
                                    style: const TextStyle(fontSize: 16.0),
                                  ),
                                )
                                    : Text(topic),
                              ),
                              DataCell(
                                Row(
                                  children: [
                                    if (!_editMode)
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () {
                                          setState(() {
                                            _editMode = true;
                                            _selectedRow = documentId;
                                            _notificationTypeController.text = notificationType;
                                            _topicController.text = topic;
                                          });
                                        },
                                      ),
                                    if (_editMode && _selectedRow == documentId)
                                      IconButton(
                                        icon: const Icon(Icons.save),
                                        onPressed: () {
                                          updateData(documentId);
                                          setState(() {
                                            _editMode = false;
                                            _selectedRow = null;
                                          });
                                        },
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Confirm Delete'),
                                            content: const Text('Are you sure you want to delete this data?'),
                                            actions: [
                                              TextButton(
                                                child: const Text('Cancel'),
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                              ),
                                              TextButton(
                                                child: const Text('Delete'),
                                                onPressed: () {
                                                  deleteData(documentId);
                                                  Navigator.of(context).pop();
                                                },
                                              ),
                                            ],
                                          ),
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

                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              ),
              const SizedBox(height:            16.0,
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                child: const Text('Add New Notification'),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Add New Notification'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: _notificationTypeController,
                            decoration: const InputDecoration(
                              labelText: 'Notification Type',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10.0),
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          TextFormField(
                            controller: _topicController,
                            decoration: const InputDecoration(
                              labelText: 'Topic',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10.0),
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          child: const Text('Cancel'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: const Text('Save'),
                          onPressed: () {
                            addData();
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );

  }

  void addData() {
    String notificationType = _notificationTypeController.text.trim();
    String topic = _topicController.text.trim();
    if (notificationType.isNotEmpty && topic.isNotEmpty) {
      FirebaseFirestore.instance.collection('notifications_settings').add({
        'notification_type': notificationType,
        'topic': topic,
      }).then((_) {
        _notificationTypeController.clear();
        _topicController.clear();
      }).catchError((error) {
        print('Error adding data: $error');
      });
    }
  }

  void updateData(String documentId) {
    String notificationType = _notificationTypeController.text.trim();
    String topic = _topicController.text.trim();
    if (notificationType.isNotEmpty && topic.isNotEmpty) {
      FirebaseFirestore.instance.collection('notifications_settings').doc(documentId).update({
        'notification_type': notificationType,
        'topic': topic,
      }).then((_) {
        _notificationTypeController.clear();
        _topicController.clear();
      }).catchError((error) {
        print('Error updating data: $error');
      });
    }
  }

  void deleteData(String documentId) {
    FirebaseFirestore.instance.collection('notifications_settings').doc(documentId).delete().catchError((error) {
      print('Error deleting data: $error');
    });
  }
}