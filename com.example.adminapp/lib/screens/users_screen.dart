import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

void defaultBackButton() {}

class UsersScreen extends StatefulWidget {
  final Function backButton;

  const UsersScreen({super.key, this.backButton = defaultBackButton});

  @override
  _UsersScreenState createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
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
    CollectionReference users =
    FirebaseFirestore.instance.collection('user_devices');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => widget.backButton(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: users
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
                return const Text('No users available');
              }

              final List<DocumentSnapshot> usersList = snapshot.data!.docs;

              final int totalRows = usersList.length;
              final int startIndex = currentPage * rowsPerPage;
              final int endIndex = startIndex + rowsPerPage;

              final List<DataRow> rows = [];

              if (startIndex >= totalRows) {
                currentPage--;
              }

              for (int i = startIndex; i < endIndex && i < totalRows; i++) {
                final DocumentSnapshot document = usersList[i];
                final Map<String, dynamic> data = document.data() as Map<String, dynamic>;
                final String id = document.id;

                rows.add(
                  DataRow(
                    cells: [
                      DataCell(Text(data['user_id'] ?? '')),
                      DataCell(Text(data['device_name'] ?? '')),
                      DataCell(Text(data['ip_address'] ?? '')),
                      DataCell(Text((data['notification_subscription']).toString())),
                      DataCell(Text(data['install_status'] ?? '')),
                      DataCell(Text(data['last_active'] ?? '')),
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
                                  content: const Text('Are you sure you want to delete this user?'),
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
                                            .collection('user_devices')
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
              // Calculate total installed and uninstalled users
              final int installedUsersCount = usersList.where((doc) => doc['install_status'] == 'Installed').length;
              final int uninstalledUsersCount = usersList.where((doc) => doc['install_status'] == 'Uninstalled').length;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // Align children to the left
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 10, top: 10), // Add padding to the left and top
                      child: Text(
                        'Total Users: $totalRows',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Text(
                        'Installed Users: $installedUsersCount',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Text(
                        'Uninstalled Users: $uninstalledUsersCount',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    DataTable(
                      columns: const [
                        DataColumn(label: Text('User ID')),
                        DataColumn(label: Text('Device Name')),
                        DataColumn(label: Text('IP Address')),
                        DataColumn(label: Text('Notification')),
                        DataColumn(label: Text('Install Status')),
                        DataColumn(label: Text('Last Active')),
                        DataColumn(label: Text('Install Time')),
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