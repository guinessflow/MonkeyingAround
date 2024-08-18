import 'package:flutter/material.dart';
import '/models/database_helper.dart';
import '/widgets/content_carousel.dart';
import '/models/background_image_util.dart';

typedef BackgroundImageCallback = Future<void> Function();

class ContentCategoryView extends StatefulWidget {
  final ValueNotifier<bool> backgroundImageEnabled;
  final String category;
  final bool tapSoundEnabled;
  final VoidCallback onBackPressed;

  const ContentCategoryView({
    Key? key,
    required this.category,
    required this.tapSoundEnabled,
    required this.onBackPressed,
    required this.backgroundImageEnabled,
  }) : super(key: key);

  @override
  _ContentCategoryViewState createState() => _ContentCategoryViewState();
}

class _ContentCategoryViewState extends State<ContentCategoryView> {
  List<Map<String, dynamic>> _content = [];
  Set<String> _favoriteContent= {};
  String _backgroundImageLocalUrl = '';
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  Future<void> _loadContent() async {
    final content = await _fetchContentByCategory(widget.category);
    setState(() {
      _content = content;
    });
  }
  void _updateBackgroundImage(String backgroundImageLocalUrl) {
    setState(() {
      _backgroundImageLocalUrl = backgroundImageLocalUrl;
    });
  }

  Future<void> _loadFavoriteContent() async {
    final favoriteContent = await _databaseHelper.queryAllFavoriteContent();
    setState(() {
      _favoriteContent = favoriteContent.map((content) => (content['id'] as int).toString()).toSet();
    });
  }

  @override
  void initState() {
    super.initState();
    _loadContent();
    _loadFavoriteContent();
  }

  Future<List<Map<String, dynamic>>> _fetchContentByCategory(String categoryName) async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(
      DatabaseHelper.tableCategoryContent,
      where: 'category_id IN (SELECT id FROM ${DatabaseHelper.tableCategories} WHERE name = ?)',
      whereArgs: [categoryName],
      orderBy: 'timestamp DESC',
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        widget.onBackPressed();
              return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.category),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              widget.onBackPressed();
                        },
          ),
        ),
        body: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    widget.category,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Raleway',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ContentCarousel(
                    content: _content,
                    favoriteContent: _favoriteContent,
                    isAuthorContent: false,
                    onBackgroundImageChange: () async {
                      String newBackgroundImageLocalUrl = await BackgroundImageUtil.initBackgroundImage();
                      setState(() {
                        _backgroundImageLocalUrl = newBackgroundImageLocalUrl;
                      });
                    },
                    backgroundImageEnabled: widget.backgroundImageEnabled,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

}
