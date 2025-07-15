import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../models/product.dart';
import 'edit_profile_screen.dart';
import 'address_list_screen.dart';
import 'historial_compras_screen.dart';
import 'notificaciones_screen.dart';
import '../services/notificacion_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_detail_screen.dart';
import 'payment_methods_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notificacionService = NotificacionService();
    final fbUser = fb_auth.FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          if (fbUser != null)
            StreamBuilder<List<dynamic>>(
              stream: notificacionService
                  .getNotificacionesUsuario(fbUser.uid)
                  .map((notis) => notis.where((n) => !n.leida).toList()),
              builder: (context, snapshot) {
                final noLeidas = snapshot.data?.length ?? 0;
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => NotificacionesScreen()),
                        );
                      },
                    ),
                    if (noLeidas > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            '$noLeidas',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
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
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HistorialComprasScreen()),
            );
          },
        ),
        _buildMenuItem(
          icon: Icons.favorite,
          title: 'Favoritos',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FavoritosScreen()),
            );
          },
        ),
        _buildMenuItem(
          icon: Icons.location_on,
          title: 'Direcciones',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddressListScreen()),
            );
          },
        ),
        _buildMenuItem(
          icon: Icons.payment,
          title: 'Métodos de Pago',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PaymentMethodsScreen()),
            );
          },
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

class FavoritosScreen extends StatefulWidget {
  const FavoritosScreen({Key? key}) : super(key: key);

  @override
  State<FavoritosScreen> createState() => _FavoritosScreenState();
}

class _FavoritosScreenState extends State<FavoritosScreen> {
  Set<String> _removing = {};

  Future<void> _quitarFavorito(String productId) async {
    final user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() { _removing.add(productId); });
    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .collection('favoritos')
        .doc(productId)
        .delete();
    setState(() { _removing.remove(productId); });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto eliminado de favoritos')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Favoritos')),
        body: const Center(child: Text('Debes iniciar sesión para ver tus favoritos.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .collection('favoritos')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No tienes productos favoritos.'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final fav = docs[index].data();
              final productId = fav['productId'];
              return FutureBuilder(
                future: FirebaseFirestore.instance.collection('products').doc(productId).get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const SizedBox.shrink();
                  }
                  final data = snapshot.data!.data()!;
                  return AnimatedOpacity(
                    opacity: _removing.contains(productId) ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 400),
                    child: Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: data['imageUrl'] != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(data['imageUrl'], width: 50, height: 50, fit: BoxFit.cover),
                              )
                            : const Icon(Icons.image, size: 40),
                        title: Text(data['name'] ?? ''),
                        subtitle: Text('\$${(data['price'] as num).toStringAsFixed(2)}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.favorite, color: Colors.red),
                          onPressed: () => _quitarFavorito(productId),
                          tooltip: 'Quitar de favoritos',
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailScreen(
                                product: Product.fromJson({...data, 'id': productId}),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
} 