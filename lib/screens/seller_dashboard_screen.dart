import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import 'sell_product_screen.dart';
import '../services/seller_service.dart';
import 'seller_register_screen.dart';
import 'edit_profile_screen.dart';
import 'dart:async'; // Added for StreamSubscription

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({Key? key}) : super(key: key);

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  final ProductService _productService = ProductService();
  List<Product> _products = [];
  bool _isLoading = true;
  int _totalSales = 0;
  double _totalRevenue = 0.0;
  int _unreadMessages = 0;
  bool? _isSeller;
  bool _datosCargados = false;
  
  // Listeners para actualizaciones en tiempo real
  StreamSubscription<QuerySnapshot>? _salesListener;
  StreamSubscription<QuerySnapshot>? _productsListener;
  StreamSubscription<QuerySnapshot>? _messagesListener;
  int _previousSalesCount = 0;
  bool _hasNewSale = false;

  @override
  void initState() {
    super.initState();
    _checkSellerStatus();
  }

  Future<void> _checkSellerStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    print('[SellerDashboard] Usuario actual:  [32m${user?.displayName} [0m');
    if (user == null) {
      print('[SellerDashboard] No hay usuario autenticado');
      setState(() => _isSeller = false);
      return;
    }
    print('[SellerDashboard] UID:  [34m${user.uid} [0m');
    try {
      final isSeller = await SellerService().isSeller(user.uid);
      print('[SellerDashboard] ¿Es vendedor?: $isSeller');
      setState(() => _isSeller = isSeller);
    } catch (e) {
      print('[SellerDashboard] Error al consultar vendedor: $e');
      setState(() => _isSeller = false);
    }
  }

  void _setupRealtimeListeners() {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    // Listener para ventas en tiempo real - usar colección de ventas por vendedor
    _salesListener = FirebaseFirestore.instance
        .collection('ventas_vendedores')
        .where('sellerId', isEqualTo: currentUserId)
        .where('fecha', isGreaterThanOrEqualTo: DateTime.now().subtract(const Duration(days: 1)))
        .snapshots()
        .listen((snapshot) {
      final newSalesCount = snapshot.docs.length;
      _totalSales = newSalesCount;
      _totalRevenue = snapshot.docs.fold(0.0, (sum, doc) => 
          sum + (doc.data()['monto'] as num? ?? 0.0).toDouble());
      
      if (mounted) {
        setState(() {});
        // Mostrar notificación solo si hay una nueva venta
        if (newSalesCount > _previousSalesCount && _previousSalesCount > 0) {
          _mostrarNotificacionNuevaVenta();
          setState(() {
            _hasNewSale = true;
          });
          // Resetear el indicador después de 3 segundos
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _hasNewSale = false;
              });
            }
          });
        }
        _previousSalesCount = newSalesCount;
      }
    });

    // Listener para productos en tiempo real
    _productsListener = FirebaseFirestore.instance
        .collection('products')
        .where('sellerId', isEqualTo: currentUserId)
        .snapshots()
        .listen((snapshot) async {
      final products = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Agregar el ID del documento
        return Product.fromJson(data);
      }).toList();
      if (mounted) {
        setState(() {
          _products = products;
        });
      }
    });

    // Listener para mensajes no leídos en tiempo real
    _messagesListener = FirebaseFirestore.instance
        .collection('messages')
        .where('sellerId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _unreadMessages = snapshot.docs.length;
        });
      }
    });
  }

  void _mostrarNotificacionNuevaVenta() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.shopping_cart, color: Colors.white),
            const SizedBox(width: 8),
            const Text('¡Nueva venta realizada!'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
      print('[SellerDashboard] Cargando datos para UID: $currentUserId');
      if (currentUserId == null) {
        print('[SellerDashboard] UID es null');
        setState(() => _isLoading = false);
        return;
      }

      // Configurar listeners en tiempo real
      _setupRealtimeListeners();

      // Cargar productos del vendedor
      final products = await _productService.getProducts();
      _products = products.where((p) => p.sellerId == currentUserId).toList();
      print('[SellerDashboard] Productos cargados:  [32m${_products.length} [0m');

      // Cargar estadísticas de ventas
      try {
        final salesSnapshot = await FirebaseFirestore.instance
            .collection('ventas_vendedores')
            .where('sellerId', isEqualTo: currentUserId)
            .where('fecha', isGreaterThanOrEqualTo: DateTime.now().subtract(const Duration(days: 1)))
            .get();
        _totalSales = salesSnapshot.docs.length;
        _totalRevenue = salesSnapshot.docs.fold(0.0, (sum, doc) => sum + (doc.data()['monto'] as num? ?? 0.0).toDouble());
        print('[SellerDashboard] Ventas cargadas:  [34m$_totalSales [0m');
      } catch (e) {
        print('[SellerDashboard] Error cargando ventas: $e');
        _totalSales = 0;
        _totalRevenue = 0.0;
      }

      // Cargar mensajes no leídos
      try {
        final messagesSnapshot = await FirebaseFirestore.instance
            .collection('messages')
            .where('sellerId', isEqualTo: currentUserId)
            .where('isRead', isEqualTo: false)
            .get();
        _unreadMessages = messagesSnapshot.docs.length;
        print('[SellerDashboard] Mensajes cargados:  [35m$_unreadMessages [0m');
      } catch (e) {
        print('[SellerDashboard] Error cargando mensajes: $e');
        _unreadMessages = 0;
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('[SellerDashboard] Error general en _loadData: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _salesListener?.cancel();
    _productsListener?.cancel();
    _messagesListener?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isSeller == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_isSeller!) {
      return SellerRegisterScreen(
        onRegistered: () {
          _checkSellerStatus();
        },
      );
    }
    if (_isSeller == true && !_datosCargados) {
      _datosCargados = true;
      _loadData();
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Vendedor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Botón para editar perfil de vendedor
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                          );
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Editar perfil de vendedor'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStatsCards(),
                    const SizedBox(height: 24),
                    _buildProductsList(),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SellProductScreen()),
          ).then((_) => _loadData());
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatsCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1,
      children: [
        _buildStatCard(
          'Ventas Hoy',
          _totalSales.toString(),
          Icons.shopping_cart,
          Colors.blue,
          hasNewSale: _hasNewSale,
        ),
        _buildStatCard(
          'Ingresos Hoy',
          '\$${_totalRevenue.toStringAsFixed(2)}',
          Icons.attach_money,
          Colors.green,
        ),
        _buildStatCard(
          'Productos',
          _products.length.toString(),
          Icons.inventory,
          Colors.orange,
        ),
        _buildStatCard(
          'Mensajes',
          _unreadMessages.toString(),
          Icons.message,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {bool hasNewSale = false}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 28, color: color),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    value,
                    key: ValueKey(value), // Esto fuerza la animación cuando cambia el valor
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (hasNewSale)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.fiber_manual_record,
                    size: 8,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mis Productos',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (_products.isEmpty)
          const Center(
            child: Text('No tienes productos publicados'),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _products.length,
            itemBuilder: (context, index) {
              final product = _products[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      product.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported),
                        );
                      },
                    ),
                  ),
                  title: Text(product.name),
                  subtitle: Text(
                    'Stock: ${product.stock} | Precio: \$${product.price.toStringAsFixed(2)}',
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Editar'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Eliminar'),
                      ),
                    ],
                    onSelected: (value) async {
                      if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Confirmar eliminación'),
                            content: const Text('¿Estás seguro de que deseas eliminar este producto?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Eliminar'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          try {
                            await _productService.deleteProduct(product.id);
                            _loadData();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Producto eliminado exitosamente')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error al eliminar el producto: $e')),
                              );
                            }
                          }
                        }
                      }
                    },
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
} 