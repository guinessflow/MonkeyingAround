import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/utils.dart';
import '/models/database_helper.dart';
import '/widgets/content_carousel.dart';
import '/models/background_image_util.dart';

typedef BackgroundImageCallback = Future<void> Function();

class SearchResultsWidget extends StatefulWidget {
  final ValueNotifier<bool> backgroundImageEnabled;
  final List<Map<String, dynamic>> searchdata;
  final bool searchByAuthor;
  final bool searchByCategory;
  final bool searchByCulture;
  final bool searchByFavorite;

  final bool useBackgroundImage;
  final double iconAngle;
  final Alignment iconPosition;
  final Alignment categoryNamePosition;

  const SearchResultsWidget({Key? key, 
    required this.searchdata,
    required this.searchByAuthor,
    required this.searchByCategory,
    required this.searchByFavorite,
    this.searchByCulture = false,
    this.useBackgroundImage = true,
    this.iconAngle = 0.0,
    this.iconPosition = Alignment.topRight,
    this.categoryNamePosition = Alignment.topLeft,
    required this.backgroundImageEnabled,
  }) : super(key: key);

  @override
  _SearchResultsWidgetState createState() => _SearchResultsWidgetState(
    isAuthorSearch: searchByAuthor,
    isCategorySearch: searchByCategory,
    isCultureSearch: searchByCulture,
    isFavoriteSearch: searchByFavorite,
  );
}


class _SearchResultsWidgetState extends State<SearchResultsWidget> {
  bool isAuthorSearch;
  bool isCategorySearch;
  bool isCultureSearch;
  bool isFavoriteSearch;
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  double _childAspectRatio = 0;
  final double _crossAxisSpacing = 10;
  final double _mainAxisSpacing = 10;
  String _backgroundImageLocalUrl = '';

  _SearchResultsWidgetState({
    required this.isAuthorSearch,
    required this.isCategorySearch,
    required this.isCultureSearch,
    required this.isFavoriteSearch,
  });

  @override
  void initState() {
    super.initState();
    _setGridProperties();
  }

  void _updateBackgroundImage(String backgroundImageLocalUrl) {
    setState(() {
      _backgroundImageLocalUrl = backgroundImageLocalUrl;
    });
  }

  Color generateColor(String input) {
    return Color((input.hashCode * 0x12345679) | 0xFF000000);
  }

  double _calculateAuthorAspectRatio(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    final deviceHeight = MediaQuery.of(context).size.height;
    return (deviceHeight / deviceWidth) / 2.1;
  }

  double _calculateCategoryAspectRatio(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    final deviceHeight = MediaQuery.of(context).size.height;
    return (deviceHeight / deviceWidth) / 1.5;
  }

  void _setGridProperties({double authorAspectRatio = 1.0, double categoryAspectRatio = 1.0}) {
    String imageLocal = widget.searchdata[0]['image_remote'] ?? '';

    setState(() {
      _childAspectRatio = imageLocal.isEmpty ? categoryAspectRatio : authorAspectRatio;
    });
  }

  Future<void> _handleTap(int index, String name) async {
  //  print('onTap called');
  //  print('isCultureSearch: $isCultureSearch, isAuthorSearch: $isAuthorSearch, isCategorySearch: $isCategorySearch');

    int contentCount;
    List<Map<String, dynamic>> content;

    if (isCultureSearch) {
      contentCount = await _databaseHelper.getContentCountByCulture(widget.searchdata[index]['id'].toString());
    } else if (isAuthorSearch) {
      contentCount = await _databaseHelper.getContentCountByAuthor(widget.searchdata[index]['id'].toString());
    } else {
      contentCount = await _databaseHelper.getContentCountByCategory(widget.searchdata[index]['id'].toString());
    }

    bool online = await isOnline();
    if (!online && contentCount == 0) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('No Internet Connection'),
            content: const Text('Please check your internet connection and try again.'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
              ),
            ],
          );
        },
      );
    }else{
      if (isCultureSearch) {
       // print('Getting content by culture');
        content = await _databaseHelper.getContentByCulture(widget.searchdata[index]['id'].toString());
      } else if (isAuthorSearch) {
      //  print('Getting content by author');
        content = await _databaseHelper.getContentByAuthor(widget.searchdata[index]['id'].toString());
      } else {
     //   print('Getting content by category');
        content = await _databaseHelper.getContentByCategory(widget.searchdata[index]['id'].toString());
      }

      final favoriteContent = await _databaseHelper.queryAllDeviceFavoriteContent();
      //print('Navigating to ContentCarousel with $contentCount content');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: Text(name)),
            body: ContentCarousel(
              content: content,
              favoriteContent: favoriteContent.map((content) => content['id'] as String).toSet(),
              isAuthorContent: isAuthorSearch,
              isCategoryContent: isCategorySearch,
              isCultureContent: isCultureSearch,
              isFavoriteContent: isFavoriteSearch,
              onBackgroundImageChange: () async {
                String newBackgroundImageLocalUrl = await BackgroundImageUtil.initBackgroundImage();
                setState(() {
                  _backgroundImageLocalUrl = newBackgroundImageLocalUrl;
                });
              },
              backgroundImageEnabled: widget.backgroundImageEnabled,
              source: 'search',
              name: name,
              authorId: isAuthorSearch ? widget.searchdata[index]['id'].toString() : null,
              categoryId: (!isAuthorSearch && !isCultureSearch) ? widget.searchdata[index]['id'].toString() : null,
              cultureId: isCultureSearch ? widget.searchdata[index]['id'].toString() : null,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double authorAspectRatio = _calculateAuthorAspectRatio(context);
    double categoryAspectRatio = _calculateCategoryAspectRatio(context);
    _setGridProperties(authorAspectRatio: authorAspectRatio, categoryAspectRatio: categoryAspectRatio);

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: _childAspectRatio,
        crossAxisSpacing: _crossAxisSpacing,
        mainAxisSpacing: _mainAxisSpacing,
      ),
      padding: const EdgeInsets.all(8.0),
      itemCount: widget.searchdata.length,
      itemBuilder: (context, index) {
        String name = widget.searchdata[index]['name'] ?? '';
        String imageLocal = widget.searchdata[index]['image_remote'] ?? '';

        List<Map<String, dynamic>>? content;

        if (widget.searchdata[index]['author'] != null) {
          isAuthorSearch = true;
          name = widget.searchdata[index]['author'];
          imageLocal = widget.searchdata[index]['author_image'];
        } else if (widget.searchdata[index]['category'] != null) {
          isCategorySearch = true;
          name = widget.searchdata[index]['category'];
          imageLocal = widget.searchdata[index]['category_icon'];
        } else if (widget.searchdata[index]['culture'] != null) {
          isCultureSearch = true;
          name = widget.searchdata[index]['culture'];
          imageLocal = widget.searchdata[index]['culture_image'];
        }

        Future<void> fetchContent() async {
          if (widget.searchdata[index]['author'] != null) {
            content = await _databaseHelper.getContentByAuthor(widget.searchdata[index]['author_id'].toString());
          } else if (widget.searchdata[index]['category'] != null) {
            content = await _databaseHelper.getContentByCategory(widget.searchdata[index]['category_id'].toString());
          } else if (widget.searchdata[index]['culture'] != null) {
            content = await _databaseHelper.getContentByCulture(widget.searchdata[index]['culture_id'].toString());
          }
        }

        return Container(
            child: isFavoriteSearch
                ? GestureDetector(
              onTap: () async {
                await fetchContent();
                if (content != null) {
                  final favoriteContent = await _databaseHelper.queryAllDeviceFavoriteContent();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Scaffold(
                        appBar: AppBar(title: Text(name)),
                        body: ContentCarousel(
                          content: content!,
                          favoriteContent: favoriteContent.map((content) => content['id'] as String).toSet(),
                          isAuthorContent: isAuthorSearch,
                          isCategoryContent: isCategorySearch,
                          isCultureContent: isCultureSearch,
                          isFavoriteContent: isFavoriteSearch,
                          onBackgroundImageChange: () async {
                            String newBackgroundImageLocalUrl = await BackgroundImageUtil.initBackgroundImage();
                            setState(() {
                              _backgroundImageLocalUrl = newBackgroundImageLocalUrl;
                            });
                          },
                          backgroundImageEnabled: widget.backgroundImageEnabled,
                          source: 'search',
                          name: name,
                          authorId: isAuthorSearch ? widget.searchdata[index]['id'].toString() : null,
                          categoryId: (!isAuthorSearch && !isCultureSearch) ? widget.searchdata[index]['id'].toString() : null,
                          cultureId: isCultureSearch ? widget.searchdata[index]['id'].toString() : null,
                        ),
                      ),
                    ),
                  );
                } else {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext dialogContext) {
                      return AlertDialog(
                        title: const Text('No Internet Connection'),
                        content: const Text('Please check your internet connection and try again.'),
                        actions: <Widget>[
                          TextButton(
                            child: const Text('OK'),
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                }
              },
              child: isAuthorSearch
                  ? Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(imageLocal),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.7),
                              Colors.black.withOpacity(0.2),
                            ],
                          ),
                        ),
                        child: Text(
                          name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'OpenSans',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
                  : isCategorySearch
                  ? Container(
                decoration: BoxDecoration(
                  color: generateColor(name),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 16.0,
                      left: 16.0,
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'OpenSans',
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16.0,
                      right: 16.0,
                      child: Transform.rotate(
                        angle: widget.iconAngle * 3.141592653589793 / 180,
                        child: ColorFiltered(
                          colorFilter: const ColorFilter.matrix([
                            -1, 0, 0, 0, 255,
                            0, -1, 0, 0, 255,
                            0, 0, -1, 0, 255,
                            0, 0, 0, 1, 0,
                          ]),
                          child: CachedNetworkImage(
                            imageUrl: imageLocal,
                            height: 50.0,
                            width: 50.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
                  : isCultureSearch
                  ? Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(imageLocal),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.7),
                              Colors.black.withOpacity(0.2),
                            ],
                          ),
                        ),
                        child: Text(
                          name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'OpenSans',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
                  : const SizedBox(),
            )
              : (() {
            String imagePath = imageLocal;
            if (imageLocal.isNotEmpty) {
              return GestureDetector(
                onTap: () => _handleTap(index, name),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: CachedNetworkImageProvider(imagePath),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.7),
                                  Colors.black.withOpacity(0.2),
                                ],
                              ),
                            ),
                            child: Text(
                              name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'OpenSans',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            } else {
              return InkWell(
                onTap: () => _handleTap(index, name),
                child: Container(
                  decoration: BoxDecoration(
                    color: generateColor(name),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Stack(
                    children: [
                      // Category name positioned in the top left corner
                      Positioned(
                        top: 16.0, // Padding from the top
                        left: 16.0, // Padding from the left
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'OpenSans',
                          ),
                        ),
                      ),
                      // Icon positioned and rotated
                      Positioned(
                        bottom: 16.0, // Padding from the bottom
                        right: 16.0,
                        child: Transform.rotate(
                          angle: widget.iconAngle * 3.141592653589793 / 180, // Convert degrees to radians
                          child: ColorFiltered(
                            colorFilter: const ColorFilter.matrix([
                              -1, 0, 0, 0, 255,
                              0, -1, 0, 0, 255,
                              0, 0, -1, 0, 255,
                              0, 0, 0, 1, 0,
                            ]),
                            child: CachedNetworkImage(
                              imageUrl: widget.searchdata[index]['icon_remote'],
                              height: 50.0, // Icon height
                              width: 50.0, // Icon width
                            ),
                          ),
                        ), // Padding from the right
                      ),
                    ],
                  ),
                ),
              );
            }
          })(),
        );
      },
    );
  }
}