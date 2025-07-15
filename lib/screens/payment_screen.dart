import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import '../providers/cart_provider.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/address_service.dart';
import '../models/address.dart';
import 'address_list_screen.dart';
import 'recibo_screen.dart';
import '../services/compra_service.dart';
import '../models/compra.dart';

class PaymentScreen extends StatefulWidget {
  final Product? product;
  final int? quantity;
  final String? address;

  const PaymentScreen({Key? key, this.product, this.quantity, this.address}) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  Address? _selectedAddress;
  bool _isLoadingAddress = true;
  String _selectedPaymentMethod = 'credit_card';
  bool _isProcessing = false;
  // Variables para la tarjeta de crédito
  String cardNumber = '';
  String expiryDate = '';
  String cardHolderName = '';
  String cvvCode = '';
  bool isCvvFocused = false;
  final _creditCardFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadDefaultAddress();
  }

  Future<void> _loadDefaultAddress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() { _isLoadingAddress = false; });
      return;
    }
    final address = await AddressService().getDefaultAddress(user.uid);
    setState(() {
      _selectedAddress = address;
      _isLoadingAddress = false;
    });
  }

  Future<void> _showAddressForm() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final result = await showModalBottomSheet<Address>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: AddressForm(userId: user.uid),
      ),
    );
    if (result != null) {
      await AddressService().setDefaultAddress(user.uid, result.id);
      await _loadDefaultAddress();
    }
  }

  Future<void> _showAddressList() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddressListScreen()),
    );
    await _loadDefaultAddress();
  }

  void _onCreditCardModelChange(CreditCardModel? creditCardModel) {
    setState(() {
      cardNumber = creditCardModel?.cardNumber ?? '';
      expiryDate = creditCardModel?.expiryDate ?? '';
      cardHolderName = creditCardModel?.cardHolderName ?? '';
      cvvCode = creditCardModel?.cvvCode ?? '';
      isCvvFocused = creditCardModel?.isCvvFocused ?? false;
    });
  }

  void _processPayment() async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona o agrega una dirección de entrega.')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isProcessing = true);
    final user = FirebaseAuth.instance.currentUser;
    final cart = Provider.of<CartProvider>(context, listen: false);
    final cartItems = widget.product != null
        ? [CartItem(product: widget.product!, quantity: widget.quantity ?? 1)]
        : List<CartItem>.from(cart.items);
    final productos = cartItems.map((item) => {
      'nombre': item.product.name,
      'cantidad': item.quantity,
      'precioUnitario': item.product.price,
      'subtotal': item.product.price * item.quantity,
    }).toList();
    final total = widget.product != null
        ? (widget.product!.price * (widget.quantity ?? 1))
        : cartItems.fold(0.0, (sum, item) => sum + (item.product.price * item.quantity));
    print('--- Productos para el recibo ---');
    for (var p in productos) {
      print('Producto: ${p['nombre']} | Cantidad: ${p['cantidad']} | Precio unitario: ${p['precioUnitario']} | Subtotal: ${p['subtotal']}');
    }
    print('Total calculado: $total');
    final metodoPagoLabel = _selectedPaymentMethod == 'paypal'
        ? 'PayPal'
        : _selectedPaymentMethod == 'google_pay'
            ? 'Google Pay'
            : 'Tarjeta de crédito';
    final reciboId = DateTime.now().millisecondsSinceEpoch.toString();
    // REGISTRAR LA COMPRA EN FIRESTORE
    final compraService = CompraService();
    for (final item in cartItems) {
      final compra = Compra(
        id: '',
        idProducto: item.product.id,
        idUsuario: user?.uid ?? '',
        fechaCompra: DateTime.now(),
        estado: 'pendiente',
        cantidad: item.quantity,
        precio: item.product.price,
        imageUrl: item.product.imageUrl,
      );
      await compraService.registrarCompra(user?.uid ?? '', compra);
    }
    // Simular procesamiento de pago
    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      Provider.of<CartProvider>(context, listen: false).clear();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ReciboScreen(
            receiptId: reciboId,
            comercioNombre: 'Mercadito App',
            comercioContacto: 'soporte@mercadito.com',
            clienteNombre: user?.displayName ?? 'Usuario',
            clienteEmail: user?.email ?? '',
            direccionEntrega: _selectedAddress!,
            productos: productos,
            total: total,
            metodoPago: metodoPagoLabel,
            fecha: DateTime.now(),
          ),
        ),
      );
    });
  }

  // Agrega este método auxiliar para obtener el logo y nombre del método seleccionado
  Widget _buildSelectedPaymentMethod() {
    String label = '';
    Widget icon;
    switch (_selectedPaymentMethod) {
      case 'paypal':
        label = 'PayPal';
        icon = Image.asset('assets/icon/paypal.png', width: 32, height: 32);
        break;
      case 'google_pay':
        label = 'Google Pay';
        icon = Image.asset('assets/icon/googlepay.png', width: 32, height: 32);
        break;
      case 'credit_card':
      default:
        label = 'Tarjeta de crédito';
        icon = Icon(Icons.credit_card, color: Colors.orange.shade700, size: 32);
        break;
    }
    return Card(
      color: Colors.orange.shade50,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: icon,
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Método seleccionado'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final cartItems = widget.product != null
        ? [CartItem(product: widget.product!, quantity: widget.quantity ?? 1)]
        : cart.items;
    final total = widget.product != null
        ? (widget.product!.price * (widget.quantity ?? 1))
        : cart.totalAmount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pago'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Resumen del pedido
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resumen del Pedido',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...cartItems.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${item.product.name} x${item.quantity}'),
                            Text('\$${(item.product.price * item.quantity).toStringAsFixed(2)}'),
                          ],
                        ),
                      )),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '\$${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Dirección de entrega
              _isLoadingAddress
                  ? const Center(child: CircularProgressIndicator())
                  : _selectedAddress == null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('No tienes dirección de entrega registrada.'),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _showAddressForm,
                              icon: const Icon(Icons.add_location_alt),
                              label: const Text('Agregar dirección'),
                            ),
                          ],
                        )
                      : Card(
                          color: Colors.orange.shade50,
                          child: ListTile(
                            leading: const Icon(Icons.location_on, color: Colors.orange),
                            title: Text(_selectedAddress!.fullName),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_selectedAddress!.addressLine1 + ( _selectedAddress!.addressLine2 != null && _selectedAddress!.addressLine2!.isNotEmpty ? ", " + _selectedAddress!.addressLine2! : "")),
                                Text('${_selectedAddress!.city}, ${_selectedAddress!.state}, ${_selectedAddress!.zipCode}'),
                                Text(_selectedAddress!.country),
                                if (_selectedAddress!.phone.isNotEmpty) Text('Tel: ${_selectedAddress!.phone}'),
                                if (_selectedAddress!.deliveryInstructions != null && _selectedAddress!.deliveryInstructions!.isNotEmpty)
                                  Text('Notas: ${_selectedAddress!.deliveryInstructions}'),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'change') _showAddressList();
                                if (value == 'add') _showAddressForm();
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'change', child: Text('Cambiar dirección')),
                                const PopupMenuItem(value: 'add', child: Text('Agregar nueva dirección')),
                              ],
                            ),
                          ),
                        ),
              const SizedBox(height: 16),

              // Método de pago
              DropdownButtonFormField<String>(
                value: _selectedPaymentMethod,
                items: [
                  DropdownMenuItem(
                    value: 'credit_card',
                    child: Row(
                      children: [
                        Icon(Icons.credit_card, color: Colors.orange.shade700),
                        const SizedBox(width: 8),
                        const Text('Tarjeta de crédito'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'paypal',
                    child: Row(
                      children: [
                        Image.asset('assets/icon/paypal.png', width: 28, height: 28),
                        const SizedBox(width: 8),
                        const Text('PayPal'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'google_pay',
                    child: Row(
                      children: [
                        Image.asset('assets/icon/googlepay.png', width: 28, height: 28),
                        const SizedBox(width: 8),
                        const Text('Google Pay'),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value!;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Método de pago',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // Visualización bonita del método seleccionado
              _buildSelectedPaymentMethod(),

              // Widget de tarjeta de crédito
              if (_selectedPaymentMethod == 'credit_card' || _selectedPaymentMethod == 'debit_card') ...[
                CreditCardWidget(
                  cardNumber: cardNumber,
                  expiryDate: expiryDate,
                  cardHolderName: cardHolderName,
                  cvvCode: cvvCode,
                  showBackView: isCvvFocused,
                  onCreditCardWidgetChange: (CreditCardBrand? brand) {},
                ),
                const SizedBox(height: 16),
                CreditCardForm(
                  formKey: _creditCardFormKey,
                  cardNumber: cardNumber,
                  expiryDate: expiryDate,
                  cardHolderName: cardHolderName,
                  cvvCode: cvvCode,
                  onCreditCardModelChange: _onCreditCardModelChange,
                  inputConfiguration: const InputConfiguration(
                    cardNumberDecoration: InputDecoration(
                      labelText: 'Número de tarjeta',
                      hintText: 'XXXX XXXX XXXX XXXX',
                      border: OutlineInputBorder(),
                    ),
                    expiryDateDecoration: InputDecoration(
                      labelText: 'Fecha de expiración',
                      hintText: 'XX/XX',
                      border: OutlineInputBorder(),
                    ),
                    cardHolderDecoration: InputDecoration(
                      labelText: 'Nombre en la tarjeta',
                      border: OutlineInputBorder(),
                    ),
                    cvvCodeDecoration: InputDecoration(
                      labelText: 'CVV',
                      hintText: 'XXX',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _processPayment,
                  child: _isProcessing
                      ? const CircularProgressIndicator()
                      : const Text('Proceder al Pago'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 