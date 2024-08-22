import 'dart:async';
import 'package:flutter/material.dart';
import '/widgets/content_painter.dart';
import '/models/database_helper.dart';

class ContentsScreen extends StatefulWidget {
  final ValueNotifier<String> idNotifier;
  final String id;
  final String name;
  final bool isAuthor;
  final bool isFavorites;
  final String? authorId;
  final String? categoryId;
  final bool showAppBar; // New argument

  const ContentsScreen({Key? key,
    required this.idNotifier,
    required this.id,
    required this.name,
    this.isAuthor = false,
    this.isFavorites = false,
    this.authorId,
    this.categoryId,
    this.showAppBar = true, // Default value is true
  }) : super(key: key);

  @override
  _ContentsScreenState createState() => _ContentsScreenState();
}

class _ContentsScreenState extends State<ContentsScreen> {
  late Future<List<Map<String, dynamic>>> _contentFuture;
  late final VoidCallback _idListener;

  @override
  void initState() {
    super.initState();

    _idListener = () {
      setState(() {});  // Trigger a rebuild when the id changes
    };

    widget.idNotifier.addListener(_idListener);
  }

  @override
  void dispose() {
    widget.idNotifier.removeListener(_idListener);
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _getContentFuture() {
    if (widget.isFavorites) {
      return DatabaseHelper.instance.getFavoriteContent(authorId: widget.authorId, categoryId: widget.categoryId);
    } else if (widget.isAuthor) {
      return DatabaseHelper.instance.queryAuthorContent(widget.authorId ?? widget.id);
    } else {
      return DatabaseHelper.instance.queryCategoryContent(widget.categoryId ?? widget.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final contentFuture = _getContentFuture();
    const actionIconsPanelHeight = 50.0;
    return Scaffold(
      appBar: widget.showAppBar ? AppBar(
        title: Text(widget.name),
      ) : null, // conditionally render AppBar based on showAppBar value
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: contentFuture,
        builder: (BuildContext context,
            AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final content = snapshot.data!;
            return PageView.builder(
              scrollDirection: Axis.vertical,
              itemCount: content.length,
              itemBuilder: (BuildContext context, int index) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Expanded(
                        child: CustomPaint(
                          painter: ContentBubblePainter(
                            backgroundColor: Theme.of(context).colorScheme.background,
                            actionIconsPanelHeight: actionIconsPanelHeight,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Text(
                              content[index]['content'],
                              style: TextStyle(fontSize: 24, color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: actionIconsPanelHeight,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.favorite_border),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: const Icon(Icons.save),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: const Icon(Icons.content_copy),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: const Icon(Icons.share),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: const Icon(Icons.text_fields),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
