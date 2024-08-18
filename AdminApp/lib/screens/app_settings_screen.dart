import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppSettingsScreen extends StatefulWidget {
  final VoidCallback backButton;

  const AppSettingsScreen({super.key, required this.backButton});

  @override
  _AppSettingsScreenState createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  final TextEditingController _apiUrlController = TextEditingController();
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _appNameController = TextEditingController();
  final TextEditingController _privacyPolicyController = TextEditingController();
  final TextEditingController _termsOfServiceController = TextEditingController();
  final TextEditingController _productIdController = TextEditingController();
  final TextEditingController _thankyouCopyController = TextEditingController();
  final TextEditingController _upgradeCopyController = TextEditingController();
  final TextEditingController _fontSizeController = TextEditingController();
  String _selectedFontFamily = 'Roboto'; // Default font family
  final List<String> _fontFamilies = [
    'DancingScript',
    'Roboto',
    'Roobert',
    'Lora',
    'Merriweather',
    'PlayfairDisplay',
    'LibreBaskerville',
    'CormorantGaramond',
    'Lato',
    'OpenSans',
    'Raleway',
    'Montserrat',
    'NotoSerif',
    'Pacifico',
    'Quicksand',
    'LeagueSpartan',
  ];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Fetch existing app settings from Firestore
    _fetchAppSettings();
    _fetchFCMCredentials();
  }

  void _fetchAppSettings() {
    FirebaseFirestore.instance
        .collection('app')
        .doc('appSettings')
        .get()
        .then((DocumentSnapshot<Map<String, dynamic>> snapshot) {
      if (snapshot.exists) {
        setState(() {
          _appNameController.text = snapshot.data()!['appName'] ?? '';
          _privacyPolicyController.text = snapshot.data()!['privacyPolicyUrl'] ?? '';
          _termsOfServiceController.text = snapshot.data()!['termsOfServiceUrl'] ?? '';
          _selectedFontFamily = snapshot.data()!['fontFamily'] ?? 'Roboto';
          _productIdController.text = snapshot.data()!['productId'] ?? '';
          _thankyouCopyController.text = snapshot.data()!['thankyouCopy'] ?? '';
          _upgradeCopyController.text = snapshot.data()!['upgradeCopy'] ?? '';
          _fontSizeController.text = snapshot.data()!['fontSize']?.toString() ?? '';
          _isLoading = false; // Set loading state to false when data is loaded
        });
      }
    }).catchError((error) {
      print("Failed to fetch app settings: $error");
      setState(() {
        _isLoading = false; // Set loading state to false on error
      });
    });
  }

  void _updateAppSettings() {
    String appName = _appNameController.text;
    String privacyPolicyUrl = _privacyPolicyController.text;
    String termsOfServiceUrl = _termsOfServiceController.text;
    String selectedFontFamily = _selectedFontFamily;
    String productId = _productIdController.text;
    String thankyouCopy = _thankyouCopyController.text;
    String upgradeCopy = _upgradeCopyController.text;
    double fontSize = double.tryParse(_fontSizeController.text) ?? 18.0;

    // Update the app settings in Firestore
    FirebaseFirestore.instance
        .collection('app')
        .doc('appSettings')
        .set({
      'appName': appName,
      'privacyPolicyUrl': privacyPolicyUrl,
      'termsOfServiceUrl': termsOfServiceUrl,
      'fontFamily': selectedFontFamily,
      'productId': productId,
      'thankyouCopy': thankyouCopy,
      'upgradeCopy': upgradeCopy,
      'fontSize': fontSize,
    })
        .then((value) {
      // Show success message or perform any other actions
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Success'),
            content: const Text('App settings updated successfully.'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    })
        .catchError((error) {
      print("Failed to update app settings: $error");
    });
  }

  void _fetchFCMCredentials() {
    FirebaseFirestore.instance
        .collection('fcm_credentials')
        .doc('serverkey')
        .get()
        .then((DocumentSnapshot<Map<String, dynamic>> snapshot) {
      if (snapshot.exists) {
        setState(() {
          _apiUrlController.text = snapshot.data()!['apiUrl'] ?? '';
          _keyController.text = snapshot.data()!['key'] ?? '';
        });
      }
    }).catchError((error) {
      print("Failed to fetch FCM credentials: $error");
    });
  }

  void _updateFCMCredentials() {
    String apiUrl = _apiUrlController.text;
    String key = _keyController.text;

    // Update the FCM credentials in Firestore
    FirebaseFirestore.instance
        .collection('fcm_credentials')
        .doc('serverkey')
        .set({
      'apiUrl': apiUrl,
      'key': key,
    })
        .then((value) {
      // Show success message or perform any other actions
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Success'),
            content: const Text('FCM credentials updated successfully.'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    })
        .catchError((error) {
      print("Failed to update FCM credentials: $error");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            widget.backButton();
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField('App Name:', _appNameController),
              const SizedBox(height: 16),
              _buildTextField('Font Size for App Name (Eg: 18):', _fontSizeController),
              const SizedBox(height: 16),
              _buildDropdown('Select Font Family for App Name:', _selectedFontFamily, _fontFamilies),
              const SizedBox(height: 16),
              _buildTextField('In-app Purchase Product ID:', _productIdController),
              const SizedBox(height: 16),
              _buildMultiLineTextField('Purchase Thank You Copy:', _thankyouCopyController),
              const SizedBox(height: 16),
              _buildMultiLineTextField('Purchase Upgrade Copy:', _upgradeCopyController),
              const SizedBox(height: 16),
              _buildTextField('Privacy Policy URL:', _privacyPolicyController),
              const SizedBox(height: 16),
              _buildTextField('Terms of Service URL:', _termsOfServiceController),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: _updateAppSettings,
                  child: const Text('Save'),
                ),
              ),
              // FCM Credentials Section
              const SizedBox(height: 16),
              _buildTextField('FCM API URL:', _apiUrlController),
              const SizedBox(height: 16),
              _buildMultiLineTextField('FCM Server Key:', _keyController),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: _updateFCMCredentials,
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: 'Enter $label',
          ),
        ),
      ],
    );
  }

  Widget _buildMultiLineTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: null, // Allows for multiline input
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: 'Enter $label',
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String selectedValue, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 16),
        DropdownButton<String>(
          value: selectedValue,
          onChanged: (String? value) {
            setState(() {
              _selectedFontFamily = value!;
            });
          },
          items: items.map((String fontFamily) {
            return DropdownMenuItem<String>(
              value: fontFamily,
              child: Text(fontFamily),
            );
          }).toList(),
        ),
      ],
    );
  }
}

