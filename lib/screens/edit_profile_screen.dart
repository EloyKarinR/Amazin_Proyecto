import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/ubicacion_selector.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  double? _latitud;
  double? _longitud;
  bool _guardandoUbicacion = false;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _nameController = TextEditingController(text: authProvider.user?.name ?? '');
    _emailController = TextEditingController(text: authProvider.user?.email ?? '');
    _cargarUbicacionVendedor();
  }

  Future<void> _cargarUbicacionVendedor() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('sellers').doc(user.id).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _latitud = (data['latitud'] as num?)?.toDouble();
        _longitud = (data['longitud'] as num?)?.toDouble();
      });
    }
  }

  Future<void> _guardarUbicacion() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null || _latitud == null || _longitud == null) return;
    setState(() => _guardandoUbicacion = true);
    await FirebaseFirestore.instance.collection('sellers').doc(user.id).update({
      'latitud': _latitud,
      'longitud': _longitud,
    });
    setState(() => _guardandoUbicacion = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ubicación actualizada con éxito!')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final newName = _nameController.text.trim();
    final messenger = ScaffoldMessenger.of(context); // Obtener messenger antes del async gap

    if (newName.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('El nombre no puede estar vacío.')),
      );
      return;
    }

    if (authProvider.user?.name != newName) {
      try {
        await authProvider.updateUserName(newName); // Operación asíncrona
        if (!mounted) return; // Verificar si el widget sigue montado
        messenger.showSnackBar(
          const SnackBar(content: Text('Perfil actualizado con éxito!')),
        );
        if (mounted) {
          Navigator.pop(context); // Verificar montado antes de usar context
        }
      } catch (e) {
        if (!mounted) return; // Verificar montado antes de usar context
        messenger.showSnackBar(
          SnackBar(content: Text('Error al actualizar el perfil: ${e.toString()}')),
        );
      }
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('El nombre es el mismo. No se realizaron cambios.')),
      );
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final messenger = ScaffoldMessenger.of(context); // Obtener messenger antes del async gap
      try {
        await authProvider.updateProfilePhoto(image);
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('Foto de perfil actualizada con éxito!')),
        );
      } catch (e) {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text('Error al actualizar la foto: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
      ),
      body: authProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundImage: user?.photoUrl != null
                            ? NetworkImage(user!.photoUrl!)
                            : null,
                        child: user?.photoUrl == null
                            ? const Icon(Icons.person, size: 60)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      enabled: false, // Email es de solo lectura
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Selector de ubicación para vendedores
                  const Text('Ubicación en el mapa (solo vendedores)', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  UbicacionSelector(
                    latitudInicial: _latitud,
                    longitudInicial: _longitud,
                    onUbicacionSeleccionada: (lat, lng) {
                      setState(() {
                        _latitud = lat;
                        _longitud = lng;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _guardandoUbicacion ? null : _guardarUbicacion,
                      icon: const Icon(Icons.location_on),
                      label: _guardandoUbicacion
                          ? const Text('Guardando...')
                          : const Text('Guardar Ubicación'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: authProvider.isLoading ? null : _saveProfile,
                      child: const Text('Guardar Cambios'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
} 