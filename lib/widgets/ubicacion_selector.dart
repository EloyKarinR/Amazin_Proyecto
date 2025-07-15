import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class UbicacionSelector extends StatefulWidget {
  final double? latitudInicial;
  final double? longitudInicial;
  final Function(double lat, double lng) onUbicacionSeleccionada;

  const UbicacionSelector({
    Key? key,
    this.latitudInicial,
    this.longitudInicial,
    required this.onUbicacionSeleccionada,
  }) : super(key: key);

  @override
  State<UbicacionSelector> createState() => _UbicacionSelectorState();
}

class _UbicacionSelectorState extends State<UbicacionSelector> {
  late LatLng _posicion;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _inicializarUbicacion();
  }

  Future<void> _inicializarUbicacion() async {
    print('[UbicacionSelector] Iniciando inicialización de ubicación...');
    LocationPermission permission = await Geolocator.checkPermission();
    print('[UbicacionSelector] Estado inicial del permiso: $permission');
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      print('[UbicacionSelector] Estado tras solicitar permiso: $permission');
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        // El usuario no concedió el permiso
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Debes conceder permisos de ubicación para seleccionar tu ubicación en el mapa.')),
          );
        }
        setState(() {
          _cargando = false;
        });
        print('[UbicacionSelector] Permiso denegado, no se puede obtener ubicación.');
        return;
      }
    }
    try {
      if (widget.latitudInicial != null && widget.longitudInicial != null) {
        print('[UbicacionSelector] Usando latitud/longitud inicial proporcionada.');
        _posicion = LatLng(widget.latitudInicial!, widget.longitudInicial!);
      } else {
        print('[UbicacionSelector] Obteniendo ubicación actual del dispositivo...');
        Position posicionActual = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        print('[UbicacionSelector] Ubicación obtenida: ${posicionActual.latitude}, ${posicionActual.longitude}');
        _posicion = LatLng(posicionActual.latitude, posicionActual.longitude);
      }
      setState(() {
        _cargando = false;
      });
    } catch (e) {
      print('[UbicacionSelector] Error al obtener ubicación: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al obtener ubicación: $e')),
        );
      }
      setState(() {
        _cargando = false;
      });
    }
  }

  void _onCameraMove(CameraPosition position) {
    setState(() {
      _posicion = position.target;
    });
  }

  void _confirmarUbicacion() {
    widget.onUbicacionSeleccionada(_posicion.latitude, _posicion.longitude);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ubicación seleccionada: (${_posicion.latitude.toStringAsFixed(5)}, ${_posicion.longitude.toStringAsFixed(5)})')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        SizedBox(
          height: 250,
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(target: _posicion, zoom: 16),
                onCameraMove: _onCameraMove,
                markers: {
                  Marker(
                    markerId: const MarkerId('seleccion'),
                    position: _posicion,
                    draggable: false,
                  ),
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: false,
              ),
              const Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Mueve el mapa para seleccionar tu ubicación', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _confirmarUbicacion,
          icon: const Icon(Icons.check),
          label: const Text('Confirmar ubicación'),
        ),
      ],
    );
  }
} 