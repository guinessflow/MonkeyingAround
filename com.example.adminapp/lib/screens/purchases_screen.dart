import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

void defaultBackButton() {}

class PurchasesScreen extends StatefulWidget {
  final Function backButton;

  const PurchasesScreen({super.key, this.backButton = defaultBackButton});

  @override
  _PurchasesScreenState createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
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
    CollectionReference purchases =
    FirebaseFirestore.instance.collection('purchases');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchases'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => widget.backButton(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
      children: [
      StreamBuilder<QuerySnapshot>(
        stream: purchases
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
            return const Text('No purchases available');
          }

          final List<DocumentSnapshot> purchasesList = snapshot.data!.docs;

          final int totalRows = purchasesList.length;
          final int startIndex = currentPage * rowsPerPage;
          final int endIndex = startIndex + rowsPerPage;

          final List<DataRow> rows = [];

          if (startIndex >= totalRows) {
            currentPage--;
          }

          for (int i = startIndex; i < endIndex && i < totalRows; i++) {
            final DocumentSnapshot document = purchasesList[i];
            final Map<String, dynamic> data = document.data() as Map<String, dynamic>;
            final String id = document.id;

            rows.add(
              DataRow(
                cells: [
                  DataCell(Text(data['productId'] ?? '')),
                  DataCell(Text(data['purchaseId'] ?? '')),
                  DataCell(Text(data['purchaseStatus'] ?? '')),
                  DataCell(Text((data['timestamp'] as Timestamp).toDate().toString())),
                  DataCell(Text(data['userId'] ?? '')),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Confirm Deletion'),
                              content: const Text('Are you sure you want to delete this purchase?'),
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
                                        .collection('purchases')
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

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Align children to the left
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 10, top: 10), // Add padding to the left and top
                child: Text(
                  'Total Purchases: $totalRows',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Product ID')),
                    DataColumn(label: Text('Purchase ID')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Timestamp')),
                    DataColumn(label: Text('User ID')),
                    DataColumn(label: Text('Action')),
                  ],
                  rows: rows,
                ),
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
          );
        },
      ),
      ],
    ),
    ),
    );
  }
}