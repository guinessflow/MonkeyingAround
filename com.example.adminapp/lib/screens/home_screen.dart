import 'package:flutter/material.dart';
import '/screens/app_settings_screen.dart';
import '/screens/categories_screen.dart';
import '/screens/authors_screen.dart';
import '/screens/cultures_screen.dart';
import '/screens/content_screen.dart';
import '/screens/backgrounds_screen.dart';
import '/screens/adsettings_screen.dart';
import '/screens/purchases_screen.dart';
import '/screens/users_screen.dart';
import '/screens/user_favorites_screen.dart';
import '/screens/daily_notifications_screen.dart';
import '/screens/send_notification_screen.dart';
import '/screens/promo_notifications_screen.dart';
import '/screens/notifications_settings.dart';
import '/screens/contacts_messages_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final ThemeMode _currentThemeMode = ThemeMode.system;

  List<Widget> get _widgetOptions => <Widget>[
    _cardGrid(),
    CategoriesScreen(backButton: _backToHome),
    CulturesScreen(backButton: _backToHome),
    ContentScreen(backButton: _backToHome),
    BackgroundsScreen(backButton: _backToHome),
    AppSettingsScreen(backButton: _backToHome),
    AdsSettings(backButton: _backToHome),
    PurchasesScreen(backButton: _backToHome),
    UsersScreen(backButton: _backToHome),
    SendNotificationScreen(backButton: _backToHome),
    ContactsMessagesScreen(backButton: _backToHome),
  ];



  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _backToHome() {
    setState(() {
      _selectedIndex = 0;
    });
  }

  Widget _cardGrid() {
    return Center(
      child: GridView.count(
        crossAxisCount: 2,
        childAspectRatio: 1.0,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: <Widget>[
          _createCard('Categories', Icons.category, 1),
          _createCard('Culture', Icons.public, 2),
          _createCard('Content', Icons.format_quote, 3),
          _createCard('Backgrounds', Icons.image, 4),
          _createCard('App Settings', Icons.settings, 5),
          _createCard('Ads Settings', Icons.settings, 6),
          _createCard('Purchases', Icons.shopping_cart, 7),
          _createCard('Users', Icons.people, 8),
          _createCard('Send Promo Notification', Icons.notifications, 9),
          _createCard('Messages', Icons.message, 10),
        ],
      ),
    );
  }

  Widget _createCard(String title, IconData icon, int index) {
    return InkWell(
      onTap: () {
        _onItemTapped(index);
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Colors.blue),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Raleway',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color:Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
    );
  }
}


