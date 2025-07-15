import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../models/comentario.dart';
import '../services/comentario_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/product_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/seller.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'payment_screen.dart';
import '../services/compra_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({
    Key? key,
    required this.product,
  }) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ComentarioService _comentarioService = ComentarioService();
  final ProductService _productService = ProductService();
  final CompraService _compraService = CompraService();
  bool _mostrarFormulario = false;
  int _calificacion = 5;
  final TextEditingController _comentarioController = TextEditingController();
  bool _enviando = false;
  bool _puedeComentar = false;
  bool _verificandoCompra = true;
  Seller? _seller;
  bool _cargandoSeller = true;

  @override
  void initState() {
    super.initState();
    _verificarPermisoComentar();
    _cargarSeller();
  }

  Future<void> _verificarPermisoComentar() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _puedeComentar = false;
        _verificandoCompra = false;
      });
      return;
    }
    final puede = await _compraService.usuarioHaCompradoProducto(user.uid, widget.product.id);
    setState(() {
      _puedeComentar = puede;
      _verificandoCompra = false;
    });
  }

  Future<void> _cargarSeller() async {
    final doc = await FirebaseFirestore.instance.collection('sellers').doc(widget.product.sellerId).get();
    if (doc.exists) {
      setState(() {
        _seller = Seller.fromMap(doc.data()!);
        _cargandoSeller = false;
      }
      );
    } else {
      setState(() {
        _seller = null;
        _cargandoSeller = false;
      });
    }
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  Future<void> _agregarComentario() async {
    setState(() { _enviando = true; });
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para comentar.')),
      );
      setState(() { _enviando = false; });
      return;
    }
    final comentario = Comentario(
      id: '',
      idUsuario: user.uid,
      nombreUsuario: user.displayName ?? 'Usuario',
      calificacion: _calificacion,
      comentario: _comentarioController.text.trim(),
      fecha: DateTime.now(),
      compraVerificada: false, // Lógica futura
    );
    await _comentarioService.agregarComentario(widget.product.id, comentario);
    setState(() {
      _mostrarFormulario = false;
      _comentarioController.clear();
      _calificacion = 5;
      _enviando = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('¡Comentario agregado!')),
    );
  }

  Future<bool> _esFavorito(String productId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .collection('favoritos')
        .doc(productId)
        .get();
    return doc.exists;
  }

  Future<void> _toggleFavorito(String productId, bool esFavorito) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final ref = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .collection('favoritos')
        .doc(productId);
    if (esFavorito) {
      await ref.delete();
    } else {
      await ref.set({'productId': productId, 'fecha': DateTime.now()});
    }
  }

  Widget _buildComentarios() {
    return StreamBuilder<List<Comentario>>(
      stream: _comentarioService.getComentarios(widget.product.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final comentarios = snapshot.data ?? [];
        if (comentarios.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('Aún no hay comentarios para este producto.'),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: comentarios.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, i) {
            final c = comentarios[i];
            return ListTile(
              leading: Icon(Icons.account_circle, size: 36, color: Colors.grey[600]),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      c.nombreUsuario,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ...List.generate(5, (idx) => Icon(
                    idx < c.calificacion ? Icons.star : Icons.star_border,
                    color: Colors.amber[700], size: 18,
                  )),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.comentario),
                  Text(
                    '${c.fecha.day.toString().padLeft(2, '0')}/${c.fecha.month.toString().padLeft(2, '0')}/${c.fecha.year}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFormulario() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tu reseña', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (i) => IconButton(
                icon: Icon(
                  i < _calificacion ? Icons.star : Icons.star_border,
                  color: Colors.amber[700],
                ),
                onPressed: () {
                  setState(() { _calificacion = i + 1; });
                },
              )),
            ),
            TextField(
              controller: _comentarioController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Escribe tu comentario',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _enviando ? null : _agregarComentario,
                  child: _enviando
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Enviar'),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: _enviando ? null : () {
                    setState(() { _mostrarFormulario = false; });
                  },
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Product?>(
      stream: _productService.streamProductById(widget.product.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final product = snapshot.data!;
        return Scaffold(
          appBar: AppBar(
            title: Text(product.name),
            actions: [
              FutureBuilder<bool>(
                future: _esFavorito(product.id),
                builder: (context, snapshot) {
                  final esFavorito = snapshot.data ?? false;
                  return IconButton(
                    icon: Icon(
                      esFavorito ? Icons.favorite : Icons.favorite_border,
                      color: esFavorito ? Colors.red : Colors.grey,
                    ),
                    onPressed: () async {
                      await _toggleFavorito(product.id, esFavorito);
                      setState(() {}); // Para refrescar el estado
                    },
                    tooltip: esFavorito ? 'Quitar de favoritos' : 'Agregar a favoritos',
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.pushNamed(context, '/cart');
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Image.network(
                product.imageUrl,
                height: 300,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 300,
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.image_not_supported,
                      size: 100,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Stock
                    Builder(
                      builder: (context) {
                        final stock = product.stock;
                        Color color;
                        String texto;
                        if (stock == 0) {
                          color = Colors.red;
                          texto = 'Agotado';
                        } else if (stock <= 5) {
                          color = Colors.orange;
                          texto = '¡Últimas unidades! ($stock disponibles)';
                        } else {
                          color = Colors.blueGrey;
                          texto = 'En stock: $stock';
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 8),
                          child: Text(
                            texto,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    // Calificación y número de reseñas en tiempo real
                    StreamBuilder<List<Comentario>>(
                      stream: _comentarioService.getComentarios(product.id),
                      builder: (context, snapshot) {
                        final comentarios = snapshot.data ?? [];
                        double promedio = 0;
                        if (comentarios.isNotEmpty) {
                          promedio = comentarios.map((c) => c.calificacion).reduce((a, b) => a + b) / comentarios.length;
                        }
                        return Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber[700]),
                            const SizedBox(width: 4),
                            Text(
                              promedio.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(${comentarios.length} reseñas)',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Descripción',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.description,
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    // Características técnicas
                    if (product.caracteristicas.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Características técnicas',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: product.caracteristicas.entries.map((e) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      e.key,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 3,
                                    child: Text(e.value),
                                  ),
                                ],
                              ),
                            )).toList(),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    // Sección de comentarios
                    const Divider(),
                    const Text(
                      'Reseñas y comentarios',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildComentarios(),
                    const SizedBox(height: 8),
                    if (_verificandoCompra)
                      const Center(child: CircularProgressIndicator())
                    else if (_mostrarFormulario)
                      _buildFormulario()
                    else if (_puedeComentar)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() { _mostrarFormulario = true; });
                          },
                          icon: const Icon(Icons.rate_review),
                          label: const Text('Escribir reseña'),
                        ),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Solo puedes dejar una reseña si has comprado y recibido este producto.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: product.stock == 0 ? null : () {
                              final cartProvider = Provider.of<CartProvider>(context, listen: false);
                              cartProvider.addItem(product, 1);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${product.name} agregado al carrito'),
                                  backgroundColor: Colors.green,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
                            label: const Text('Agregar al Carrito', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              elevation: 4,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: product.stock == 0 ? null : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PaymentScreen(
                                    product: product,
                                    quantity: 1,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.payment, color: Colors.white),
                            label: const Text('Comprar Ahora', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              elevation: 4,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_cargandoSeller)
                      const Center(child: CircularProgressIndicator()),
                    if (!_cargandoSeller && _seller != null && _seller!.latitud != null && _seller!.longitud != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          const Text('Ubicación del vendedor', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 200,
                            child: GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: LatLng(_seller!.latitud!, _seller!.longitud!),
                                zoom: 15,
                              ),
                              markers: {
                                Marker(
                                  markerId: const MarkerId('vendedor'),
                                  position: LatLng(_seller!.latitud!, _seller!.longitud!),
                                  infoWindow: InfoWindow(title: _seller!.nombreTienda ?? 'Vendedor'),
                                ),
                              },
                              myLocationButtonEnabled: false,
                              zoomControlsEnabled: false,
                            ),
                          ),
                          if (_seller!.direccion != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text('Dirección: ${_seller!.direccion!}'),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 