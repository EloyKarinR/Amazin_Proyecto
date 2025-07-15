import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../models/address.dart';
import '../services/address_service.dart';
import '../providers/auth_provider.dart';

class AddressListScreen extends StatefulWidget {
  const AddressListScreen({Key? key}) : super(key: key);

  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  late AddressService _addressService;
  List<Address> _addresses = [];
  bool _isLoading = true;
  String? _userId;
  // Eliminar _countries, _selectedCountryName y _selectedCountryCode de aquí

  @override
  void initState() {
    super.initState();
    _addressService = AddressService();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAddresses());
  }

  Future<void> _loadAddresses() async {
    final userId = Provider.of<AuthProvider>(context, listen: false).user?.id;
    if (userId == null) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo obtener el usuario actual.')),
      );
      return;
    }
    setState(() { _isLoading = true; _userId = userId; });
    try {
      final addresses = await _addressService.getUserAddresses(userId);
      setState(() {
        _addresses = addresses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error al cargar direcciones'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _showAddressForm({Address? address}) async {
    final result = await showModalBottomSheet<Address>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddressForm(
          userId: _userId!,
          address: address,
        ),
      ),
    );
    if (result != null) _loadAddresses();
  }

  void _deleteAddress(Address address) async {
    await _addressService.deleteAddress(address.id);
    _loadAddresses();
  }

  void _setDefault(Address address) async {
    await _addressService.setDefaultAddress(_userId!, address.id);
    _loadAddresses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Direcciones')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _addresses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_off, size: 80, color: Colors.orange.shade200),
                      const SizedBox(height: 16),
                      const Text(
                        'No tienes direcciones guardadas.',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Agrega tu primera dirección para facilitar tus compras.',
                        style: TextStyle(fontSize: 15, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _addresses.length,
                  itemBuilder: (context, index) {
                    final address = _addresses[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: ListTile(
                        leading: Icon(
                          address.isDefault ? Icons.star : Icons.location_on,
                          color: address.isDefault ? Colors.orange : Colors.blueGrey,
                        ),
                        title: Text(address.fullName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${address.addressLine1}${address.addressLine2 != null && address.addressLine2!.isNotEmpty ? ", ${address.addressLine2!}" : ""}'),
                            Text('${address.city}, ${address.state}, ${address.zipCode}'),
                            Text(address.country),
                            if (address.phone.isNotEmpty) Text('Tel: ${address.phone}'),
                            if (address.deliveryInstructions != null && address.deliveryInstructions!.isNotEmpty)
                              Text('Notas: ${address.deliveryInstructions}'),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') _showAddressForm(address: address);
                            if (value == 'delete') _deleteAddress(address);
                            if (value == 'default') _setDefault(address);
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'edit', child: Text('Editar')),
                            const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                            if (!address.isDefault)
                              const PopupMenuItem(value: 'default', child: Text('Marcar como predeterminada')),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddressForm(),
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Agregar dirección'),
      ),
    );
  }
}

class AddressForm extends StatefulWidget {
  final String userId;
  final Address? address;
  const AddressForm({Key? key, required this.userId, this.address}) : super(key: key);

  @override
  State<AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<AddressForm> {
  final _formKey = GlobalKey<FormState>();
  final AddressService _addressService = AddressService();
  bool _isSaving = false;

  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _address1Controller;
  late TextEditingController _address2Controller;
  late TextEditingController _zipController;
  late TextEditingController _instructionsController;

  List<Map<String, String>> _countries = [];
  List<Map<String, dynamic>> _states = [];
  List<Map<String, dynamic>> _cities = [];
  
  String? _selectedCountryName;
  String? _selectedCountryCode;
  String? _selectedStateName;
  String? _selectedCityName;
  bool _isDefault = false;

  // Mapa para los labels de división política por país
  final Map<String, String> _divisionLabels = {
    'AR': 'Provincia',
    'BO': 'Departamento',
    'BR': 'Estado',
    'CL': 'Región',
    'CO': 'Departamento',
    'CR': 'Provincia',
    'CU': 'Provincia',
    'EC': 'Provincia',
    'SV': 'Departamento',
    'GT': 'Departamento',
    'HN': 'Departamento',
    'MX': 'Estado',
    'NI': 'Departamento',
    'PA': 'Provincia',
    'PY': 'Departamento',
    'PE': 'Región',
    'PR': 'Municipio',
    'DO': 'Provincia',
    'UY': 'Departamento',
    'VE': 'Estado',
  };

  String get _currentDivisionLabel {
    if (_selectedCountryCode != null && _divisionLabels.containsKey(_selectedCountryCode)) {
      return _divisionLabels[_selectedCountryCode!]!;
    }
    return 'Estado/Provincia';
  }

  @override
  void initState() {
    super.initState();
    final a = widget.address;
    _fullNameController = TextEditingController(text: a?.fullName ?? '');
    _phoneController = TextEditingController(text: a?.phone ?? '');
    _address1Controller = TextEditingController(text: a?.addressLine1 ?? '');
    _address2Controller = TextEditingController(text: a?.addressLine2 ?? '');
    _zipController = TextEditingController(text: a?.zipCode ?? '');
    _instructionsController = TextEditingController(text: a?.deliveryInstructions ?? '');
    _isDefault = a?.isDefault ?? false;
    _loadCountries().then((_) async {
      if (a != null) {
        // Seleccionar país
        final country = _countries.firstWhere(
          (c) => c['name'] == a.country,
          orElse: () => _countries.isNotEmpty ? _countries.first : {'code': '', 'name': ''},
        );
        _selectedCountryName = country['name'];
        _selectedCountryCode = country['code'];
        // Cargar estados y seleccionar el guardado
        if (_selectedCountryCode != null) {
          await _loadStates(_selectedCountryCode!);
          // Seleccionar provincia/estado guardado
          final state = _states.firstWhere(
            (s) => s['name'] == a.state,
            orElse: () => _states.isNotEmpty ? _states.first : {'name': ''},
          );
          _selectedStateName = state['name'];
          // Cargar ciudades y seleccionar la guardada
          final cities = await _addressService.getCitiesByCountry(_selectedCountryCode!);
          // Si el JSON de ciudades tiene campo 'state', filtrar por estado
          final filtered = cities.where((c) => c['state'] == _selectedStateName).toList();
          _cities = filtered.isNotEmpty ? filtered : [];
          if (_cities.isNotEmpty) {
            final city = _cities.firstWhere(
              (c) => c['name'] == a.city,
              orElse: () => _cities.isNotEmpty ? _cities.first : {'name': ''},
            );
            _selectedCityName = city['name'];
          } else {
            _selectedCityName = null;
          }
        }
        setState(() {});
      }
    });
  }

  Future<void> _loadCountries() async {
    final String data = await rootBundle.loadString('assets/countries_latam.json');
    final List<dynamic> jsonResult = json.decode(data);
    setState(() {
      _countries = jsonResult.map<Map<String, String>>((e) => {
        'name': e['name'] as String,
        'code': e['code'] as String,
      }).toList();
    });
  }

  Future<void> _loadStates(String countryCode) async {
    try {
      final states = await _addressService.getStatesByCountry(countryCode);
      setState(() {
        _states = states;
        _selectedStateName = null;
      });
    } catch (e) {
      setState(() {
        _states = [];
        _selectedStateName = null;
      });
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _zipController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isSaving = true; });
    final address = Address(
      id: widget.address?.id ?? '',
      userId: widget.userId,
      country: _selectedCountryName ?? 'Perú',
      fullName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim(),
      addressLine1: _address1Controller.text.trim(),
      addressLine2: _address2Controller.text.trim(),
      city: _selectedCityName ?? '', // <-- aquí el cambio
      state: _selectedStateName ?? 'Lima',
      zipCode: _zipController.text.trim(),
      isDefault: _isDefault,
      deliveryInstructions: _instructionsController.text.trim(),
      createdAt: widget.address?.createdAt ?? DateTime.now(),
    );
    final service = AddressService();
    if (widget.address == null) {
      await service.addAddress(address);
    } else {
      await service.updateAddress(address);
    }
    if (_isDefault) {
      await service.setDefaultAddress(widget.userId, address.id);
    }
    if (mounted) Navigator.pop(context, address);
    setState(() { _isSaving = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.location_on, size: 48, color: Colors.orange.shade400),
                      const SizedBox(height: 8),
                      Text(
                        widget.address == null ? 'Agregar nueva dirección' : 'Editar dirección',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Datos de contacto', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                // País
                DropdownSearch<String>(
                  items: _countries.map((c) => c['name'] ?? '').toList(),
                  selectedItem: _selectedCountryName,
                  onChanged: (value) async {
                    setState(() {
                      _selectedCountryName = value;
                      _selectedCountryCode = _countries.firstWhere(
                        (c) => c['name'] == value,
                        orElse: () => {'code': '', 'name': ''},
                      )['code'];
                    });
                    if (_selectedCountryCode != null) {
                      await _loadStates(_selectedCountryCode!);
                      // Si el estado anterior no existe en la nueva lista, limpiar
                      if (!_states.any((s) => s['name'] == _selectedStateName)) {
                        setState(() {
                          _selectedStateName = null;
                        });
                      }
                      // Limpiar ciudades
                      setState(() {
                        _cities = [];
                        _selectedCityName = null;
                      });
                    }
                  },
                  validator: (v) => v == null || v.isEmpty ? 'Selecciona un país' : null,
                  dropdownDecoratorProps: const DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: 'País',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  popupProps: const PopupProps.menu(
                    showSearchBox: true,
                    fit: FlexFit.loose,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(labelText: 'Nombre completo'),
                  validator: (v) => v == null || v.isEmpty ? 'Campo obligatorio' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.isEmpty ? 'Campo obligatorio' : null,
                ),
                const SizedBox(height: 20),
                const Text('Dirección', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _address1Controller,
                  decoration: const InputDecoration(labelText: 'Dirección (calle, número, etc.)'),
                  validator: (v) => v == null || v.isEmpty ? 'Campo obligatorio' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _address2Controller,
                  decoration: const InputDecoration(labelText: 'Departamento/Suite (opcional)'),
                ),
                const SizedBox(height: 8),
                // Estado/Provincia/Departamento/Región
                DropdownSearch<String>(
                  items: _states
                      .map((s) => s['name'])
                      .whereType<String>()
                      .toList(),
                  selectedItem: _selectedStateName,
                  onChanged: (value) async {
                    setState(() {
                      _selectedStateName = value;
                    });
                    // Filtrar ciudades por país y estado seleccionados
                    if (_selectedCountryCode != null && value != null) {
                      final cities = await _addressService.getCitiesByCountry(_selectedCountryCode!);
                      // Filtrar por estado si el JSON de ciudades tiene ese campo
                      final filtered = cities.where((c) => c['state'] == value).toList();
                      setState(() {
                        _cities = filtered.isNotEmpty ? filtered : [];
                        // Si la ciudad anterior no existe en la nueva lista, limpiar
                        if (!_cities.any((c) => c['name'] == _selectedCityName)) {
                          _selectedCityName = null;
                        }
                      });
                    }
                  },
                  validator: (v) => v == null || v.isEmpty ? 'Selecciona ${_currentDivisionLabel.toLowerCase()}' : null,
                  dropdownDecoratorProps: DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: _currentDivisionLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  popupProps: const PopupProps.menu(
                    showSearchBox: true,
                    fit: FlexFit.loose,
                  ),
                ),
                const SizedBox(height: 8),
                // Ciudad (solo si hay ciudades disponibles)
                if (_cities.isNotEmpty)
                  DropdownSearch<String>(
                    items: _cities
                        .map((c) => c['name'])
                        .whereType<String>()
                        .toList(),
                    selectedItem: _selectedCityName,
                    onChanged: (value) {
                      setState(() {
                        _selectedCityName = value;
                      });
                    },
                    validator: (v) => v == null || v.isEmpty ? 'Selecciona una ciudad' : null,
                    dropdownDecoratorProps: const DropDownDecoratorProps(
                      dropdownSearchDecoration: InputDecoration(
                        labelText: 'Ciudad',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    popupProps: const PopupProps.menu(
                      showSearchBox: true,
                      fit: FlexFit.loose,
                    ),
                  ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _zipController,
                  decoration: const InputDecoration(labelText: 'Código postal'),
                  validator: (v) => v == null || v.isEmpty ? 'Campo obligatorio' : null,
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _instructionsController,
                  decoration: const InputDecoration(labelText: 'Instrucciones de entrega (opcional)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(
                      value: _isDefault,
                      onChanged: (v) => setState(() => _isDefault = v ?? false),
                    ),
                    const Text('Marcar como predeterminada'),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(widget.address == null ? 'Agregar dirección' : 'Guardar cambios'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 