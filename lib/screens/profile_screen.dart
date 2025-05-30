import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            _buildMenuItems(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.orange.shade50,
      child: Column(
        children: [
          const CircleAvatar(
            radius: 50,
            child: Icon(Icons.person, size: 50),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nombre del Usuario',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'usuario@email.com',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {},
            child: const Text('Editar Perfil'),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems() {
    return Column(
      children: [
        _buildMenuItem(
          icon: Icons.shopping_bag,
          title: 'Mis Pedidos',
          onTap: () {},
        ),
        _buildMenuItem(
          icon: Icons.favorite,
          title: 'Favoritos',
          onTap: () {},
        ),
        _buildMenuItem(
          icon: Icons.location_on,
          title: 'Direcciones',
          onTap: () {},
        ),
        _buildMenuItem(
          icon: Icons.payment,
          title: 'Métodos de Pago',
          onTap: () {},
        ),
        _buildMenuItem(
          icon: Icons.settings,
          title: 'Configuración',
          onTap: () {},
        ),
        _buildMenuItem(
          icon: Icons.help,
          title: 'Ayuda y Soporte',
          onTap: () {},
        ),
        _buildMenuItem(
          icon: Icons.logout,
          title: 'Cerrar Sesión',
          onTap: () {},
          textColor: Colors.red,
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor),
      title: Text(
        title,
        style: TextStyle(color: textColor),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
} 