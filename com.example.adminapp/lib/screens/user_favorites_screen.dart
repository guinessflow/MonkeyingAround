import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class UserFavoritesScreen extends StatefulWidget {
  final VoidCallback backButton;

  const UserFavoritesScreen({super.key, required this.backButton});

  @override
  _UserFavoritesScreenState createState() => _UserFavoritesScreenState();
}

class _UserFavoritesScreenState extends State<UserFavoritesScreen> {
  final int rowsPerPage = 7;
  int currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Favorites'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.backButton,
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('user_favorites')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final favorites = snapshot.data!.docs;
            final totalRows = favorites.length;
            final totalPages = (totalRows / rowsPerPage).ceil();
           // final totalFavoritesCount = totalRows.toString();

            if (totalRows == 0) {
              return const Center(
                child: Text('No favorites found.'),
              );
            }

            final startIndex = currentPage * rowsPerPage;
            final endIndex = (startIndex + rowsPerPage).clamp(0, totalRows);

            final visibleFavorites = favorites.sublist(startIndex, endIndex);

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        'Total Favorites: $totalRows',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: visibleFavorites.length,
                    itemBuilder: (context, index) {
                      final favorite = visibleFavorites[index].data() as Map<String, dynamic>;
                      final id = visibleFavorites[index].id;

                      final userID = favorite['user_id'];
                      final contentID = favorite['content_id'];
                      final favStatus = favorite['favorite_status'];
                      final timestamp = DateTime.fromMillisecondsSinceEpoch(favorite['timestamp']);
                      final formattedTimestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp);

                      return Card(
                        child: ListTile(
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('User ID: $userID'),
                              Text('Content ID: $contentID'),
                              Text('Favorite Status: $favStatus'),
                              Text('Last Updated: $formattedTimestamp'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  _deleteFavorite(id);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: currentPage > 0 ? () => _changePage(-1) : null,
                    ),
                    Text('${currentPage + 1} / $totalPages'),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: currentPage < totalPages - 1 ? () => _changePage(1) : null,
                    ),
                  ],
                ),
              ],
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }

  void _changePage(int increment) {
    setState(() {
      currentPage += increment;
    });
  }

  void _deleteFavorite(String favoriteId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this entry?'),
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
                FirebaseFirestore.instance
                    .collection('user_favorites')
                    .doc(favoriteId)
                    .delete()
                    .then((_) {
                  print('Favorite entry deleted successfully.');
                }).catchError((error) {
                  print('Error deleting favorite: $error');
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
