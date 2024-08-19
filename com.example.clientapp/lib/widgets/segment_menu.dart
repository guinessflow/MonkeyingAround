import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '/screens/contact_us.dart';
import '/screens/privacy_policy.dart';
import '/models/subscription_helper.dart';
import '/models/device_manager.dart';
import '/screens/terms_of_service.dart';
import '/models/in_app_purchase_manager.dart';
import '/models/database_helper.dart';

extension StringExtension on String {
  String capitalize() {
    return length > 0 ? this[0].toUpperCase() + substring(1) : this;
  }
}

class SegmentMenu extends StatefulWidget {
  final FocusNode focusNode;
  final Function(ThemeMode) onThemeChanged;
  final ValueNotifier<bool> tapSoundEnabled;
  final ValueNotifier<bool> dailyContentEnabled;
  final ValueNotifier<ThemeMode> currentThemeMode;
  final ValueNotifier<bool> backgroundImageEnabled;
  final ValueChanged<bool> onBackgroundImageEnabledChanged;

  const SegmentMenu({
    Key? key,
    required this.focusNode,
    required this.onThemeChanged,
    required this.tapSoundEnabled,
    required this.dailyContentEnabled,
    required this.currentThemeMode,
    required this.backgroundImageEnabled,
    required this.onBackgroundImageEnabledChanged,
  }) : super(key: key);

  @override
  _SegmentMenuState createState() => _SegmentMenuState();
}

class _SegmentMenuState extends State<SegmentMenu> {
  TextEditingController _appNameController = TextEditingController();
  final InAppPurchaseManager _inAppPurchaseManager = InAppPurchaseManager();
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  late SharedPreferences _prefs;
  ValueNotifier<bool> dailyQuoteNotifier = ValueNotifier(false);
  DeviceManager deviceManager = DeviceManager(firestore: FirebaseFirestore.instance);

  // Firestore collection reference
  final CollectionReference _purchaseCollection =
  FirebaseFirestore.instance.collection('purchases');

  bool _isProPurchased = false;

  String? _userId;
  bool _isSubscribed = false;
  String _appName = '';
  String _selectedFontFamily = '';
  String _privacyPolicyUrl = '';
  String _termsOfServiceUrl = '';
  String _upgradeCopy = '';
  String _thankyouCopy = '';
  String _productId = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeUserIdAndSubscription();
    _inAppPurchaseManager.initialize();
    _checkPurchaseStatus();
    _fetchAppSettings();
  }

  Future<void> _fetchAppSettings() async {
    try {
      setState(() {
        _isLoading = true; // Set loading state to true before fetching
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Try to fetch app settings from shared preferences
      _appName = prefs.getString('appName') ?? '';
      _selectedFontFamily = prefs.getString('fontFamily') ?? '';
      _privacyPolicyUrl = prefs.getString('privacyPolicyUrl') ?? '';
      _termsOfServiceUrl = prefs.getString('termsOfServiceUrl') ?? '';
      _upgradeCopy = prefs.getString('upgradeCopy') ?? '';
      _thankyouCopy = prefs.getString('thankyouCopy') ?? '';
      _productId = prefs.getString('productId') ?? '';


      // If app settings are not in shared preferences, fetch from the database
      if (_appName.isEmpty ||
          _selectedFontFamily.isEmpty ||
          _privacyPolicyUrl.isEmpty ||
          _termsOfServiceUrl.isEmpty || _upgradeCopy.isEmpty || _thankyouCopy.isEmpty || _productId.isEmpty) {
        Map<String, dynamic> appSettings = await DatabaseHelper.fetchAppSettings();

        setState(() {
          _appName = appSettings['appName'];
          _selectedFontFamily = appSettings['fontFamily'];
          _privacyPolicyUrl = appSettings['privacyPolicyUrl'];
          _termsOfServiceUrl = appSettings['termsOfServiceUrl'];
          _upgradeCopy = appSettings['upgradeCopy'];
          _thankyouCopy = appSettings['thankyouCopy'];
          _productId = appSettings['productId'];
          _isLoading = false;
        });

        // Save app settings to shared preferences
        prefs.setString('appName', _appName);
        prefs.setString('fontFamily', _selectedFontFamily);
        prefs.setString('privacyPolicyUrl', _privacyPolicyUrl);
        prefs.setString('termsOfServiceUrl', _termsOfServiceUrl);
        prefs.setString('upgradeCopy', _upgradeCopy);
        prefs.setString('thankyouCopy', _thankyouCopy);
        prefs.setString('productId', _productId);
      } else {
        // If app settings are in shared preferences, set loading state to false
        setState(() {
          _isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        _isLoading = false; // Set loading state to false on error
      });
      print('Error fetching app settings: $error');
    }
  }

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
            .where('purchaseStatus',
            whereIn: ['PurchaseStatus.purchased', 'PurchaseStatus.restored'])
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

  Future<void> _savePurchaseStatus(
      String purchaseId, String userId, String productId, PurchaseStatus purchaseStatus) async {
    Map<String, dynamic> purchaseData = {
      'purchaseId': purchaseId,
      'userId': userId,
      'productId': productId,
      'purchaseStatus': purchaseStatus.toString(), // Store the purchase status as a string
      'timestamp': FieldValue.serverTimestamp(),
    };

    // Save the purchase information to Firestore
    await _purchaseCollection.doc(purchaseId).set(purchaseData);
    print('Purchase information saved to Firestore.');

    // Save the _isProPurchased flag to state persistence
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isProPurchased', true);
  }

  Future<List<ProductDetails>> fetchProducts(List<String> productIds) async {
    return await _inAppPurchaseManager.fetchProducts(productIds);
  }

  Future<void> initiatePurchase(ProductDetails productDetails) async {
    await _inAppPurchaseManager.initiatePurchase(productDetails);
  }

  Future<void> _upgradeToProVersion(BuildContext context) async {
    try {
      // Fetch the product details for the pro version
      List<String> productIds = [_productId];
      List<ProductDetails> products = await fetchProducts(productIds);

      // Handle billing response
      _subscription?.resume(); // Resume the purchase subscription
      final Stream<List<PurchaseDetails>> purchaseUpdatedStream =
          InAppPurchase.instance.purchaseStream;
      print(purchaseUpdatedStream);
      late StreamSubscription<List<PurchaseDetails>> purchaseUpdatedSubscription;
      purchaseUpdatedSubscription = purchaseUpdatedStream.listen(
            (purchaseDetailsList) async {
          print(purchaseUpdatedSubscription);
          for (PurchaseDetails purchaseDetails in purchaseDetailsList) {
            if (purchaseDetails.status == PurchaseStatus.pending) {
              // Handle pending purchase if necessary
            } else if (purchaseDetails.status == PurchaseStatus.error) {
              // Purchase failed

              // Show a failure message or perform any other necessary actions
              Fluttertoast.showToast(
                msg: 'Failed to complete purchase.',
                backgroundColor: Colors.red,
              );
            } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                purchaseDetails.status == PurchaseStatus.restored) {
              // Purchase was successful
              // Fetch the user ID
              String? userId = await deviceManager.getUserId();
              if (userId != null) {
                // Save the purchase information to Firestore
                _savePurchaseStatus(
                  purchaseDetails.purchaseID!,
                  userId,
                  purchaseDetails.productID,
                  purchaseDetails.status,
                );
              } else {
                // Handle the case when userId is null
                // Fluttertoast.showToast(
                //  msg: 'Failed to retrieve user ID. Please try again.',
                //   backgroundColor: Colors.red,
                // );
                return; // Exit the method if userId is null
              }

              // Perform any additional actions or update the app's state accordingly
              showDialog(
                context: context,
                barrierDismissible: true,
                builder: (BuildContext context) {
                  // Get the current theme
                  ThemeData theme = Theme.of(context);

                  // Determine the text color based on the theme brightness
                  Color textColor = theme.brightness == Brightness.dark ? Colors.white : Colors.black;

                  // Determine the background color based on the theme
                  Color backgroundColor = theme.dialogBackgroundColor ?? Colors.white;

                  // Determine the accent color based on the theme color scheme
                  //Color accentColor = theme.colorScheme.secondary ?? Colors.black;

                  return AlertDialog(
                    backgroundColor: backgroundColor,
                    title: Text(
                      "Congratulations!",
                      style: TextStyle(
                        color: textColor,
                        fontFamily: "OpenSans",
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    content: Text(
                      _thankyouCopy,
                      style: TextStyle(
                        color: textColor,
                        fontFamily: "OpenSans",
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    actions: [
                      TextButton(
                        child: Text(
                          "OK",
                          style: TextStyle(
                            color: textColor,
                            fontFamily: "OpenSans",
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context, rootNavigator: true).pop();
                        },
                      ),
                    ],
                  );
                },
              );

              // Acknowledge the purchase
              InAppPurchase.instance.completePurchase(purchaseDetails);
            } else {
              // Show a failure message if product details are not available
              Fluttertoast.showToast(
                msg: 'Failed to initiate purchase. Please try again.',
                backgroundColor: Colors.red,
              );
            }
          }
        },
        onError: (error) {
          // Handle error if any occurs
          print('Purchase error: $error');
        },
        onDone: () {
          purchaseUpdatedSubscription.cancel();
        },
      );

      // Request the purchase
      InAppPurchase.instance.buyNonConsumable(
        purchaseParam: PurchaseParam(
          productDetails: products.first,
          applicationUserName: null,
        ),
      );
    } catch (error) {
      // Handle purchase error
      print('Purchase error: $error');
      Fluttertoast.showToast(
        msg: 'Failed to initiate purchase. Please try again.',
        backgroundColor: Colors.red,
      );
    }
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    if (purchaseDetailsList.isEmpty) {
      // Handle the case when the purchaseDetailsList is empty
      print('No purchase details available.');
      return;
    }

    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        // Purchase is pending
        print('Purchase pending:');
        print('Product ID: ${purchaseDetails.productID}');
        print('Transaction ID: ${purchaseDetails.purchaseID}');
        print('Status: ${purchaseDetails.status}');
        print('Verification data: ${purchaseDetails.verificationData}');

        // Handle pending purchase if necessary
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        // Purchase failed
        print('Purchase failed:');
        print('Product ID: ${purchaseDetails.productID}');
        print('Transaction ID: ${purchaseDetails.purchaseID}');
        print('Status: ${purchaseDetails.status}');
        print('Error message: ${purchaseDetails.error}');

        // Show a failure message or perform any other necessary actions
        Fluttertoast.showToast(
          msg: 'Failed to complete purchase. Please try again.',
          backgroundColor: Colors.red,
        );
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        // Purchase was successful or restored
        print('Purchase successful:');
        print('Product ID: ${purchaseDetails.productID}');
        print('Transaction ID: ${purchaseDetails.purchaseID}');
        print('Status: ${purchaseDetails.status}');
        print('Verification data: ${purchaseDetails.verificationData}');

        // Perform any additional actions or update the app's state accordingly
        // Fluttertoast.showToast(
        // msg: 'Pro version purchased. Enjoy all features!',
        // );

        // Acknowledge the purchase
        await InAppPurchase.instance.completePurchase(purchaseDetails);
      } else {
        // Show a failure message if product details are not available
        //  Fluttertoast.showToast(
        //    msg: 'Failed to initiate purchase. Please try again.',
        //   backgroundColor: Colors.red,
        //  );
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _inAppPurchaseManager.dispose();
    super.dispose();
  }

  Future<void> _initializeUserIdAndSubscription() async {
    String? userId = await deviceManager.getUserId();
    if (userId != null) {
      bool isSubscribed = await SubscriptionHelper.getDailyContentSubscription(userId: userId);
      setState(() {
        _userId = userId;
        _isSubscribed = isSubscribed;
      });
    } else {
      //print('Error: User ID not found');
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    Color progressColor = theme.brightness == Brightness.dark ? Colors.white : Colors.black;
    // Add your desired font styles here
    TextStyle menuOptionTextStyle = theme.textTheme.bodyLarge!.copyWith(
        fontFamily: 'Lato', fontSize: 18, fontWeight: FontWeight.normal);
    TextStyle themeModeTextStyle = theme.textTheme.bodyLarge!.copyWith(
        fontFamily: 'Lato', fontSize: 18, fontWeight: FontWeight.normal);

    return Dismissible(
      key: const Key('segment_menu'),
      direction: DismissDirection.down,
      onDismissed: (direction) {
        Navigator.pop(context); // Close the segment menu when swiped down
      },
      child: Container(
        color: theme.scaffoldBackgroundColor,
        child: _isLoading
            ? Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
        )
            : SingleChildScrollView(
          child: Column(
            children: [
              // Label informing users to swipe down to close the segment menu
              const Padding(
                padding: EdgeInsets.only(top: 8.0, bottom: 4.0),
                child: Text(
                  'Swipe down or click outside to close',
                  style: TextStyle(
                    fontFamily: 'Lato',
                    fontSize: 16.0,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.normal,
                    color: Colors.grey,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 8.0),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.grey,
                  size: 24.0,
                ),
              ),
              ListTile(
                title: Text(
                  _isProPurchased
                      ? 'Version'
                      : _upgradeCopy,
                  style: TextStyle(
                    color: theme.brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.normal,
                    // Add any other desired styles for the non-pro text
                  ),
                ),
                trailing: _isProPurchased
                    ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_appName Pro',
                      style: menuOptionTextStyle,
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFFF7CD00),
                    ),
                  ],
                )
                    : Container(
                  height: 40.0,
                  width: 120.0,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        await _upgradeToProVersion(context);
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Center(
                          child: Text(
                            'Upgrade',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFFF7CD00),
                              fontSize: 16,
                              fontFamily: 'Quicksand',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              ListTile(
                title: Text('Theme', style: menuOptionTextStyle),
                trailing: DropdownButton<ThemeMode>(
                  value: widget.currentThemeMode.value,
                  onChanged: (ThemeMode? newValue) {
                    if (newValue != null) {
                      setState(() {
                        widget.onThemeChanged(newValue);
                      });
                    }
                  },
                  items: <ThemeMode>[
                    ThemeMode.light,
                    ThemeMode.dark,
                    ThemeMode.system,
                  ].map<DropdownMenuItem<ThemeMode>>((ThemeMode value) {
                    return DropdownMenuItem<ThemeMode>(
                      value: value,
                      child: Text(
                        value.toString().split('.')[1].capitalize(),
                        style: themeModeTextStyle,
                      ),
                    );
                  }).toList(),
                ),
              ),
              ListTile(
                title: Text('Background theme', style: menuOptionTextStyle),
                trailing: _buildRoundedSlider(
                  widget.backgroundImageEnabled,
                  onToggle: (bool isEnabled) async {
                    widget.onBackgroundImageEnabledChanged(isEnabled);
                    SharedPreferences prefs = await SharedPreferences.getInstance();
                    prefs.setBool('_showOverlayText', isEnabled); // Update the _showOverlayText based on the value of isEnabled
                    prefs.setBool('_backgroundImageEnabled', isEnabled); // Store the value of backgroundImageEnabled
                  },
                ),
              ),
              ListTile(
                title: Text('Enable notification', style: menuOptionTextStyle),
                trailing: _userId == null
                    ? CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(progressColor))
                    : _buildRoundedSlider(
                  ValueNotifier<bool>(_isSubscribed),
                  onToggle: (bool isEnabled) async {
                    await SubscriptionHelper.setDailyContentSubscription(
                      userId: _userId!,
                      isEnabled: isEnabled,
                    );
                    setState(() {
                      _isSubscribed = isEnabled;
                    });
                    Fluttertoast.showToast(
                      msg: isEnabled ? 'Daily notification enabled' : 'Daily notification disabled',
                    );
                  },
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ContactUs(),
                    ),
                  );
                },
                child: ListTile(
                  title: Text('Contact us', style: menuOptionTextStyle),
                ),
              ),
              InkWell(
                onTap: () async {
                  final url = _privacyPolicyUrl;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PrivacyPolicyScreen(url: url),
                    ),
                  );
                },
                child: ListTile(
                  title: Text('Privacy Policy', style: menuOptionTextStyle),
                ),
              ),
              InkWell(
                onTap: () async {
                  final url = _termsOfServiceUrl;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TermsOfServiceScreen(url: url),
                    ),
                  );
                },
                child: ListTile(
                  title: Text('Terms of Use', style: menuOptionTextStyle),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoundedSlider(ValueNotifier<bool> valueNotifier, {Function(bool)? onToggle}) {
    return ValueListenableBuilder<bool>(
      valueListenable: valueNotifier,
      builder: (BuildContext context, bool value, Widget? child) {
        return GestureDetector(
          onTap: () {
            valueNotifier.value = !value;
            if (onToggle != null) {
              onToggle(!value);
            }
          },
          child: Container(
            width: 60.0,
            height: 30.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.0),
              color: value ? Colors.green[600] : Colors.grey[700],
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 150),
              curve: Curves.ease,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 28.0,
                height: 28.0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14.0),
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

