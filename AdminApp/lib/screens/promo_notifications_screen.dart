import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

void defaultBackButton() {}

class PromoNotificationsScreen extends StatefulWidget {
  final Function backButton;

  const PromoNotificationsScreen({super.key, this.backButton = defaultBackButton});

  @override
  _PromoNotificationsScreenState createState() => _PromoNotificationsScreenState();
}

class _PromoNotificationsScreenState extends State<PromoNotificationsScreen> {
  final int rowsPerPage = 5;
  int currentPage = 0;
  late TextEditingController _searchController;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    CollectionReference notifications =
    FirebaseFirestore.instance.collection('promo_notifications');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Promo Notifications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => widget.backButton(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                    currentPage = 0;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Search',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: notifications
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return const Text('Something went wrong');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                  return const Text('No promo notifications available');
                }

                final List<DocumentSnapshot> notificationsList = snapshot.data!.docs;

                final int totalRows = notificationsList.length;
                final int startIndex = currentPage * rowsPerPage;
                final int endIndex = startIndex + rowsPerPage;

                final List<DataRow> rows = [];

                if (startIndex >= totalRows) {
                  currentPage--;
                }

                for (int i = startIndex; i < endIndex && i < totalRows; i++) {
                  final DocumentSnapshot document = notificationsList[i];
                  final Map<String, dynamic> data = document.data() as Map<String, dynamic>;
                  final String id = document.id;

                  rows.add(
                    DataRow(
                      cells: [
                        DataCell(Text((data['user_id'] ?? '').toString())),
                        DataCell(Text((data['topic'] ?? '').toString())),
                        DataCell(Text(data['title'] ?? '')),
                        DataCell(Text(data['message'] ?? '')),
                        DataCell(Text(data['seen'].toString())), // Convert bool value to String
                        DataCell(Text((data['timestamp'] as Timestamp).toDate().toString())),
                        DataCell(
                          TextButton(
                            child: const Icon(Icons.delete),
                            onPressed: () async {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Confirm Deletion'),
                                    content: const Text('Are you sure you want to delete this promo notification?'),
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
                                          await FirebaseFirestore.instance
                                              .collection('promo_notifications')
                                              .doc(id)
                                              .delete();
                                        },
                                      ),
                                    ],
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

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // Align children to the left
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 10, top: 10), // Add padding to the left and top
                        child: Text(
                          'Total Promo Notifications: $totalRows',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      DataTable(
                        columns: const [
                          DataColumn(label: Text('User ID')),
                          DataColumn(label: Text('Topic')),
                          DataColumn(label: Text('Title')),
                          DataColumn(label: Text('Message')),
                          DataColumn(label: Text('Seen')),
                          DataColumn(label: Text('Sent Time')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: rows,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center, // Align children vertically in the center
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: (currentPage > 0)
                                ? () {
                              setState(() {
                                currentPage--;
                              });
                            }
                                : null, // Disable the previous arrow key if there are no more previous pages
                          ),
                          Text('Page ${currentPage + 1}'),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward),
                            onPressed: (endIndex < totalRows)
                                ? () {
                              setState(() {
                                currentPage++;
                              });
                            }
                                : null, // Disable the next arrow key if there are no more pages
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}