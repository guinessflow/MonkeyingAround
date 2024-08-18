import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '/screens/favorites_screen.dart';
import '/screens/content_category_view.dart';
import '/widgets/universal_ad_widget.dart';
import '/widgets/segment_menu.dart';
import '/widgets/search_results_widget.dart';
import '/widgets/category_grid.dart';
import '/widgets/authors_grid.dart';
import '/widgets/cultures_grid.dart';
import '/widgets/persistent_footer.dart';
import '/models/fcm_notification_manager.dart';
import '/models/subscription_helper.dart';
import '/models/ThemeProvider.dart';
import '/models/device_manager.dart';
import '/models/database_helper.dart';
import '/utils/state_manager.dart';
import '/utils/utils.dart';

final stateManager = StateManager();

int _selectedIndex = 0;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await DatabaseHelper.instance.init();

  await InAppPurchase.instance.isAvailable();
  MobileAds.instance.initialize();
  await signInAnonymously();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    clearCacheOnExit();
  });

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: MaterialApp(
        theme: ThemeData.light(), // Set the light theme as default
        darkTheme: ThemeData.dark(), // Set the dark theme
        themeMode: ThemeMode.system, // Use the system theme mode
        home: const MainApp(),
      ),
    ),
  );

  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setBool('app_restarted', true); // Set the flag to indicate app restart
}

void clearCacheOnExit() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.clear();
}

Future<void> signInAnonymously() async {
  try {
    UserCredential userCredential = await FirebaseAuth.instance.signInAnonymously();
    User? user = userCredential.user;
    if (user != null) {
      // print('User ID: ${user.uid}');
      // Perform any other necessary actions with the authenticated user
    }
  } catch (e) {
    //print('Failed to sign in anonymously: $e');
  }
}

class MainApp extends StatefulWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.light);
  final ValueNotifier<bool> showWelcomeContentNotifier = ValueNotifier<bool>(true);
  bool _initialized = false;


  @override
  void initState() {
    super.initState();
    _initializeApp(context);
  }

  Future<bool> _checkDatabaseEmpty() async {
    return await DatabaseHelper.instance.isDatabaseEmpty();
  }

  Future<void> _initializeApp(BuildContext context) async {
    bool isOnline = await checkIsOnline();

    if (isOnline) {
      try {
        await signInAnonymously();

        bool isDatabaseEmpty = await _checkDatabaseEmpty();

        if (isDatabaseEmpty) {
          await DatabaseHelper.instance.recreateDatabase();
          await DatabaseHelper.instance.fetchEssentialData();
          await DatabaseHelper.instance.syncBackgroundImagesIfNeeded();
        } else {
          // Fetch essential data from Firebase even if the database is not empty
          await DatabaseHelper.instance.fetchEssentialData();
        }

        setState(() {
          _initialized = true;
        });

        Navigator.of(context).pushReplacementNamed('/main');
      } catch (e) {
        print('Error initializing app: $e');
        // Handle error appropriately
      }
    } else {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          final themeProvider = Provider.of<ThemeProvider>(dialogContext);
          final themeData = themeProvider.themeMode == ThemeMode.light
              ? ThemeData.light()
              : ThemeData.dark();
          return AlertDialog(
            title: Text(
              'No Internet Connection',
              style: TextStyle(
                color: themeData.brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
            ),
            content: Text(
              'Please check your internet connection and try again.',
              style: TextStyle(
                color: themeData.brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: themeData.brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _initializeApp(context);
                },
              ),
            ],
            backgroundColor:
            themeData.brightness == Brightness.dark ? Colors.grey[900] : Colors.white,
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      final themeData = Theme.of(context);
      final progressColor = themeData.brightness == Brightness.dark ? Colors.white : Colors.black;
      final textColor = themeData.brightness == Brightness.dark ? Colors.white : Colors.black;
      return Scaffold(
        backgroundColor: themeData.scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
              const SizedBox(height: 20),
              Text(
                'Loading...',
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: 'Merriweather',
                  // fontStyle: FontStyle.italic,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      );
    }
    else {
      return ChangeNotifierProvider(
        create: (context) => ThemeProvider(),
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'MyApp',
              theme: ThemeData.light(),
              darkTheme: ThemeData.dark(),
              themeMode: themeProvider.themeMode,
              home: MainScreen(
                focusNode: FocusNode(),
                showWelcomeContentNotifier: ValueNotifier<bool>(true),
              ),
              routes: <String,WidgetBuilder>{
                '/main': (context) => MainScreen(
                  focusNode: FocusNode(),
                  showWelcomeContentNotifier: ValueNotifier<bool>(true),
                ),
              },
              //initialRoute: MainScreen.routeName,
              //initialroute added and <String,WidgetBuilder> added
            );
          },
        ),
      );
    }
  }
}


Future<void> customBackgroundMessageHandler(RemoteMessage message) async {
  // print('Handling a background message: ${message.messageId}');
}

class MainScreen extends StatefulWidget {
  final FocusNode focusNode;
  final ValueNotifier<bool> showWelcomeContentNotifier;

  //static const String routeName = "/";
  const MainScreen({Key? key, required this.focusNode, required this.showWelcomeContentNotifier}) : super(key: key);
  //final String title;
  @override
  _MainScreenState createState() => _MainScreenState();
} //added static const string routename = "/"; and final string title;

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  DeviceManager deviceManager = DeviceManager(firestore: FirebaseFirestore.instance);
  late DatabaseHelper dbHelper;
  String _appName = '';
  String _selectedFontFamily = '';
  double _fontSize = 18.0;
  bool _isLoading = true;
  bool _isAdLoaded = false;
  bool _isProPurchased = false;
  final FocusNode _searchBarFocusNode = FocusNode();
  bool _isSearchBarFocused = false; // Track the focus state of the search bar
  List<String> _favoriteQuotes = [];
  late final AudioPlayer player;
  String? _selectedCategory;
  String? _selectedAuthor;
  String? _selectedCulture;
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<bool> tapSoundEnabled = ValueNotifier<bool>(true);
  final ValueNotifier<bool> darkThemeEnabled = ValueNotifier<bool>(false);
  final ValueNotifier<bool> backgroundImageEnabled = ValueNotifier<bool>(true);
  final ValueNotifier<Map<String, dynamic>> _randomContentNotifier = ValueNotifier<Map<String, dynamic>>({});
  final dailyContentNotifier = ValueNotifier<bool>(false);
  final FocusNode segmentMenuFocusNode = FocusNode();
  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(
      ThemeMode.system);
  final ValueNotifier<String> _searchQuery = ValueNotifier<String>('');
  late Future<List<Map<String, dynamic>>> _searchResultsFuture;
  final ValueNotifier<String> _searchType = ValueNotifier<String>('categories');

  // Firestore collection reference
  final CollectionReference _purchaseCollection =
  FirebaseFirestore.instance.collection('purchases');

  Future<void> _checkPurchaseStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isProPurchased = prefs.getBool('isProPurchased') ?? false;

    if (!_isProPurchased) {
      // Fetch the user ID
      String? userId = await deviceManager.getUserId();

      if (userId != null) {
        // Query Firestore for the purchase status
        QuerySnapshot purchaseSnapshot = await _purchaseCollection
            .where('userId', isEqualTo: userId)
            .where('purchaseStatus', whereIn: ['PurchaseStatus.purchased','PurchaseStatus.restored'])
            .get();

        // Set the _isProPurchased flag based on the existence of the document
        setState(() {
          _isProPurchased = purchaseSnapshot.docs.isNotEmpty;
        });

        // Save the _isProPurchased flag to state persistence
        prefs.setBool('isProPurchased', _isProPurchased);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // signInAnonymously();
      // App resumed from background
      // Perform any necessary actions
    } else if (state == AppLifecycleState.inactive) {
      // App inactive (e.g., in the background or transitioning)
      // Perform any necessary actions
    } else if (state == AppLifecycleState.paused) {
      // App paused (e.g., in the background)
      // Call signOut() method
      // signOut();
    }
  }

  void _updateSearchQuery(String query) {
    if (_searchQuery.value != query) {
      _searchQuery.value = query;
      _searchResultsFuture = _getSearchResults(query);
    }
  }

  void _onThemeChanged(ThemeMode theme) {
    if (mounted) {
      setState(() {
        themeModeNotifier.value = theme;
      });
      stateManager.saveSelectedThemeMode(theme);
    }
  }

  Future<Map<String, dynamic>> _getRandomQuote() async {
    final dbHelper = DatabaseHelper.instance;
    List<String> quoteTypes = ['category_quotes', 'author_quotes'];
    String quoteType = quoteTypes[Random().nextInt(quoteTypes.length)];
    List<Map<String, dynamic>> allQuotes = await dbHelper.queryAllRows(table: quoteType);
    if (allQuotes.isNotEmpty) {
      Map<String, dynamic> randomQuote = allQuotes[Random().nextInt(allQuotes.length)];
      return randomQuote;
    } else {
      return {}; // Return an empty map if no quotes are found
    }
  }

  InterstitialAd? _interstitialAd;

  void _loadInterstitialAd() async {
    Map<String, dynamic> adSettings = await dbHelper.fetchAdSettings();
    Map<String, dynamic> interstitialAdSettings = adSettings['Interstitial'];
    if (interstitialAdSettings['enabled'] == true) {
      String interstitialAdUnitId = interstitialAdSettings['adUnitId'];
      if (interstitialAdUnitId.isNotEmpty) {
        InterstitialAd.load(
          adUnitId: interstitialAdUnitId,
          request: const AdRequest(),
          adLoadCallback: InterstitialAdLoadCallback(
            onAdLoaded: (InterstitialAd ad) {
              _interstitialAd = ad;
              _showInterstitialAd();
            },
            onAdFailedToLoad: (LoadAdError error) {
              // print('InterstitialAd failed to load: $error');
            },
          ),
        );
      }
    }
  }

  void _showInterstitialAd() {
    if (_isProPurchased) {
      return; // If the user has purchased the pro version, do not show the ad
    }

    if (_interstitialAd == null) {
      // print('Warning: attempt to show interstitial before loaded.');
      return;
    }

    _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) {
        // print('InterstitialAd showed full screen content.');
      },
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        // print('InterstitialAd dismissed full screen content.');
        ad.dispose();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        // print('InterstitialAd failed to show full screen content: $error');
        ad.dispose();
      },
    );

    _interstitialAd?.show();
    _interstitialAd = null;
  }

  Future<void> _fetchProPurchasedStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isProPurchased = prefs.getBool('isProPurchased') ?? false;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchAppSettings();
    _checkPurchaseStatus();
    dbHelper = DatabaseHelper.instance;
    stateManager.loadSelectedThemeMode().then((ThemeMode themeMode) {
      if (mounted) {
        setState(() {
          themeModeNotifier.value = themeMode;
        });
      }
    });

    WidgetsBinding.instance.addObserver(this);
    player = AudioPlayer();
    _searchController.addListener(() {
      _updateSearchQuery(_searchController.text);
    });
    _searchResultsFuture = _getSearchResults(_searchController.text);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchBarFocusNode.unfocus(); // Unfocus search bar after the first frame
    });

    String userID;

    deviceManager.getUserId().then((String? userId) {
      if (userId != null) {
        SubscriptionHelper.getDailyContentSubscription(userId: userId).then((bool isSubscribed) {
          if (mounted) {
            setState(() {
              dailyContentNotifier.value = isSubscribed;
            });
          }
        });
      } else {
        //  print('Error: User ID not found');
      }
    });

    FCMNotificationManager.initializeFCM(context, themeModeNotifier, (backgroundImageLocalUrl) {
      // Add your implementation for updating the background image here
    });

    _getRandomQuote().then((Map<String, dynamic> randomQuote) {
      setState(() {
        _randomContentNotifier.value = randomQuote;
      });
    });
    // Retrieve the value of _isAdLoaded from SharedPreferences
    SharedPreferences.getInstance().then((prefs) {
      bool? isAdLoaded = prefs.getBool('_isAdLoaded');
      if (mounted) {
        setState(() {
          _isAdLoaded = isAdLoaded ?? false;
        });
      }
    });
    _loadInterstitialAd(); // Load the interstitial ad
  }

  Future<void> _fetchAppSettings() async {
    try {
      setState(() {
        _isLoading = true;
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Try to fetch app settings from shared preferences
      _appName = prefs.getString('appName') ?? '';
      _selectedFontFamily = prefs.getString('fontFamily') ?? '';
      _fontSize = prefs.getDouble('fontSize') ?? 18.0;

      // If app settings are not in shared preferences, fetch from the database
      if (_appName.isEmpty || _selectedFontFamily.isEmpty || _fontSize.isNaN) {
        Map<String, dynamic> appSettings = await DatabaseHelper.fetchAppSettings();

        setState(() {
          _appName = appSettings['appName'];
          _selectedFontFamily = appSettings['fontFamily'];
          _fontSize = appSettings['fontSize'] ?? 18.0;
          _isLoading = false;
        });

        // Save app settings to shared preferences
        prefs.setString('appName', _appName);
        prefs.setString('fontFamily', _selectedFontFamily);
        prefs.setDouble('fontSize', _fontSize);
      } else {
        // If app settings are in shared preferences, set loading state to false
        setState(() {
          _isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
    }
  }


  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    player.dispose();
    _searchBarFocusNode.dispose();
    _searchController.dispose();
    // signOut();
    super.dispose();
  }

  Future<void> updateFavoritesList() async {
    List<Map<String, dynamic>> favoriteQuotes = await dbHelper.queryAllDeviceFavoriteContent();
    if (mounted) {
      setState(() {
        _favoriteQuotes = favoriteQuotes.map((quote) => quote['id'] as String).toList();
      });
    }
  }

  Future<bool> _shouldShowQuoteOfTheDay() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? lastDisplayed = prefs.getString('lastDisplayedDate');

    // Check if lastDisplayed is not null before parsing
    DateTime lastDisplayedDate = lastDisplayed != null
        ? DateTime.parse(lastDisplayed)
        : DateTime(2000);

    DateTime currentDate = DateTime.now();
    return currentDate.year != lastDisplayedDate.year ||
        currentDate.month != lastDisplayedDate.month ||
        currentDate.day != lastDisplayedDate.day;
  }


  Future<void> _setLastDisplayedDate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastDisplayedDate', DateTime.now().toIso8601String());
  }

  // Add a new boolean variable in the _MainScreenState class

  void _toggleSearchBarFocus() {
    setState(() {
      _isSearchBarFocused = !_isSearchBarFocused;
      if (_isSearchBarFocused) {
        _searchBarFocusNode.requestFocus();
      } else {
        _searchBarFocusNode.unfocus();
      }
    });
  }

  Widget _searchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).brightness == Brightness.light
            ? Colors.grey[200]
            : Colors.grey[900],
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Icon(Icons.search, color: Theme.of(context).iconTheme.color),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: _toggleSearchBarFocus,
              child: TextField(
                controller: _searchController,
                focusNode: _searchBarFocusNode,
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).hintColor,
                  ),
                  border: InputBorder.none,
                ),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _searchController,
            builder: (context, value, child) {
              return value.text.isNotEmpty
                  ? InkWell(
                onTap: () {
                  setState(() {
                    _searchController.clear();
                    _updateSearchQuery(_searchController.text);
                    _searchBarFocusNode.unfocus();
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  height: 24,
                  width: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              )
                  : _customClearButton();
            },
          ),
        ],
      ),
    );
  }


  Widget _customClearButton() {
    final theme = Theme.of(context);
    final isLightTheme = theme.brightness == Brightness.light;
    final buttonColor = isLightTheme ? theme.hintColor.withOpacity(0.5) : Colors.white;
    final iconColor = isLightTheme ? Colors.white : theme.hintColor;

    return Visibility(
      visible: _searchController.text.isNotEmpty,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _searchController.clear();
            _searchBarFocusNode.unfocus();
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: buttonColor,
            ),
            height: 24,
            width: 24,
            child: Icon(Icons.close, color: iconColor, size: 18),
          ),
        ),
      ),
    );
  }



  Widget _buildBody() {
    return ValueListenableBuilder<String>(
      valueListenable: _searchQuery,
      builder: (BuildContext context, String searchQuery, Widget? child) {
        if (searchQuery.isNotEmpty) {
          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _searchResultsFuture,
            builder: (BuildContext context,
                AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else {
                final results = snapshot.data!;
                if (results.isEmpty) {
                  return const Center(child: Text('No results found.'));
                } else {
                  return SearchResultsWidget(
                    searchdata: results,
                    searchByCategory: _selectedIndex == 0, // Enable category search when selectedIndex is 0
                    searchByAuthor: _selectedIndex == 4, // Enable author search when selectedIndex is 1
                    searchByCulture: _selectedIndex == 1, // Enable culture search when selectedIndex is 2
                    searchByFavorite: _selectedIndex == 2,
                    backgroundImageEnabled: backgroundImageEnabled,
                  );
                }
              }
            },
          );
        }
        switch (_selectedIndex) {
          case 0:
            return _selectedCategory == null
                ? CategoryGrid(
              tapSoundEnabled: true,
              player: player,
              onCategorySelected: (category) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              backgroundImageEnabled: backgroundImageEnabled,
              randomContentNotifier: _randomContentNotifier,
              showWelcomeContentNotifier: widget.showWelcomeContentNotifier,
            )
                : ContentCategoryView(
              category: _selectedCategory!,
              tapSoundEnabled: true,
              onBackPressed: () {
                setState(() {
                  _selectedCategory = null;
                });
              },
              backgroundImageEnabled: backgroundImageEnabled,
            );
          case 4:
            return AuthorsGrid(
              tapSoundEnabled: true,
              player: player,
              onAuthorSelected: (author) {
                setState(() {
                  _selectedAuthor = author;
                });
              },
              backgroundImageEnabled: backgroundImageEnabled,
            );
          case 1: // When Cultures icon is tapped
            return CulturesGrid(
              tapSoundEnabled: true,
              player: player,
              onCultureSelected: (culture) {
                setState(() {
                  _selectedCulture = culture;
                });
              },
              backgroundImageEnabled: backgroundImageEnabled,
            );
          case 2:
            return FavoritesScreen(
              onBackgroundImageChange: () async {
                // Add your implementation for updating the background image here
              },
              backgroundImageEnabled: backgroundImageEnabled,
            );
          default:
            return CategoryGrid(
              tapSoundEnabled: true,
              player: player,
              onCategorySelected: (category) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              backgroundImageEnabled: backgroundImageEnabled,
              randomContentNotifier: _randomContentNotifier,
              showWelcomeContentNotifier: widget.showWelcomeContentNotifier,
            );
        }
      },
    );
  }


  // Add this method to fetch search results based on the query
  Future<List<Map<String, dynamic>>> _getSearchResults(String searchQuery) async {
    if (searchQuery.isNotEmpty) {
      final dbHelper = DatabaseHelper.instance;
      if (_selectedIndex == 0) { // Search for categories
        final categories = await dbHelper.queryCategories(searchQuery);
        return categories;
      } else if (_selectedIndex == 4) { // Search for authors
        final authors = await dbHelper.queryAuthors(searchQuery);
        return authors;
      } else if (_selectedIndex == 1) { // Search for cultures
        final cultures = await dbHelper.queryCultures(searchQuery);
        return cultures;
      } else if (_selectedIndex == 2) { // Search for cultures
        final cultures = await dbHelper.getSearchFavoriteContent(searchQuery);
        return cultures;
      } else {
        return [];
      }
    } else {
      return [];
    }
  }


  // sample ad widget
  Widget sampleAdWidget = const Card(
    child: Padding(
      padding: EdgeInsets.all(10),
      child: Text(
        'This is a sample ad',
        style: TextStyle(fontSize: 20),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    String appBarTitle = _appName.isNotEmpty ? _appName : '';
    return GestureDetector(
      onTap: () {
        _searchBarFocusNode.unfocus();
      },
      child: Listener(
        onPointerDown: (_) {
          if (segmentMenuFocusNode.hasFocus) {
            segmentMenuFocusNode.unfocus();
          }
        },
        child: ValueListenableBuilder<ThemeMode>(
          valueListenable: themeModeNotifier,
          builder: (BuildContext context, ThemeMode themeMode, Widget? child) {
            ThemeData lightTheme = ThemeData.light().copyWith(
              appBarTheme: AppBarTheme(
                backgroundColor: Colors.grey.shade200,
                iconTheme: const IconThemeData(color: Colors.black),
                titleTextStyle: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );

            ThemeData darkTheme = ThemeData.dark().copyWith(
              appBarTheme: AppBarTheme(
                backgroundColor: Colors.grey[850]!,
                iconTheme: const IconThemeData(color: Colors.white),
                titleTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );

            return MaterialApp(
              title: 'ClientApp',
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: themeMode,
              home: Scaffold(
                appBar: AppBar(
                  title: Text(
                    appBarTitle,
                    style: TextStyle(
                      fontFamily: _selectedFontFamily,
                      fontSize: _fontSize,
                    ),
                  ),
                ),
                body: Column(
                  children: <Widget>[
                    Expanded(
                      child: GestureDetector(
                        child: Column(
                          children: [
                            _searchBar(),
                            Expanded(child: _buildBody()),
                          ],
                        ),
                      ),
                    ),
                    FutureBuilder<ConnectivityResult>(
                      future: Connectivity().checkConnectivity(),
                      builder: (BuildContext context, AsyncSnapshot<ConnectivityResult> connectivitySnapshot) {
                        bool isOnline = connectivitySnapshot.data != ConnectivityResult.none;

                        if(isOnline){
                          return FutureBuilder<Map<String, dynamic>>(
                            future: dbHelper.fetchAdSettings(),
                            builder: (context, snapshot) {
                              if(snapshot.hasData){
                                Map<String, dynamic>? bannerAdSettings = snapshot.data?['FooterBanner'];
                                String adUnitId = bannerAdSettings?['adUnitId'] ?? '';
                                String adProvider = bannerAdSettings?['adProvider'] ?? 'admob';
                                String customAdCode = bannerAdSettings?['customAdCode'] ?? '';
                                bool bannerAdEnabled = bannerAdSettings?['enabled'] ?? false;
                                AdFormat adFormat = AdFormat.values.firstWhere(
                                      (element) => element.toString().split('.')[1] == (bannerAdSettings?['adFormat'] ?? 'banner'),
                                  orElse: () => AdFormat.banner,
                                );

                                if(bannerAdEnabled  && !_isProPurchased){
                                  return Container(
                                    padding: const EdgeInsets.all(2.0), // Add padding to the container
                                    margin: const EdgeInsets.all(2.0), // Add margin to the container
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        // Text(
                                        //   'Sponsored',
                                        //   style: Theme.of(context).textTheme.bodyLarge, // Use the theme's caption text style
                                        // ),
                                        const SizedBox(height: 0.0), // Adjust the spacing as needed
                                        SizedBox(
                                          height: 60.0,
                                          child: UniversalAdWidget(
                                            adUnitId: adUnitId,
                                            adFormat: adFormat,
                                            context: context,
                                            adProvider: adProvider,
                                            customAdCode: customAdCode,
                                            adHeight: 50.0,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                else {
                                  return const SizedBox.shrink();
                                }
                              }
                              return const SizedBox.shrink();  // Return an empty widget if there are no ads
                            },
                          );
                        } else {
                          return const SizedBox.shrink();  // Return an empty widget if there is no internet
                        }
                      },
                    ),
                    PersistentFooter(
                      selectedIndex: _selectedIndex,
                      onItemTapped: (index) async {
                        // await stateManager.saveCurrentIndex(index);
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                      segmentMenu: SegmentMenu(
                        focusNode: segmentMenuFocusNode,
                        onThemeChanged: _onThemeChanged,
                        tapSoundEnabled: tapSoundEnabled,
                        dailyContentEnabled: dailyContentNotifier,
                        currentThemeMode: themeModeNotifier,
                        backgroundImageEnabled: backgroundImageEnabled,
                        onBackgroundImageEnabledChanged: (bool isEnabled) {
                          setState(() {
                            backgroundImageEnabled.value = isEnabled;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

      ),
    );
  }
}