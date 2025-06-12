import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          final user = auth.user;
          return SingleChildScrollView(
            child: Column(
              children: [
                _buildProfileHeader(context, user),
                _buildMenuItems(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, User? user) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.orange.shade50,
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: user?.photoUrl != null
                ? NetworkImage(user!.photoUrl!)
                : null,
            child: user?.photoUrl == null
                ? const Icon(Icons.person, size: 50)
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            user?.name ?? 'Usuario',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user?.email ?? 'usuario@email.com',
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
            },
            child: const Text('Editar Perfil'),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems(BuildContext context) {
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
          onTap: () {
            Provider.of<AuthProvider>(context, listen: false).logout();
          },
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