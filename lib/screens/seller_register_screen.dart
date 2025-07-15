import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/seller.dart';
import '../services/seller_service.dart';
import '../widgets/ubicacion_selector.dart';

class SellerRegisterScreen extends StatefulWidget {
  final VoidCallback? onRegistered;
  const SellerRegisterScreen({Key? key, this.onRegistered}) : super(key: key);

  @override
  State<SellerRegisterScreen> createState() => _SellerRegisterScreenState();
}

class _SellerRegisterScreenState extends State<SellerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _nombreTiendaController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _redSocialController = TextEditingController();
  final _ciudadController = TextEditingController();
  bool _isLoading = false;
  double? _latitud;
  double? _longitud;

  @override
  void dispose() {
    _telefonoController.dispose();
    _direccionController.dispose();
    _nombreTiendaController.dispose();
    _descripcionController.dispose();
    _redSocialController.dispose();
    _ciudadController.dispose();
    super.dispose();
  }

  Future<void> _registrarVendedor() async {
    if (!_formKey.currentState!.validate()) return;
    if (_latitud == null || _longitud == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona tu ubicación en el mapa.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final seller = Seller(
      uid: user.uid,
      nombre: user.displayName ?? '',
      fotoUrl: user.photoURL ?? '',
      telefono: _telefonoController.text.trim(),
      direccion: _direccionController.text.trim().isEmpty ? null : _direccionController.text.trim(),
      nombreTienda: _nombreTiendaController.text.trim().isEmpty ? null : _nombreTiendaController.text.trim(),
      descripcion: _descripcionController.text.trim().isEmpty ? null : _descripcionController.text.trim(),
      redSocial: _redSocialController.text.trim().isEmpty ? null : _redSocialController.text.trim(),
      ciudad: _ciudadController.text.trim().isEmpty ? null : _ciudadController.text.trim(),
      fechaRegistro: Timestamp.now(),
      latitud: _latitud,
      longitud: _longitud,
    );
    await SellerService().createSeller(seller);
    setState(() => _isLoading = false);
    if (widget.onRegistered != null) widget.onRegistered!();
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Vendedor'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (user != null) ...[
                CircleAvatar(
                  backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                  radius: 40,
                  child: user.photoURL == null ? const Icon(Icons.person, size: 40) : null,
                ),
                const SizedBox(height: 8),
                Center(child: Text(user.displayName ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _telefonoController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Teléfono *'),
                validator: (value) => value == null || value.trim().isEmpty ? 'El teléfono es obligatorio' : null,
              ),
              TextFormField(
                controller: _direccionController,
                decoration: const InputDecoration(labelText: 'Dirección (opcional)'),
              ),
              TextFormField(
                controller: _nombreTiendaController,
                decoration: const InputDecoration(labelText: 'Nombre de la tienda (opcional)'),
              ),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(labelText: 'Descripción corta (opcional)'),
                maxLines: 2,
              ),
              TextFormField(
                controller: _redSocialController,
                decoration: const InputDecoration(labelText: 'Red social o WhatsApp (opcional)'),
              ),
              TextFormField(
                controller: _ciudadController,
                decoration: const InputDecoration(labelText: 'Ciudad o región (opcional)'),
              ),
              const SizedBox(height: 16),
              UbicacionSelector(
                onUbicacionSeleccionada: (lat, lng) {
                  setState(() {
                    _latitud = lat;
                    _longitud = lng;
                  });
                },
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _registrarVendedor,
                      child: const Text('Registrarme como vendedor'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
} 