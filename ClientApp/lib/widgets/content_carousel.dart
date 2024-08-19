import 'dart:ui';
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gal/gal.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/models/content.dart';
import '/models/background_image_util.dart';
import '/widgets/universal_ad_widget.dart';
import '/widgets/bubble_painter.dart';
import '/models/database_helper.dart';
import '../utils/state_manager.dart';

final stateManager = StateManager();

typedef BackgroundImageCallback = Future<void> Function();

class ContentCarousel extends StatefulWidget {
  final BackgroundImageCallback onBackgroundImageChange;
  final List<Map<String, dynamic>> content;
  final Set<String> favoriteContent;
  final String? source;
  final bool isAuthorContent;
  final bool isCategoryContent;
  final bool isCultureContent;
  final bool isFavoriteContent;
  final bool isAllFavoritesContent;
  final int crossAxisCount;
  final double childAspectRatio;
  final double mainAxisSpacing;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final BorderRadius borderRadius;
  final TextStyle textStyle;
  final Color containerColor;
  final String? categoryName;
  final String? authorName;
  final String? cultureName;
  final Content? selectedContent;
  final bool fromNotification;
  final String? authorId;
  final String? categoryId;
  final String? cultureId;
  final String? selectedId;
  final ValueNotifier<bool> backgroundImageEnabled;
  final String? contentId;
  final String? authorImagePath;
  final String? cultureImagePath;
  final String? name;
  final String? title;

  const ContentCarousel({
    Key? key,
    required this.content,
    required this.favoriteContent,
    this.isAuthorContent = false,
    this.isCategoryContent =false,
    this.isCultureContent =false,
    this.isFavoriteContent =false,
    this.isAllFavoritesContent  = false,
    this.crossAxisCount = 1,
    this.childAspectRatio = 1.5,
    this.mainAxisSpacing = 15,
    this.padding = const EdgeInsets.all(10),
    this.margin = const EdgeInsets.symmetric(vertical: 1.0, horizontal: 5.0),
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.textStyle = const TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    this.containerColor = const Color.fromARGB(255, 51, 153, 255),
    this.source,
    this.categoryName,
    this.authorName,
    this.cultureName,
    this.selectedContent ,
    this.fromNotification = false,
    this.authorId,
    this.categoryId,
    this.cultureId,
    this.selectedId,
    required this.onBackgroundImageChange,
    required this.backgroundImageEnabled,
    this.contentId,
    this.authorImagePath,
    this.cultureImagePath,
    this.name,
    this.title,
  }) : super(key: key);

  @override
  _ContentCarouselState createState() => _ContentCarouselState(favoriteContent);
}

class _ContentCarouselState extends State<ContentCarousel> {
  List<GlobalKey> _contentWidgetKeys = [];
  final GlobalKey _popupMenuKey = GlobalKey();
  List<GlobalKey> _backgroundImageAndContentBubbleKeys = [];
  late ValueNotifier<ConnectivityResult?> connectivityNotifier;
  Set<String> _favoriteContent;
  String _appName = '';
  String _backgroundImageUrl = '';
  bool _showOverlayText = true;
  Timer? _overlayTextTimer;
  String _currentFontFamily = 'Quicksand';
  bool _isFontSizeSliderVisible = false;
  bool _isAdLoaded = false;
  bool _isProPurchased = false;
  double _currentFontSize = 24; // Initial font size
  final StateManager _stateManager = StateManager();
  late Future<String> _backgroundImageFuture;
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final FlutterTts _flutterTts = FlutterTts();
  late PageController _controller;

  _ContentCarouselState(this._favoriteContent);

  GlobalKey generateUniqueKey() {
    return GlobalKey();
  }

  Color generateColor(String input) {
    return Color((input.hashCode * 0x12345679) | 0xFF000000);
  }

  Color getBubbleColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? Colors.black.withOpacity(0.05)
        : Colors.white.withOpacity(0.05);
  }

  Future<List<String>> _getVoices() async {
    final voices = await _flutterTts.getVoices;
    return voices.cast<String>();
  }


  Future<void> _speakContent(String quote) async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.speak(quote);
  }

  @override
  void initState() {
    super.initState();
    _contentWidgetKeys = List<GlobalKey>.generate(widget.content.length, (index) => GlobalKey());
    _backgroundImageAndContentBubbleKeys = List<GlobalKey>.generate(widget.content.length, (index) => GlobalKey());
    _fetchAppSettings();
    _loadFavoriteContent();
    connectivityNotifier = ValueNotifier<ConnectivityResult?>(null);
    Connectivity().checkConnectivity().then((value) => connectivityNotifier.value = value);

    // Updated code
    _backgroundImageFuture = _initBackgroundImage();
    initBackgroundImageAndSetState();
    _restoreFont();

    SharedPreferences.getInstance().then((prefs) {
      _showOverlayText = prefs.getBool('_showOverlayText') ?? true;
      setState(() {
        _hideOverlayTextAfterDelay();
      });
    });

    SharedPreferences.getInstance().then((prefs) {
      bool? isAdLoaded = prefs.getBool('_isAdLoaded');
      setState(() {
        _isAdLoaded = isAdLoaded ?? false;
      });
    });

    SharedPreferences.getInstance().then((prefs) {
      bool isProPurchased = prefs.getBool('isProPurchased') ?? false;
      setState(() {
        _isProPurchased = isProPurchased;
      });
    });

  }


  void _hideOverlayTextAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showOverlayText = false;
        });
      }
    });
  }


  void _restoreFont() async {
    String fontFamily = await _stateManager.restoreSelectedFont();
    setState(() {
      _currentFontFamily = fontFamily;
    });
  }

  Future<String> _initBackgroundImage() async {
    return await BackgroundImageUtil.initBackgroundImage();
  }

  Future<void> initBackgroundImageAndSetState() async {
    String newBackgroundImageUrl = await BackgroundImageUtil.initBackgroundImage();
    setState(() {
      _backgroundImageUrl = newBackgroundImageUrl;
    });
  }


  @override
  void dispose() {
    connectivityNotifier.dispose();
    _overlayTextTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchAppSettings() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Fetch app settings from shared preferences
      _appName = prefs.getString('appName') ?? '';

      // If app settings are not in shared preferences, fetch from the database
      if (_appName.isEmpty) {
        Map<String, dynamic> appSettings = await DatabaseHelper.fetchAppSettings();

        setState(() {
          _appName = appSettings['appName'];
        });

        // Save app settings to shared preferences
<<<<<<< Updated upstream
        if (_appName != null && _appName.isNotEmpty) {
=======
        if (_appName.isNotEmpty) {
>>>>>>> Stashed changes
          prefs.setString('appName', _appName);
        }
      }

      // If _appName is still null or empty, load it from PackageInfo
<<<<<<< Updated upstream
      if (_appName == null || _appName.isEmpty) {
=======
      if (_appName.isEmpty) {
>>>>>>> Stashed changes
        final packageInfo = await PackageInfo.fromPlatform();
        setState(() {
          _appName = packageInfo.appName;
        });
        // Save app name to shared preferences
        prefs.setString('appName', _appName);
      }
    } catch (error) {
      setState(() {
        // Handle the error state if needed
      });
      print('Error fetching app settings: $error');
    }
  }

  Future<void> _loadFavoriteContent() async {
    final favoriteQuotes = await _databaseHelper.queryAllDeviceFavoriteContent();
    if (mounted) {
      setState(() {
        _favoriteContent = favoriteQuotes.map((content) => content['id'] as String).toSet();
      });
    }
  }


  Future<void> _saveAsImage(GlobalKey quoteBubbleKey, GlobalKey backgroundImageKey) async {
    RenderRepaintBoundary? quoteBubbleBoundary =
    quoteBubbleKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    RenderRepaintBoundary? backgroundImageBoundary =
    backgroundImageKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

    if (quoteBubbleBoundary == null || backgroundImageBoundary == null) {
      // Handle the case where one of the boundaries is not found
      print('Failed to find RenderRepaintBoundary');
      return;
    }

    double pixelRatio = MediaQuery.of(context).devicePixelRatio;

    ui.Image backgroundImage =
    await backgroundImageBoundary.toImage(pixelRatio: pixelRatio);
    ui.Image quoteImage =
    await quoteBubbleBoundary.toImage(pixelRatio: pixelRatio);
    ui.PictureRecorder recorder = ui.PictureRecorder();
    Canvas canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, backgroundImage.width.toDouble(),
            backgroundImage.height.toDouble()));
    canvas.drawImage(backgroundImage, Offset.zero, Paint());
    canvas.drawImage(quoteImage, Offset.zero, Paint());

    if (!_isProPurchased) {
      // Add the copyright text if the user has not purchased the pro version
      TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: '© $_appName',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 30,
            fontFamily: 'OpenSans',
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(
          minWidth: 0, maxWidth: backgroundImage.width.toDouble());
      canvas.save();

      double copyrightX =
          (backgroundImage.width.toDouble() - textPainter.width) / 2;
      double copyrightY =
          backgroundImage.height.toDouble() - textPainter.height - 100;

      double textX =
          (backgroundImage.width.toDouble() - textPainter.width) / 2;
      double textY =
          (backgroundImage.height.toDouble() - textPainter.height) / 2;

      // canvas.translate(copyrightX, copyrightY);

      canvas.translate(textX, textY);
      textPainter.paint(canvas, Offset.zero);
      canvas.restore();
    }

    // Save the image with the copyright text
    ui.Image finalImage =
    await recorder.endRecording().toImage(quoteImage.width, quoteImage.height);
    ByteData? byteData =
    await finalImage.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      // Handle the case where conversion to ByteData failed
      print('Failed to convert image to ByteData');
      return;
    }

    Uint8List pngBytes = byteData.buffer.asUint8List();

    // Save the image using gal package
    await Gal.putImageBytes(pngBytes);

    print('Image saved using gal package');

    // Handle the result (if necessary) - Note: Gal.putImageBytes doesn't provide a result
    // You might want to add additional logic if needed

    Fluttertoast.showToast(msg: 'Image saved to gallery.');
  }


  Future<void> _shareAsImageContent(GlobalKey contentBubbleKey, GlobalKey backgroundImageKey) async {
    RenderRepaintBoundary? quoteBubbleBoundary = contentBubbleKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    RenderRepaintBoundary? backgroundImageBoundary = backgroundImageKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

    if (quoteBubbleBoundary == null || backgroundImageBoundary == null) {
      // Handle the case where one of the boundaries is not found
      print('Failed to find RenderRepaintBoundary');
      return;
    }

    double pixelRatio = MediaQuery.of(context).devicePixelRatio;

    ui.Image backgroundImage = await backgroundImageBoundary.toImage(pixelRatio: pixelRatio);
    ui.Image quoteImage = await quoteBubbleBoundary.toImage(pixelRatio: pixelRatio);
    ui.PictureRecorder recorder = ui.PictureRecorder();
    Canvas canvas = Canvas(recorder, Rect.fromLTWH(0, 0, backgroundImage.width.toDouble(), backgroundImage.height.toDouble()));
    canvas.drawImage(backgroundImage, Offset.zero, Paint());
    canvas.drawImage(quoteImage, Offset.zero, Paint());

    if (!_isProPurchased) {
      TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: '© $_appName',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 30,
            fontFamily: 'OpenSans',
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(minWidth: 0, maxWidth: backgroundImage.width.toDouble());
      canvas.save();

      double textX = (backgroundImage.width.toDouble() - textPainter.width) / 2;
      double textY = (backgroundImage.height.toDouble() - textPainter.height) / 2;

      canvas.translate(textX, textY);
      textPainter.paint(canvas, Offset.zero);
      canvas.restore();
    }

    ui.Image finalImage = await recorder.endRecording().toImage(quoteImage.width, quoteImage.height);
    ByteData? byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      // Handle the case where conversion to ByteData failed
      print('Failed to convert image to ByteData');
      return;
    }

    Uint8List pngBytes = byteData.buffer.asUint8List();

    final imagePath = await saveImage(pngBytes);
    if (imagePath != null) {
      // Image saved successfully, now share it
      await _shareImage(imagePath, subject: 'Picture from $_appName');
      // Fluttertoast.showToast(msg: 'Image saved to gallery and shared.');
    } else {
      // Handle the case where saving the image failed
      print('Failed to save image.');
      // Fluttertoast.showToast(msg: 'Failed to save image.');
    }
  }

  Future<String?> saveImage(Uint8List imageBytes) async {
    Directory? directory = await getTemporaryDirectory();
    String filePath = '${directory.path}/$_appName.png';

    try {
      await File(filePath).writeAsBytes(imageBytes);
      return filePath;
    } catch (e) {
      print('Failed to save image: $e');
      return null;
    }
  }

  Future<void> _shareImage(String imagePath, {String subject = ''}) async {
    try {
      final file = File(imagePath);

      await Share.shareFiles(
        [file.path],
        subject: subject,
      );
    } catch (e) {
      print('Failed to share image: $e');
      Fluttertoast.showToast(msg: 'Failed to share image.');
    }
  }

  Future<void> _shareAsTextContent(String content) async {
    await Share.share(content, subject: 'Shared from $_appName');
  }

  Future<void> _copyContent(String content) async {
    await Clipboard.setData(ClipboardData(text: content));
  }

  PopupMenuEntry<String> buildFontMenuItem(String fontFamily, {required String displayName, bool isProFont = false}) {
    final appTheme = Theme.of(context);
    final iconColor = appTheme.brightness == Brightness.light ? Colors.black : Colors.white;
    final fontColor = appTheme.brightness == Brightness.light ? Colors.black : Colors.white;

    return PopupMenuItem<String>(
      value: fontFamily,
      child: ListTile(
        title: Text(
          displayName,
          style: TextStyle(fontFamily: fontFamily, color: fontColor),
        ),
        trailing: _currentFontFamily == fontFamily
            ? Icon(Icons.check, color: iconColor)
            : isProFont && !_isProPurchased
            ? Image.asset('assets/icons/pro.png', width: 16, height: 16, color: iconColor)
            : null,
        enabled: !_isProPurchased || !isProFont,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
        onTap: () {
          if (!_isProPurchased && isProFont) {
            Fluttertoast.showToast(msg: 'This is a pro feature. Upgrade to unlock!');
          } else {
            setState(() {
              _currentFontFamily = fontFamily;
            });

            String displayName = fontDisplayNames[fontFamily] ?? fontFamily;
            Navigator.pop(context);
            _stateManager.saveSelectedFont(fontFamily);
          }
        },
      ),
    );
  }


  Map<String, String> fontDisplayNames = {
    'Lora': 'Serif Classic',
    'Lato': 'Seraphic',
    'Raleway': 'Grace',
    'Montserrat': 'Chic',
    'Pacifico': 'Luminous',
    'OpenSans': 'Serene',
    'NotoSerif': 'Charm',
    'Roboto': 'Modern',
    'DancingScript': 'Elegance',
    'Roobert': 'Geometric',
    'Merriweather': 'Readable',
    'PlayfairDisplay': 'Vintage',
    'LibreBaskerville': 'Refined',
    'Quicksand': 'Exquisite',
    'LeagueSpartan': 'Majestic',
    'CormorantGaramond': 'Enchanting',
  };



  Widget _buildContentGrid(int index, contentWidgetKey, backgroundImageAndContentBubbleKey) {
    //print('Debugging');
    String contentIdKey = widget.source == 'favorites' ? 'content_id' : 'id';
    String did = '';
    String content = '';
    String authorName = '';
    String categoryName = '';
    String cultureName = '';
    String authorImagePath = '';
    String cultureImagePath = '';
    String contentType = '';
    bool isAuthorContent = false;
    bool isCategoryContent = false;
    bool isCultureContent = false;
    bool isFavoriteContent = false;

    var contentData = widget.content[index];

// Common assignment
    did = contentData['did'] ?? '';
    content = contentData['content'] ?? '';
    contentType = contentData['type'] ?? '';
    cultureImagePath = contentData['image_remote'] ?? '';

    authorImagePath = widget.fromNotification
        ? (widget.authorImagePath ?? '')
        : (widget.content[index]['image_remote'] ?? contentData['author_image'] ?? contentData['image_remote'] ?? '' );

    cultureImagePath = widget.fromNotification
        ? (widget.authorImagePath ?? '')
        : (widget.content[index]['image_remote'] ?? contentData['author_image'] ?? contentData['image_remote'] ?? '' );

    // authorImagePath = quoteData['author_image'] ?? quoteData['image_remote'] ?? '';

    authorName = widget.fromNotification
        ? (widget.content[index]['authorName'] ?? '')
        : (widget.source == 'favorites'
        ? (widget.content[index]['author'] ?? '')
        : (widget.authorName ?? ''));

    categoryName = widget.fromNotification
        ? (widget.content[index]['categoryName'] ?? '')
        : (widget.source == 'favorites'
        ? (widget.content[index]['category'] ?? '')
        : (widget.categoryName ?? ''));

    cultureName = widget.fromNotification
        ? (widget.content[index]['cultureName'] ?? '')
        : (widget.source == 'favorites'
        ? (widget.content[index]['culture'] ?? '')
        : (widget.cultureName ?? ''));

// Special case assignments
    if (widget.source == 'favorites') {
      did = widget.content[index]['author_id'] ?? widget.content[index]['category_id'] ?? widget.content[index]['culture_id'];
    }else if (widget.source == 'search') {
      isAuthorContent = widget.isAuthorContent;
      isCategoryContent = widget.isCategoryContent;
      isCultureContent = widget.isCultureContent;
      if (isAuthorContent) {
        authorName = widget.name ?? '';
        did = widget.authorId ?? widget.content[index]['author_id'];
        //print('Selected Author ID: $did');
      } else if (isCategoryContent) {
        categoryName = widget.name ?? '';
        did = widget.categoryId ?? widget.content[index]['category_id'];
       // print('Selected Category ID: $did');
      } else if (isCultureContent) {
        cultureName = widget.name ?? '';
        did = widget.cultureId ?? widget.content[index]['culture_id'];
       // print('Selected Culture ID: $did');
      }
    } else {  // case where source is author, category, or culture
      isAuthorContent = widget.isAuthorContent;
      isCategoryContent = widget.isCategoryContent;
      isCultureContent = widget.isCultureContent;
      if (isAuthorContent) {
        did = widget.authorId ?? '';
       // print('Selected Author ID: $did');
      } else if (isCategoryContent) {
        did = widget.categoryId ?? '';
       // print('Selected Category ID: $did');
      } else if (isCultureContent) {
        did = widget.cultureId ?? '';
       // print('Selected Culture ID: $did');
      }
    }


    if (widget.fromNotification) {
      if (contentType == 'author') {
        // authorName = widget.content[index]['name'] ?? '';
        did = widget.content[index]['did'] ?? '';
      } else {
        // categoryName = widget.content[index]['name'] ?? '';
        did = widget.content[index]['did'] ?? '';
      }
    }
// Final assignments
    final contentId = widget.fromNotification ? contentData['qid'] ?? '' : (contentData[contentIdKey]?.toString() ?? '');

   // print('Culture image path: $cultureImagePath');
   // print('Author image path: $authorImagePath');

    Widget? authorImageWidget;
    Widget cultureImageWidget = const SizedBox.shrink();
    // if (isAuthorContent) {
    if (authorImagePath.isNotEmpty) {
      authorImageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(100.0),
        child: Image(
          image: CachedNetworkImageProvider(authorImagePath),
          width: 100,
          height: 100,
          fit: BoxFit.cover,
        ),
      );
    } else if (widget.fromNotification && isAuthorContent) {
      authorImageWidget = ValueListenableBuilder<ConnectivityResult?>(
        valueListenable: connectivityNotifier,
        builder: (BuildContext context, ConnectivityResult? connectivityResult, Widget? child) {
          if (connectivityResult != null && connectivityResult != ConnectivityResult.none) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(100.0),
              child: Image(
                image: CachedNetworkImageProvider(widget.content[index]['image'] ?? ''),
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            );
          } else {
            return const SizedBox.shrink(); // Render nothing when offline
          }
        },
      );
    }
    // Culture Image
    if (cultureImagePath.isNotEmpty) {
      cultureImageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(100.0),
        child: Image(
          image: CachedNetworkImageProvider(cultureImagePath),
          width: 100,
          height: 100,
          fit: BoxFit.cover,
        ),
      );
    }
    //}
    Color panelBackgroundColor = Colors.black.withOpacity(0.7);
    // The contentBubble definition starts here
    Widget contentBubble = GestureDetector(
      onTap: () async {
        if (_isFontSizeSliderVisible) {
          setState(() {
            _isFontSizeSliderVisible = false;
          });
        }
      },
      child: RepaintBoundary(
        key: _contentWidgetKeys[index],
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(0),
            bottomRight: Radius.circular(0),
          ),
          child: ValueListenableBuilder<bool>(
            valueListenable: widget.backgroundImageEnabled,
            builder: (BuildContext context, bool value, Widget? child) {
              return Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: value ? Colors.transparent : Colors.transparent,
                        borderRadius: value ? null : BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width, // Subtract the padding values
                    height: MediaQuery.of(context).size.height, // Set a fixed height for the quote bubble
                    child: CustomPaint(
                      size: Size(MediaQuery.of(context).size.width - 48, 300), // Update the size here too
                      painter: value
                          ? ContentBubblePainter(
                        backgroundColor: panelBackgroundColor,
                        borderRadius: 20,
                        actionIconsPanelHeight: 0,
                      )
                          : ContentBubblePainterWithoutTopRounded(
                        backgroundColor: panelBackgroundColor,
                        borderRadius: 20,
                      ),
                      child: Container(
                        padding: EdgeInsets.fromLTRB(
                          24,
                          16,
                          24,
                          value ? 60 : 80, // Add extra bottom padding when the background image is disabled
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [

                              if (categoryName.isNotEmpty ?? false)
                                InkWell(
                                  onTap: () async {
                                    await widget.onBackgroundImageChange();
                                    if (widget.source == 'favorites' || widget.fromNotification) {
                                      List<Map<String, dynamic>> content;
                                      content = await _databaseHelper.getContentByCategory(did);

                                      if (content.isEmpty) {
                                        return;
                                      }

                                      final Set<String> favoriteContent = {};
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => Scaffold(
                                            appBar: AppBar(title: Text(categoryName)),
                                            body: ContentCarousel(
                                              content: content,
                                              favoriteContent: favoriteContent,
                                              categoryName: categoryName,
                                              categoryId: did,
                                              isCategoryContent: true,
                                              onBackgroundImageChange: () async {
                                                String newBackgroundImageUrl = await BackgroundImageUtil.initBackgroundImage();
                                                setState(() {
                                                  _backgroundImageUrl = newBackgroundImageUrl;
                                                });
                                              },
                                              backgroundImageEnabled: widget.backgroundImageEnabled,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: Column(
                                    children: [
                                      Text(
                                        categoryName,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontFamily: 'Raleway',
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(
                                        width: categoryName.length * 8.0,
                                        child: const Divider(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 10),
                              if (authorImageWidget != null) authorImageWidget,
                              const SizedBox(height: 8), // Add space between author image and author name
                              if (authorName.isNotEmpty ?? false)
                                InkWell(
                                  onTap: () async {
                                    await widget.onBackgroundImageChange();
                                    if (widget.source == 'favorites') {
                                      List<Map<String, dynamic>> content;
                                     // print('AuthorID $did');
                                      content = await _databaseHelper.getContentByAuthor(did);

                                      if (content.isEmpty) {
                                        return;
                                      }

                                      final favoriteContent = await _databaseHelper.queryAllDeviceFavoriteContent();
                                      // Set the isAuthorContent flag to true when displaying author's content
                                      content = content.map((quote) {
                                        return {
                                          ...quote,
                                          'is_author_content': true,
                                        };
                                      }).toList();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => Scaffold(
                                            appBar: AppBar(title: Text(authorName)),
                                            body: ContentCarousel(
                                              content: content,
                                              favoriteContent: favoriteContent.map((content) => content['id'] as String).toSet(),
                                              authorName: authorName,
                                              authorId: did,
                                              isAuthorContent: true,
                                              onBackgroundImageChange: () async {
                                                String newBackgroundImageUrl = await BackgroundImageUtil.initBackgroundImage();
                                                setState(() {
                                                  _backgroundImageUrl = newBackgroundImageUrl;
                                                });
                                              },
                                              backgroundImageEnabled: widget.backgroundImageEnabled,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: Column(
                                    children: [
                                      Text(
                                        authorName,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontFamily: 'Raleway',
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(
                                        width: authorName.length * 8.0,
                                        child: const Divider(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 10),
                              if (cultureName.isNotEmpty ?? false)
                                InkWell(
                                  onTap: () async {
                                    await widget.onBackgroundImageChange();
                                    if (widget.source == 'favorites' || widget.fromNotification) {
                                      List<Map<String, dynamic>> content;
                                      content = await _databaseHelper.getContentByCulture(did);  // Make sure this method is defined in _databaseHelper

                                      if (content.isEmpty) {
                                        return;
                                      }

                                      final Set<String> favoriteContent = {};
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => Scaffold(
                                            appBar: AppBar(title: Text(cultureName)),
                                            body: ContentCarousel(
                                              content: content,
                                              favoriteContent: favoriteContent,
                                              cultureName: cultureName,
                                              cultureId: did,
                                              isCultureContent: true,
                                              onBackgroundImageChange: () async {
                                                String newBackgroundImageUrl = await BackgroundImageUtil.initBackgroundImage();
                                                setState(() {
                                                  _backgroundImageUrl = newBackgroundImageUrl;
                                                });
                                              },
                                              backgroundImageEnabled: widget.backgroundImageEnabled,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: Column(
                                    children: [
                                      Text(
                                        '$cultureName',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontFamily: 'Raleway',
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(
                                        width: cultureName.length * 8.0,
                                        child: const Divider(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 10),
                              InteractiveViewer(
                                minScale: 0.5,
                                maxScale: 10.0,
                                child: Text(
                                  content,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFamily: _currentFontFamily,
                                    fontSize: _currentFontSize,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: _showOverlayText,
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(seconds: 3), // Adjust the duration to control the fading speed
                      tween: Tween<double>(begin: 1.0, end: 0.0),
                      builder: (BuildContext context, double value, Widget? child) {
                        return Opacity(
                          opacity: value,
                          child: const Center(
                            child: Text(
                              'Tap to change background image',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                     // print('Tapped on the RepaintBoundary!');
                      String newBackgroundImageUrl = await BackgroundImageUtil.initBackgroundImage();
                    //  print('New Background Image URL: $newBackgroundImageUrl');
                      if (_isFontSizeSliderVisible) {
                        setState(() {
                          _isFontSizeSliderVisible = false;
                        });
                      }else{
                        setState(() {
                          _backgroundImageUrl = newBackgroundImageUrl;
                          _showOverlayText = false; // Hide the overlay text immediately after tapping
                        });
                      }
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    return Padding(
      padding: widget.margin,
      child: Stack(
        children: [
          FutureBuilder<String>(
            future: _backgroundImageFuture,
            builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(); // Show an empty container while the image is loading
              } else {
                return Positioned.fill(
                  child: ValueListenableBuilder<bool>(
                    valueListenable: widget.backgroundImageEnabled,
                    builder: (BuildContext context, bool value, Widget? child) {
                      return GestureDetector(
                        onTap: () async {
                        },
                        child: RepaintBoundary(
                          key: _backgroundImageAndContentBubbleKeys[index],
                          child: ClipRRect(
                            borderRadius: const BorderRadius.all(Radius.circular(20)), // Same border radius as contentBubble
                            child: _backgroundImageUrl.isNotEmpty
                                ? Opacity(
                              opacity: value ? 1.0 : 0.0, // Set the opacity based on the background image being enabled or disabled
                              child: CachedNetworkImage(
                                imageUrl: _backgroundImageUrl, // This should be the URL of the image you want to load.
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(
                                  child: SizedBox(
                                    height: 20.0,
                                    width: 20.0,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white70), // Change the color here
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => const Icon(Icons.error), // This is optional, displayed if there is an error loading the image.
                              ),
                            )
                                : Container(),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }
            },
          ),

          Positioned.fill(
            child: contentBubble,
          ),
          Positioned(
            bottom: ContentBubblePainter.bubbleTailHeight,
            left: 0,
            right: 0,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.zero,
              ),
              child: Material(
                type: MaterialType.transparency,
                child: ValueListenableBuilder<bool>(
                  valueListenable: widget.backgroundImageEnabled,
                  builder: (BuildContext context, bool value, Widget? child) {
                    bool isLightTheme = Theme.of(context).brightness == Brightness.light;
                    bool isIconColorBlack = !value && isLightTheme;

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: Icon(
                              _favoriteContent.contains(widget.contentId ?? contentId)
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isIconColorBlack ? Colors.white : Colors.white,
                            ),
                            onPressed: () async {
                              String currentContentId = widget.contentId ?? contentId;
                              if (_favoriteContent.contains(currentContentId)) {
                                await _databaseHelper.removeFromDeviceFavorites(currentContentId);
                                setState(() {
                                  _favoriteContent.remove(currentContentId);
                                });
                               // Fluttertoast.showToast(msg: 'Content removed from favorites.');
                              } else {
                                await _databaseHelper.addToDeviceFavorites(currentContentId);
                                setState(() {
                                  _favoriteContent.add(currentContentId);
                                });
                               // Fluttertoast.showToast(msg: 'Content added to favorites.');
                              }
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.save_alt,
                              color: isIconColorBlack ? Colors.white : Colors.white,
                            ),
                            onPressed: () async {
                              await _saveAsImage(_contentWidgetKeys[index], _backgroundImageAndContentBubbleKeys[index]);
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.copy,
                              color: isIconColorBlack ? Colors.white : Colors.white,
                            ),
                            onPressed: () async {
                              await _copyContent(content);
                            },
                          ),
                          IconButton(
                            key: _popupMenuKey,
                            icon: Icon(
                              Icons.share,
                              color: isIconColorBlack ? Colors.white : Colors.white,
                            ),
                            onPressed: () {
                              final RenderBox button = _popupMenuKey.currentContext!.findRenderObject() as RenderBox;
                              final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
                              final Offset buttonPosition = button.localToGlobal(Offset.zero, ancestor: overlay);
                              final double buttonWidth = button.size.width;
                              final double buttonHeight = button.size.height;
                              final double screenWidth = MediaQuery.of(context).size.width;
                              final double screenHeight = MediaQuery.of(context).size.height;

                              showMenu(
                                context: context,
                                position: RelativeRect.fromLTRB(
                                  (screenWidth - buttonWidth) / 2,
                                  buttonPosition.dy + buttonHeight,
                                  (screenWidth + buttonWidth) / 2,
                                  screenHeight,
                                ),
                                items: <PopupMenuEntry<String>>[
                                  const PopupMenuItem<String>(
                                    value: 'text',
                                    child: ListTile(
                                      leading: Icon(Icons.text_fields),
                                      title: Text('Share as Text'),
                                    ),
                                  ),
                                  const PopupMenuItem<String>(
                                    value: 'image',
                                    child: ListTile(
                                      leading: Icon(Icons.image),
                                      title: Text('Share as Image'),
                                    ),
                                  ),
                                ],
                              ).then((result) {
                                if (result == 'text') {
                                  // Share as text
                                  _shareAsTextContent(content);
                                } else if (result == 'image') {
                                  // Share as image
                                  _shareAsImageContent(_contentWidgetKeys[index], _backgroundImageAndContentBubbleKeys[index]);
                                }
                              });
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.format_size,
                              color: isIconColorBlack ? Colors.white : Colors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                _isFontSizeSliderVisible = !_isFontSizeSliderVisible;
                              });
                            },
                          ),
                          Visibility(
                            visible: _isFontSizeSliderVisible,
                            child: SizedBox(
                              height: 150, // Adjust the height of the vertical slider
                              child: RotatedBox(
                                quarterTurns: 3, // Rotate by 270 degrees
                                child: Slider(
                                  value: _currentFontSize,
                                  min: 16, // Minimum font size
                                  max: 58, // Maximum font size
                                  onChanged: (double newValue) {
                                    setState(() {
                                      _currentFontSize = newValue;
                                    });
                                  },
                                  activeColor: Colors.white,
                                  inactiveColor: Colors.white.withOpacity(0.5),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 48.0,
                            child: PopupMenuButton<String>(
                              icon: Icon(
                                Icons.font_download,
                                color: isIconColorBlack ? Colors.white : Colors.white,
                              ),
                              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                buildFontMenuItem('Lora', displayName: 'Serif Classic', isProFont: false),
                                buildFontMenuItem('Lato', displayName: 'Seraphic', isProFont: false),
                                buildFontMenuItem('Raleway', displayName: 'Grace', isProFont: false),
                                buildFontMenuItem('Montserrat', displayName: 'Chic', isProFont: true),
                                buildFontMenuItem('Pacifico', displayName: 'Luminous', isProFont: true),
                                buildFontMenuItem('OpenSans', displayName: 'Serene', isProFont: false),
                                buildFontMenuItem('NotoSerif', displayName: 'Charm', isProFont: false),
                                buildFontMenuItem('Roboto', displayName: 'Modern', isProFont: true),
                                buildFontMenuItem('DancingScript', displayName: 'Elegance', isProFont: true),
                                buildFontMenuItem('Roobert', displayName: 'Geometric', isProFont: true),
                                buildFontMenuItem('Merriweather', displayName: 'Readable', isProFont: true),
                                buildFontMenuItem('PlayfairDisplay', displayName: 'Vintage', isProFont: true),
                                buildFontMenuItem('LibreBaskerville', displayName: 'Refined', isProFont: true),
                                buildFontMenuItem('Quicksand', displayName: 'Exquisite', isProFont: false),
                                buildFontMenuItem('LeagueSpartan', displayName: 'Majestic', isProFont: true),
                                buildFontMenuItem('CormorantGaramond', displayName: 'Enchanting', isProFont: true),
                              ],
                              onSelected: (String value) async {
                                await _stateManager.saveSelectedFont(value);
                                setState(() {
                                  _currentFontFamily = value;
                                });

                                String displayName = fontDisplayNames[value] ?? value;
                               // Fluttertoast.showToast(msg: 'Selected font: $displayName');
                              },
                              offset: const Offset(0, 100), // Adjust the y-axis value as needed
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.volume_up,
                              color: isIconColorBlack ? Colors.white : Colors.white,
                            ),
                            onPressed: () {
                              _speakContent(content);
                            },
                          ),
                        ],
                      ),
                    );

                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    Color progressColor = themeData.brightness == Brightness.dark ? Colors.white : Colors.black54;
    Color textColor = themeData.brightness == Brightness.dark ? Colors.white : Colors.black54;
    int itemCount = widget.content.length + (widget.content.length ~/ 3);
    return Padding(
      padding: widget.padding,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _databaseHelper.fetchAdSettings(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            Map<String, dynamic>? bannerAdSettings = snapshot.data?['Carousel'];
            bool bannerAdEnabled = bannerAdSettings?['enabled'] ?? false;
            if (!bannerAdEnabled || _isProPurchased) {
              itemCount = widget.content.length;
            }
            return PageView.builder(
              itemCount: itemCount,
              itemBuilder: (BuildContext context, int index) {
                if (index != 0 && (index + 1) % 4 == 0 && bannerAdEnabled && !_isProPurchased && widget.source != 'favorites') {
                  return FutureBuilder<ConnectivityResult>(
                    future: Connectivity().checkConnectivity(),
                    builder: (BuildContext context, AsyncSnapshot<ConnectivityResult> connectivitySnapshot) {
                      bool isOnline = connectivitySnapshot.data != ConnectivityResult.none;

                      if (isOnline) {
                        String adUnitId = bannerAdSettings?['adUnitId'] ?? '';
                        String adProvider = bannerAdSettings?['adProvider'] ?? 'admob';
                        String customAdCode = bannerAdSettings?['customAdCode'] ?? '';
                        AdFormat adFormat = AdFormat.values.firstWhere(
                              (element) => element.toString().split('.')[1] == (bannerAdSettings?['adFormat'] ?? 'banner'),
                          orElse: () => AdFormat.banner,
                        );
                        if (bannerAdEnabled && !_isProPurchased) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: themeData.cardColor,
                            ),
                            margin: const EdgeInsets.all(0),
                            padding: const EdgeInsets.all(4),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Advertisement',
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.normal,
                                    fontFamily: 'Merriweather',
                                    color: themeData.brightness == Brightness.light ? Colors.black54 : Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 0),
                                Expanded(
                                  child: UniversalAdWidget(
                                    adUnitId: adUnitId,
                                    adFormat: adFormat,
                                    context: context,
                                    adProvider: adProvider,
                                    customAdCode: customAdCode,
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else {
                          return const SizedBox.shrink();
                        }
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                  );
                } else {
                  int contentIndex = index;
                  if (index >= 3 && bannerAdEnabled && !_isProPurchased) {
                    // Adjusting quoteIndex for skipped ad positions
                    contentIndex -= (index + 1) ~/ 4;
                  }
                  if (contentIndex < widget.content.length) {
                    return _buildContentGrid(
                      contentIndex,
                      _contentWidgetKeys[contentIndex],
                      _backgroundImageAndContentBubbleKeys[contentIndex],
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                }
              },
              scrollDirection: Axis.vertical,
            );
          } else {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            );
          }
        },
      ),
    );
  }
}