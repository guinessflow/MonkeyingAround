import 'package:flutter/material.dart';
import '/models/database_helper.dart';
import '/widgets/content_carousel.dart';
import '/screens/favorite_content_screen.dart';
import '/models/background_image_util.dart';
import '../utils/utils.dart';

typedef BackgroundImageCallback = Future<void> Function();

class FavoritesScreen extends StatefulWidget {

  final BackgroundImageCallback onBackgroundImageChange;
  final ValueNotifier<bool> backgroundImageEnabled;

  const FavoritesScreen({Key? key, required this.onBackgroundImageChange,required this.backgroundImageEnabled}) : super(key: key);

  @override
  _FavoritesScreenState createState() =>
      _FavoritesScreenState(onBackgroundImageChange: onBackgroundImageChange);
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late Future<List<Map<String, dynamic>>> _favoriteContentFuture;
  String? _selectedAuthor;
  String? _selectedCategory;
  String? _selectedCulture;
  List<Map<String, dynamic>> _authors = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _cultures = [];
  List<Map<String, dynamic>> _content = [];
  String _backgroundImageLocalUrl = '';

  final BackgroundImageCallback onBackgroundImageChange;

  _FavoritesScreenState({required this.onBackgroundImageChange});

  @override
  void initState() {
    super.initState();
    _favoriteContentFuture = _fetchFavoriteContent();
    _fetchAuthorsAndCategoriesAndCultures();
    _syncFavoriteContentIfNeeded();
  }

  Future<void> _syncFavoriteContentIfNeeded() async {
    final dbHelper = DatabaseHelper.instance;
    if (await DatabaseHelper.instance.isFavoritesEmpty()) {
      if (await isOnline()) {
        await DatabaseHelper.instance.syncFavoriteContent();
      }
    }
  }

  void _updateBackgroundImage(String backgroundImageLocalUrl) {
    setState(() {
      _backgroundImageLocalUrl = backgroundImageLocalUrl;
    });
  }

  Future<List<Map<String, dynamic>>> _fetchFavoriteContent({String? authorId, String? categoryId, String? cultureId}) async {
    final dbHelper = DatabaseHelper.instance;
    List<Map<String, dynamic>> contentList = await dbHelper.getDeviceFavoriteContentWithAuthorAndCategoryAndCulture(authorId: authorId, categoryId: categoryId, cultureId: cultureId);

    // Add is_author_content, is_category_content and is_culture_content to each content map
    contentList = contentList.map((content) {
      return {
        ...content,
        'is_author_content': authorId != null,
        'is_category_content': categoryId != null,
        'is_culture_content': cultureId != null,
      };
    }).toList();

   // print('Favorite quotes: $quotesList'); // Debug print statement

    setState(() {
      _content = contentList;
    });

    return contentList;
  }

  String? _getSelectedId(String name, List<Map<String, dynamic>> data) {
    for (var item in data) {
      if (item['name'] == name) {
        return item['id'];
      }
    }
    return null;
  }

  Future<void> _fetchAuthorsAndCategoriesAndCultures() async {
    final dbHelper = DatabaseHelper.instance;
    List<Map<String, dynamic>> authorsData = await dbHelper.getDistinctAuthorsInFavorites();
    List<Map<String, dynamic>> categoriesData = await dbHelper.getDistinctCategoriesInFavorites();
    List<Map<String, dynamic>> culturesData = await dbHelper.getDistinctCulturesInFavorites(); // New line

   // print('Authors: $authorsData'); // Debug print statement
   // print('Categories: $categoriesData'); // Debug print statement
   // print('Cultures: $culturesData'); // New line

    _authors = authorsData.map((author) => {'id': author['id'], 'name': author['name'], 'isAuthor': true}).toList();
    _categories = categoriesData.map((category) => {'id': category['id'], 'name': category['name'], 'isCategory': true}).toList();
    _cultures = culturesData.map((culture) => {'id': culture['id'], 'name': culture['name'], 'isCulture': true}).toList();

 //   print('_authors: $_authors');
  //  print('_categories: $_categories');
   // print('_cultures: $_cultures'); // New line
  }

  Map<String, List<Map<String, dynamic>>> _groupContent(List<Map<String, dynamic>> contentData) {
    Map<String, List<Map<String, dynamic>>> groupedContent = {};

    for (Map<String, dynamic> content in contentData) {
      String key = 'All Favorites';
      if (_selectedAuthor != null && content['author'] != null) {
        key = content['author'];
      } else if (_selectedCategory != null &&content['category'] != null) {
        key = content['category'];
      } else if (_selectedCulture != null && content['culture'] != null) {
        key = content['culture'];
      }

      if (!groupedContent.containsKey(key)) {
        groupedContent[key] = [];
      }
      groupedContent[key]?.add(content);
    }

    return groupedContent;
  }

  void _showFilterDialog() async {
    await _fetchAuthorsAndCategoriesAndCultures();
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter dialogSetState) {
            return AlertDialog(
              title: const Text('Filter Favorites'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedAuthor,
                      items: _authors.map<DropdownMenuItem<String>>((value) {
                        return DropdownMenuItem<String>(
                          value: value['id'],
                          child: Text(value['name']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        dialogSetState(() {
                          _selectedAuthor = value;
                          _selectedCategory = null;
                          _selectedCulture = null;
                        });
                      },
                      hint: const Text('Select Author'),
                    ),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      items: _categories.map<DropdownMenuItem<String>>((value) {
                        return DropdownMenuItem<String>(
                          value: value['id'],
                          child: Text(value['name']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        dialogSetState(() {
                          _selectedCategory = value;
                          _selectedAuthor = null;
                          _selectedCulture = null;
                        });
                      },
                      hint: const Text('Select Category'),
                    ),
                    DropdownButtonFormField<String>(
                      value: _selectedCulture,
                      items: _cultures.map<DropdownMenuItem<String>>((value) {
                        return DropdownMenuItem<String>(
                          value: value['id'],
                          child: Text(value['name']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        dialogSetState(() {
                          _selectedCulture = value;
                          _selectedAuthor = null;
                          _selectedCategory = null;
                        });
                      },
                      hint: const Text('Select Culture'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    setState(() {
                      _selectedAuthor = null;
                      _selectedCategory = null;
                      _selectedCulture = null;

                      // Update _favoriteQuotesFuture
                      _favoriteContentFuture = _fetchFavoriteContent();
                    });

                    Navigator.of(context).pop();
                  },
                  child: const Text('Clear'),
                ),
                TextButton(
                  onPressed: () {
                    if (_selectedAuthor != null || _selectedCategory != null || _selectedCulture != null) {
                      setState(() {
                        _favoriteContentFuture = _fetchFavoriteContent(
                          authorId: _selectedAuthor,
                          categoryId: _selectedCategory,
                          cultureId: _selectedCulture,
                        );
                      });
                    }
                    Navigator.of(context).pop();
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }


  Widget _buildSectionContent({
    required List<Map<String, dynamic>> content,
    required Set<String> favoriteContent,
  }) {
    final filteredContent = content.where((content) => content['content'] != null).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemBuilder: (BuildContext context, int index) {
              final content = filteredContent[index];
              final contentId = content['content_id'].toString();

              return InkWell(
                onTap: () async {
                  // Add any onTap action for the quote
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        content['quote'] ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        content['author'] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 18,
                          fontStyle: FontStyle.italic,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
            itemCount: filteredContent.length,
          ),
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Favorites',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.normal,
                fontFamily: 'Arial',
              ),
            ),
            Row(
              children: [
                const Text(
                  'Filter',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.normal,
                    fontFamily: 'Arial',
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.filter_alt_outlined),
                  onPressed: _showFilterDialog,
                ),
              ],
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _favoriteContentFuture,
        builder: (context, snapshot) {
          ThemeData theme = Theme.of(context);
          Color progressColor = theme.brightness == Brightness.dark ? Colors.white : Colors.black54;
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            );
          } else if (snapshot.hasError) {
            return const Center(child: Text('An error occurred while fetching favorites.'));
          } else {
            final favoriteContent = snapshot.data!;
            final favoriteContentIds = favoriteContent.map((content) => content['id'].toString()).toSet();

            if (favoriteContent.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(10.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Your favorites list is empty.',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Discover and save jokes you love by tapping the heart icon on a joke. They will show up here!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            } else {
              Map<String, List<Map<String, dynamic>>> groupedContent = _groupContent(favoriteContent);
              return ListView.builder(
                itemCount: groupedContent.length * 2,
                itemBuilder: (BuildContext context, int index) {
                  if (index.isEven) {
                    String title = groupedContent.keys.elementAt(index ~/ 2);
                    bool isAuthorContent = _authors.any((author) => author['name'] == title && author['isAuthor']);
                    bool isCategoryContent = _categories.any((category) => category['name'] == title && category['isCategory']);
                    bool isCultureContent = _cultures.any((culture) => culture['name'] == title && culture['isCulture']);
                    bool isAllFavoritesContent = !isAuthorContent && !isCategoryContent && !isCultureContent;

                    return InkWell(
                      onTap: () {
                        List<Map<String, dynamic>> contentInSection = groupedContent[title]!;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FavoriteContentScreen(
                              title: title,
                              content: contentInSection,
                              favoriteContent: favoriteContentIds,
                              isAuthorContent: isAuthorContent,
                              isCategoryContent: isCategoryContent,
                              isCultureContent: isCultureContent,
                              isAllFavoritesContent: isAllFavoritesContent,
                              authorId: isAuthorContent ? _getSelectedId(title, _authors) : null,
                              categoryId: isCategoryContent ? _getSelectedId(title, _categories) : null,
                              cultureId: isCultureContent ? _getSelectedId(title, _cultures) : null,
                              onBackgroundImageChange: () async {
                                String newBackgroundImageLocalUrl = await BackgroundImageUtil.initBackgroundImage();
                                setState(() {
                                  _backgroundImageLocalUrl = newBackgroundImageLocalUrl;
                                });
                              },
                              backgroundImageEnabled: widget.backgroundImageEnabled,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            const SizedBox(width: 8), // Add some space between the text and the icon
                            Transform.translate(
                              offset: const Offset(0, 2), // Move the icon 2 pixels down
                              child: const Icon(
                                Icons.chevron_right, // Use the chevron_right icon
                                size: 16, // Adjust the size to match the text
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    List<Map<String, dynamic>> contentInSection = groupedContent.values.elementAt(index ~/ 2);

                    String title = groupedContent.keys.elementAt(index ~/ 2);
                    bool isAuthorContent = _authors.any((author) => author['name'] == title && author['isAuthor']);
                    bool isCategoryContent = _categories.any((category) => category['name'] == title && category['isCategory']);
                    bool isCultureContent = _cultures.any((culture) => culture['name'] == title && culture['isCulture']);
                    bool isAllFavoritesContent = !isAuthorContent && !isCategoryContent && !isCultureContent;

                    return SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6, // Adjust the height as needed
                      child: ContentCarousel(
                        content: contentInSection,

                        favoriteContent: favoriteContentIds,
                        source: 'favorites',
                        isAuthorContent: isAuthorContent,
                        isCategoryContent: isCategoryContent,
                        isCultureContent: isCultureContent,
                        isAllFavoritesContent: isAllFavoritesContent,
                        authorId: isAuthorContent ? _getSelectedId(title, _authors) : null,
                        categoryId: isCategoryContent ? _getSelectedId(title, _categories) : null,
                        cultureId: isCultureContent ? _getSelectedId(title, _cultures) : null,
                        onBackgroundImageChange: () async {
                          String newBackgroundImageLocalUrl = await BackgroundImageUtil.initBackgroundImage();
                          setState(() {
                            _backgroundImageLocalUrl = newBackgroundImageLocalUrl;
                          });
                        },
                        backgroundImageEnabled: widget.backgroundImageEnabled,
                      ),
                    );
                  }
                },
              );
            }
          }
        },
      ),
    );
  }
}