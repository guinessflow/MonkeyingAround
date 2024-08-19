import 'dart:io';
import 'package:flutter/material.dart';
import '/models/database_helper.dart';
import '/screens/contents_screen.dart';

class AuthorsScreen extends StatefulWidget {
  const AuthorsScreen({Key? key}) : super(key: key);

  @override
  _AuthorsScreenState createState() => _AuthorsScreenState();
}

class _AuthorsScreenState extends State<AuthorsScreen> {
  final _idNotifier = ValueNotifier<String>('');
  late Future<List<Map<String, dynamic>>> _authorsFuture;

  @override
  void initState() {
    super.initState();
    _authorsFuture = DatabaseHelper.instance.queryAllAuthors();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _authorsFuture,
      builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final authors = snapshot.data!;
          return GridView.builder(
            itemCount: authors.length,
            padding: const EdgeInsets.all(4.0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: MediaQuery.of(context).size.width /
                  (MediaQuery.of(context).size.height / 2.1),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (BuildContext context, int index) {
              return GestureDetector(
                onTap: () {
                  _idNotifier.value = authors[index]['id'].toString();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ContentsScreen(
                        idNotifier: _idNotifier,
                        id: authors[index]['id'].toString(),
                        name: authors[index]['name'],
                        isAuthor: true,
                      ),
                    ),
                  );
                },

                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: GridTile(
                      footer: GridTileBar(
                        backgroundColor: Colors.black54,
                        title: Text(
                          authors[index]['name'],
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: FileImage(File(authors[index]['image_local'])),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }
}
