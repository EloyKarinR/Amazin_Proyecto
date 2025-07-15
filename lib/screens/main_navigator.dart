import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'cart_screen.dart';
import 'seller_dashboard_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _selectedIndex = 0;
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = <Widget>[
      const HomeScreen(),
      if (_currentUserId != null) const SellerDashboardScreen(),
      const ProfileScreen(),
      const CartScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.home, 0),
            label: 'Inicio',
          ),
          if (_currentUserId != null)
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.store, _currentUserId != null ? 1 : -1),
              label: 'Vender',
            ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.person, _currentUserId != null ? 2 : 1),
            label: 'Perfil',
          ),
          BottomNavigationBarItem(
            icon: _buildNavIcon(Icons.shopping_cart, _currentUserId != null ? 3 : 2),
            label: 'Carrito',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.orange,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, int index) {
    final bool isActive = _selectedIndex == index;
    return isActive
        ? Container(
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: Colors.orange, size: 28),
          )
        : Icon(icon, color: Colors.orange, size: 24);
  }
} 