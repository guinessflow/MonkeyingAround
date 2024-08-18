import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '/widgets/content_carousel.dart';
import '/models/background_image_util.dart';
import '/widgets/welcome_content_widget.dart';
import '/models/database_helper.dart';
import '../utils/utils.dart';

typedef BackgroundImageCallback = Future<void> Function();

class CategoryGrid extends StatefulWidget {
  final ValueNotifier<Map<String, dynamic>> randomContentNotifier;
  final bool tapSoundEnabled;
  final AudioPlayer player;
  final String? searchQuery;
  final int crossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final EdgeInsets padding;
  final double fontSize;
  final FontWeight fontWeight;
  final Color fontColor;
  final BorderRadius borderRadius;
  final Color containerColor;
  final Function(String) onCategorySelected;
  final bool useBackgroundImage;
  final double iconAngle;
  final Alignment iconPosition;
  final Alignment categoryNamePosition;
  final ValueNotifier<bool> backgroundImageEnabled;

  final ValueNotifier<bool> showWelcomeContentNotifier;
  final String? categoryName;
  final String? categoryId;

  const CategoryGrid({
    Key? key,
    required this.randomContentNotifier,
    required this.tapSoundEnabled,
    required this.player,
    this.searchQuery,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.5,
    this.crossAxisSpacing = 10,
    this.mainAxisSpacing = 10,
    this.padding = const EdgeInsets.all(8.0),
    this.fontSize = 16,
    this.fontWeight = FontWeight.bold,
    this.fontColor = Colors.white,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.containerColor = const Color.fromARGB(255, 51, 153, 255),
    required this.onCategorySelected,
    this.useBackgroundImage = true,
    this.iconAngle = 0.0,
    this.iconPosition = Alignment.bottomRight,
    this.categoryNamePosition = Alignment.topLeft,
    required this.backgroundImageEnabled,
    required this.showWelcomeContentNotifier,
    this.categoryName,
    this.categoryId,
  }) : super(key: key);

  @override
  _CategoryGridState createState() => _CategoryGridState();
}

class _CategoryGridState extends State<CategoryGrid> with WidgetsBindingObserver {
  late Future<List<Map<String, dynamic>>> _categoriesFuture;
  String _backgroundImageLocalUrl = '';
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  late ValueNotifier<Map<String, dynamic>> _randomContentNotifier;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _categoriesFuture = DatabaseHelper.instance.queryAllCategories();
    _randomContentNotifier = widget.randomContentNotifier;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onContentDismissed() {
    widget.showWelcomeContentNotifier.value = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshCategories();
    }
  }
  void _refreshCategories() {
    setState(() {
      _categoriesFuture = DatabaseHelper.instance.queryAllCategories();
    });
  }

  Color generateColor(String input) {
    return Color((input.hashCode * 0x12345679) | 0xFF000000);
  }

  void _updateBackgroundImage(String backgroundImageLocalUrl) {
    setState(() {
      _backgroundImageLocalUrl = backgroundImageLocalUrl;
    });
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    Color progressColor = theme.brightness == Brightness.dark ? Colors.white : Colors.black54;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _categoriesFuture,
      builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: Text('No data'));
        }

        final filteredCategories = widget.searchQuery != null && widget.searchQuery!.isNotEmpty
            ? snapshot.data!
            .where((category) => category['name'].toLowerCase().contains(widget.searchQuery!.toLowerCase()))
            .toList()
            : snapshot.data!;

        return ListView(
          children: [
            WelcomeContentWidget(
              randomContentNotifier: _randomContentNotifier,
              showWelcomeContent: widget.showWelcomeContentNotifier,
              onContentDismissed: _onContentDismissed,
            ),
            Padding(
              padding: widget.padding,
              child: GridView.builder(
                shrinkWrap: true,  // This is important, it tells the GridView to size itself to its children
                physics: const NeverScrollableScrollPhysics(), // This is important, it prevents the GridView from handling scroll events
                itemCount: filteredCategories.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: widget.crossAxisCount,
                  childAspectRatio: widget.childAspectRatio,
                  crossAxisSpacing: widget.crossAxisSpacing,
                  mainAxisSpacing: widget.mainAxisSpacing,
                ),
                itemBuilder: (BuildContext context, int index) {
                  return InkWell(
                    onTap: () async {
                      bool online = await isOnline();
                      int contentCount = await _databaseHelper.getContentCountByCategory(filteredCategories[index]['id'].toString());

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
                      } else {
                        List<Map<String, dynamic>> content = await _databaseHelper.getContentByCategory(filteredCategories[index]['id'].toString());
                        final Set<String> favoriteContent = {};
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Scaffold(
                              appBar: AppBar(title: Text(filteredCategories[index]['name'])),
                              body: ContentCarousel(
                                content: content,
                                favoriteContent: favoriteContent,
                                categoryName: filteredCategories[index]['name'],
                                categoryId: filteredCategories[index]['id'],
                                isCategoryContent: true,
                                onBackgroundImageChange: () async {
                                  String newBackgroundImageLocalUrl = await BackgroundImageUtil.initBackgroundImage();
                                  setState(() {
                                    _backgroundImageLocalUrl = newBackgroundImageLocalUrl;
                                  });
                                },
                                backgroundImageEnabled: widget.backgroundImageEnabled,
                              ),
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: generateColor(filteredCategories[index]['name']),
                        borderRadius: widget.borderRadius,
                      ),
                      child: Stack(
                        children: [
                          // Category name positioned in the top left corner
                          Positioned(
                            top: 16.0, // Padding from the top
                            left: 16.0, // Padding from the left
                            child: Text(
                              filteredCategories[index]['name'],
                              style: TextStyle(
                                fontSize: widget.fontSize,
                                fontWeight: widget.fontWeight,
                                color: widget.fontColor,
                                fontFamily: 'OpenSans',
                              ),
                            ),
                          ),
                          // Icon positioned and rotated
                          if (widget.useBackgroundImage)
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
                                    imageUrl: filteredCategories[index]['icon_remote'],
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
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
