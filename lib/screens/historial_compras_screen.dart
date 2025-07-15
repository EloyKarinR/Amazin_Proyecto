import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/compra.dart';
import '../services/compra_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/notificacion.dart';
import '../services/notificacion_service.dart';
import 'cart_screen.dart';

class HistorialComprasScreen extends StatefulWidget {
  const HistorialComprasScreen({Key? key}) : super(key: key);

  @override
  State<HistorialComprasScreen> createState() => _HistorialComprasScreenState();
}

class _HistorialComprasScreenState extends State<HistorialComprasScreen> 
    with TickerProviderStateMixin {
  final CompraService _compraService = CompraService();
  final NotificacionService _notificacionService = NotificacionService();
  StreamSubscription<List<Compra>>? _comprasSub;
  List<Compra> _compras = [];
  final List<String> _estados = [
    'pendiente',
    'procesando',
    'enviado',
    'en camino',
    'entregado',
  ];
  final List<String> _abreviaturas = [
    'Pend.',
    'Proc.',
    'Env.',
    'Camino',
    'Entreg.',
  ];
  final Map<String, Timer> _timers = {};
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final Set<String> _notificados = {};
  final Set<String> _animacionesMostradas = {};
  
  // Variables para la animación
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _mostrandoAnimacion = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initNotifications();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _comprasSub = _compraService.getComprasUsuario(user.uid).listen((compras) {
        setState(() {
          _compras = compras;
        });
        for (final compra in compras) {
          _iniciarCambioAutomaticoEstado(user.uid, compra);
        }
        _verificarEntregadosParaNotificar(compras);
      });
    }
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
    ));
  }

  Future<void> _mostrarAnimacionEntregado() async {
    if (_mostrandoAnimacion) return;
    
    setState(() {
      _mostrandoAnimacion = true;
    });
    
    _animationController.forward();
    
    // Esperar a que termine la animación
    await Future.delayed(const Duration(milliseconds: 2500));
    
    // Navegar al carrito
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CartScreen()),
      );
    }
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('amazingo');
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _mostrarNotificacion(Compra compra) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'entregados_channel',
      'Pedidos Entregados',
      channelDescription: 'Notificaciones de pedidos entregados',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await _flutterLocalNotificationsPlugin.show(
      compra.id.hashCode,
      '¡Tu pedido ha sido entregado!',
      'Ya puedes dejar tu opinión sobre el producto que compraste.',
      platformChannelSpecifics,
    );
  }

  void _verificarEntregadosParaNotificar(List<Compra> compras) {
    for (final compra in compras) {
      if (compra.estado == 'entregado' && !_notificados.contains(compra.id)) {
        _mostrarNotificacion(compra);
        _guardarNotificacionFirestore(compra);
        _notificados.add(compra.id);
        
        // NO mostrar animación aquí - solo se mostrará cuando el estado cambie dinámicamente
        // La animación se mostrará en _iniciarCambioAutomaticoEstado cuando cambie de "en camino" a "entregado"
      }
    }
  }

  Future<void> _guardarNotificacionFirestore(Compra compra) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final notificacion = Notificacion(
      id: '',
      idUsuario: user.uid,
      titulo: '¡Tu pedido ha sido entregado!',
      mensaje: 'Ya puedes dejar tu opinión sobre el producto que compraste.',
      leida: false,
      fecha: DateTime.now(),
      idCompra: compra.id,
      idProducto: compra.idProducto,
    );
    await _notificacionService.crearNotificacion(notificacion);
  }

  void _iniciarCambioAutomaticoEstado(String idUsuario, Compra compra) {
    if (compra.estado == 'entregado' || _timers.containsKey(compra.id)) return;
    final idx = _estados.indexOf(compra.estado);
    if (idx == -1 || idx == _estados.length - 1) return;
    _timers[compra.id] = Timer(Duration(seconds: 10), () async {
      final nuevoEstado = _estados[idx + 1];
      await _compraService.actualizarEstadoCompra(idUsuario, compra.id, nuevoEstado);
      _timers.remove(compra.id);
      
      // Verificar si el cambio es de "en camino" a "entregado" para mostrar animación
      if (compra.estado == 'en camino' && nuevoEstado == 'entregado') {
        if (!_animacionesMostradas.contains(compra.id)) {
          _mostrarAnimacionEntregado();
          _animacionesMostradas.add(compra.id);
        }
      }
      
      final nuevaCompra = Compra(
        id: compra.id,
        idProducto: compra.idProducto,
        idUsuario: compra.idUsuario,
        fechaCompra: compra.fechaCompra,
        estado: nuevoEstado,
        cantidad: compra.cantidad,
        precio: compra.precio,
        imageUrl: compra.imageUrl,
      );
      _iniciarCambioAutomaticoEstado(idUsuario, nuevaCompra);
    });
  }

  Future<void> _cancelarPedido(Compra compra) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar pedido'),
        content: const Text('¿Estás seguro de que deseas cancelar este pedido? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (confirmado == true) {
      await _compraService.eliminarCompra(user.uid, compra.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido cancelado y eliminado.')),
      );
    }
  }

  Future<void> _limpiarHistorial() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar historial'),
        content: const Text('¿Estás seguro de que deseas eliminar todo tu historial de compras? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, eliminar todo'),
          ),
        ],
      ),
    );
    if (confirmado == true) {
      await _compraService.limpiarHistorialCompras(user.uid);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Historial de compras eliminado.')),
      );
    }
  }

  bool _verTodo = false;

  @override
  void dispose() {
    _comprasSub?.cancel();
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildTimeline(String estadoActual) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(_estados.length, (i) {
        final idxActual = _estados.indexOf(estadoActual);
        final isActive = i <= idxActual;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              children: [
                Icon(
                  isActive ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isActive ? Colors.green : Colors.grey,
                  size: 22,
                ),
                const SizedBox(height: 4),
                Text(
                  _abreviaturas[i],
                  style: TextStyle(
                    fontSize: 11,
                    color: isActive ? Colors.green : Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                  softWrap: true,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de Compras')),
      body: Stack(
        children: [
          _compras.isEmpty
              ? const Center(child: Text('No tienes compras registradas.'))
              : Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: _limpiarHistorial,
                          icon: const Icon(Icons.delete, color: Colors.red),
                          label: const Text('Limpiar historial', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                    Expanded(
                      child: ListView.separated(
                        itemCount: _verTodo ? _compras.length : (_compras.length > 5 ? 5 : _compras.length),
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, i) {
                          final compra = _compras[i];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      compra.imageUrl,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        width: 60,
                                        height: 60,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.image_not_supported, color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Producto: ${compra.idProducto}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 8),
                                        Text('Cantidad: ${compra.cantidad}'),
                                        Text('Precio: S/ ${compra.precio.toStringAsFixed(2)}'),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Estado actual: ${compra.estado[0].toUpperCase() + compra.estado.substring(1)}',
                                          style: TextStyle(
                                            color: compra.estado == 'entregado' ? Colors.green : Colors.orange,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildTimeline(compra.estado),
                                        const SizedBox(height: 8),
                                        Text('Fecha de compra: ${compra.fechaCompra.day.toString().padLeft(2, '0')}/${compra.fechaCompra.month.toString().padLeft(2, '0')}/${compra.fechaCompra.year}'),
                                        if (compra.estado != 'entregado')
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: TextButton.icon(
                                              onPressed: () => _cancelarPedido(compra),
                                              icon: const Icon(Icons.cancel, color: Colors.red),
                                              label: const Text('Cancelar pedido', style: TextStyle(color: Colors.red)),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (_compras.length > 5)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _verTodo = !_verTodo;
                          });
                        },
                        child: Text(_verTodo ? 'Ver menos' : 'Ver todo el historial'),
                      ),
                  ],
                ),
          // Animación de éxito
          if (_mostrandoAnimacion)
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Container(
                  color: Colors.black.withOpacity(0.7 * _fadeAnimation.value),
                  child: Center(
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check_circle,
                                size: 80,
                                color: Colors.green.shade600,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              '¡Pedido Entregado!',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Tu pedido ha sido entregado exitosamente.\n¡Gracias por tu compra!',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Redirigiendo al carrito...',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
} 