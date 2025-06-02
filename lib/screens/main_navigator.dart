import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'cart_screen.dart';

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _selectedIndex = 0;

  static final List<Widget> _screens = <Widget>[
    const HomeScreen(), // Pantalla de Inicio
    const ProfileScreen(), // Pantalla de Perfil
    const CartScreen(), // Pantalla del Carrito
  ];

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
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home), // Icono de Casita
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person), // Icono de Perfil
            label: 'Perfil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart), // Icono de Carrito
            label: 'Carrito',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.orange, // Color de ítem seleccionado
        onTap: _onItemTapped,
      ),
    );
  }
} 