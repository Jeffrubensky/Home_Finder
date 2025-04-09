import 'package:flutter/material.dart';
import 'search_screen.dart';
//import 'home_screen.dart';
import 'profile_screen.dart';
import 'home_screenclient.dart';

class HomePageClient extends StatefulWidget {
  const HomePageClient({super.key});

  @override
  HomePageClientState createState() => HomePageClientState();
}

class HomePageClientState extends State<HomePageClient> {
  int _selectedIndex = 0;

  /// Fonction pour obtenir la page sélectionnée dynamiquement
  Widget _getSelectedPage(int index) {
    switch (index) {
      case 0:
        return HomeScreenClient();
      case 1:
        return SearchScreen();
      case 2:
        return ProfileScreen();
      default:
        return HomeScreenClient();
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getSelectedPage(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}