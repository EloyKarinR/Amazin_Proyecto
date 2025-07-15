import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notificacion.dart';
import '../services/notificacion_service.dart';
import 'product_detail_screen.dart';
import '../services/product_service.dart';

class NotificacionesScreen extends StatelessWidget {
  final NotificacionService _notificacionService = NotificacionService();

  NotificacionesScreen({Key? key}) : super(key: key);

  void _onTapNotificacion(BuildContext context, Notificacion noti) async {
    // Cargar el producto real antes de navegar
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final productService = ProductService();
    final product = await productService.getProductById(noti.idProducto);
    Navigator.pop(context); // Cerrar loader
    if (product != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailScreen(product: product),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo cargar el producto.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Debes iniciar sesión para ver notificaciones.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones')),
      body: StreamBuilder<List<Notificacion>>(
        stream: _notificacionService.getNotificacionesUsuario(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final notificaciones = snapshot.data ?? [];
          if (notificaciones.isEmpty) {
            return const Center(child: Text('No tienes notificaciones.'));
          }
          return ListView.separated(
            itemCount: notificaciones.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, i) {
              final noti = notificaciones[i];
              return ListTile(
                leading: Icon(
                  noti.leida ? Icons.notifications : Icons.notifications_active,
                  color: noti.leida ? Colors.grey : Colors.blue,
                ),
                title: Text(noti.titulo, style: TextStyle(fontWeight: noti.leida ? FontWeight.normal : FontWeight.bold)),
                subtitle: Text(noti.mensaje),
                trailing: noti.leida ? null : const Icon(Icons.fiber_new, color: Colors.red),
                onTap: () async {
                  await _notificacionService.marcarComoLeida(user.uid, noti.id);
                  _onTapNotificacion(context, noti);
                },
              );
            },
          );
        },
      ),
    );
  }
} 