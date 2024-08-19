import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/utils.dart';
import '/models/database_helper.dart';
import '/widgets/content_carousel.dart';
import '/models/background_image_util.dart';

typedef BackgroundImageCallback = Future<void> Function();

class AuthorsGrid extends StatefulWidget {
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
  final Function(String) onAuthorSelected;
  final bool useBackgroundImage;
  final double iconAngle;
  final Alignment iconPosition;
  final Alignment authorNamePosition;
  final ValueNotifier<bool> backgroundImageEnabled;
  final String? authorName;
  final String? authorId;

  const AuthorsGrid({
    Key? key,
    required this.tapSoundEnabled,
    required this.player,
    this.searchQuery,
    this.crossAxisCount = 2,
    this.childAspectRatio = 2.5,
    this.crossAxisSpacing = 10,
    this.mainAxisSpacing = 10,
    this.padding = const EdgeInsets.all(8.0),
    this.fontSize = 16,
    this.fontWeight = FontWeight.bold,
    this.fontColor = Colors.white,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.containerColor = const Color.fromARGB(255, 51, 153, 255),
    required this.onAuthorSelected,
    this.useBackgroundImage = true,
    this.iconAngle = 0.0,
    this.iconPosition = Alignment.bottomRight,
    this.authorNamePosition = Alignment.topLeft,
    required this.backgroundImageEnabled,
    this.authorName,
    this.authorId,
  }) : super(key: key);

  @override
  _AuthorsGridState createState() => _AuthorsGridState();
}

class _AuthorsGridState extends State<AuthorsGrid> with WidgetsBindingObserver {
  late Future<List<Map<String, dynamic>>> _authorsFuture;
  String _backgroundImageLocalUrl = '';
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  final int _itemsPerPage = 6;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authorsFuture = DatabaseHelper.instance.queryAllAuthors();
    _restoreCurrentAuthorsPage();
  }

  Future<void> _saveCurrentAuthorsPage(int page) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_authors_page', page);
  }

  Future<void> _restoreCurrentAuthorsPage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int restoredPage = prefs.getInt('current_authors_page') ?? 0;
    setState(() {
      _currentPage = restoredPage;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshAuthors();
    }
  }

  void _refreshAuthors() {
    setState(() {
      _authorsFuture = DatabaseHelper.instance.queryAllAuthors();
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

    // Get the device's width and height
    final deviceWidth = MediaQuery.of(context).size.width;
    final deviceHeight = MediaQuery.of(context).size.height;

    final double desiredAspectRatio = (deviceHeight / deviceWidth) / 2.1;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _authorsFuture,
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
        final filteredAuthors = widget.searchQuery != null && widget.searchQuery!.isNotEmpty
            ? snapshot.data!
            .where((author) => author['name'].toLowerCase().contains(widget.searchQuery!.toLowerCase()))
            .toList()
            : snapshot.data!;
        final authorsOnPage = filteredAuthors
            .skip(_currentPage * _itemsPerPage)
            .take(_itemsPerPage)
            .toList();
        return Column(
          children: [
            Expanded(
              child: Padding(
                padding: widget.padding,
                child: GridView.builder(
                  itemCount: authorsOnPage.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: widget.crossAxisCount,
                    childAspectRatio: desiredAspectRatio,
                    crossAxisSpacing: widget.crossAxisSpacing,
                    mainAxisSpacing: widget.mainAxisSpacing,
                  ),
                  itemBuilder: (BuildContext context, int index) {
                    return buildAuthorGridItem(authorsOnPage[index]);
                  },
                ),
              ),
            ),
            buildPaginationControls(filteredAuthors.length),
          ],
        );
      },
    );
  }

  Widget buildAuthorGridItem(Map<String, dynamic> author) {
    return InkWell(
      onTap: () async {
        bool online = await isOnline();
        int contentCount = await _databaseHelper.getContentCountByAuthor(author['id'].toString());

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
          List<Map<String, dynamic>> content = await _databaseHelper.getContentByAuthor(author['id'].toString());
          final Set<String> favoriteContent = {};
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(title: Text(author['name'])),
                body: ContentCarousel(
                  content: content,
                  favoriteContent: favoriteContent,
                  authorName: author['name'],
                  authorId: author['id'],
                  isAuthorContent: true,
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
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: CachedNetworkImageProvider(author['image_remote']),
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
                    author['name'],
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
  }

  Widget buildPaginationControls(int totalItemCount) {
    final totalPages = (totalItemCount / _itemsPerPage).ceil();
    bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    Color backgroundColor = isDarkTheme ? Colors.grey[800]! : Colors.grey.shade300;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.0),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
        ),
        padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: _currentPage > 0
                  ? () {
                setState(() {
                  _currentPage--;
                  _saveCurrentAuthorsPage(_currentPage);
                });
              }
                  : null,
            ),
            Text(
              'Page ${_currentPage + 1} of $totalPages',
              style: const TextStyle(fontSize: 16),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: _currentPage < totalPages - 1
                  ? () {
                setState(() {
                  _currentPage++;
                  _saveCurrentAuthorsPage(_currentPage);
                });
              }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

}