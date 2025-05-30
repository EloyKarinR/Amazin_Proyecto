import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import '../providers/cart_provider.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _addressController = TextEditingController();
  String? _selectedPaymentMethod;
  final List<String> _paymentMethods = [
    'Tarjeta de Crédito',
    'PayPal',
    'Contra entrega',
  ];

  // Variables para flutter_credit_card
  String cardNumber = '';
  String expiryDate = '';
  String cardHolderName = '';
  String cvvCode = '';
  bool isCvvFocused = false;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  bool _isValidAddress(String address) {
    // Mínimo 10 caracteres y al menos un número
    return address.trim().length >= 10 && RegExp(r'[0-9]').hasMatch(address);
  }

  void onCreditCardModelChange(CreditCardModel creditCardModel) {
    setState(() {
      cardNumber = creditCardModel.cardNumber;
      expiryDate = creditCardModel.expiryDate;
      cardHolderName = creditCardModel.cardHolderName;
      cvvCode = creditCardModel.cvvCode;
      isCvvFocused = creditCardModel.isCvvFocused;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pago'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen de la compra',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: cart.items.length,
                itemBuilder: (context, index) {
                  final item = cart.items[index];
                  return ListTile(
                    leading: Image.network(
                      item.product.imageUrl,
                      width: 40,
                      height: 40,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.image),
                    ),
                    title: Text(item.product.name),
                    subtitle: Text('Cantidad: ${item.quantity}'),
                    trailing: Text('\$${item.totalPrice.toStringAsFixed(2)}'),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$${cart.totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Dirección de envío',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedPaymentMethod,
              items: _paymentMethods
                  .map((method) => DropdownMenuItem(
                        value: method,
                        child: Text(method),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Método de pago',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.payment),
              ),
            ),
            if (_selectedPaymentMethod == 'Tarjeta de Crédito') ...[
              const SizedBox(height: 16),
              // Widget para visualizar la tarjeta (opcional)
              CreditCardWidget(
                cardNumber: cardNumber,
                expiryDate: expiryDate,
                cardHolderName: cardHolderName,
                cvvCode: cvvCode,
                showBackView: isCvvFocused,
                onCreditCardWidgetChange: (CreditCardBrand brand) {
                  // Aquí puedes reaccionar a los cambios de marca (Visa, Mastercard, etc.)
                  // print('Marca de tarjeta detectada: ${brand.brandName}');
                },
                cardBgColor: Colors.orange.shade800,
                obscureCardNumber: true,
                obscureCardCvv: true,
                isHolderNameVisible: true,
                isChipVisible: true,
                isSwipeGestureEnabled: true,
                animationDuration: const Duration(milliseconds: 500),
                backgroundImage: null, // Puedes poner una imagen de fondo si quieres
                glassmorphismConfig: Glassmorphism(blurX: 10.0, blurY: 10.0, gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: <Color>[ Colors.grey.withAlpha(20), Colors.grey.withAlpha(20), ], stops: const <double>[0.3, 1.0,],),), // Efecto glassmorphism opcional
              ),
              // Formulario para ingresar los datos de la tarjeta
              CreditCardForm(
                formKey: formKey,
                cardNumber: cardNumber,
                expiryDate: expiryDate,
                cvvCode: cvvCode,
                cardHolderName: cardHolderName,
                onCreditCardModelChange: onCreditCardModelChange,
                inputConfiguration: const InputConfiguration(
                  cardNumberDecoration: InputDecoration(
                    labelText: 'Número de tarjeta',
                    hintText: 'XXXX XXXX XXXX XXXX',
                    border: OutlineInputBorder(),
                  ),
                  expiryDateDecoration: InputDecoration(
                    labelText: 'Fecha de vencimiento',
                    hintText: 'MM/AA',
                    border: OutlineInputBorder(),
                  ),
                  cvvCodeDecoration: InputDecoration(
                    labelText: 'CVV',
                    hintText: 'XXX',
                    border: OutlineInputBorder(),
                  ),
                  cardHolderDecoration: InputDecoration(
                    labelText: 'Nombre del titular',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (!_isValidAddress(_addressController.text)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Por favor ingresa una dirección válida (mínimo 10 caracteres y al menos un número).')),
                    );
                    return;
                  }
                  if (_selectedPaymentMethod == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Por favor selecciona un método de pago.')),
                    );
                    return;
                  }
                  if (_selectedPaymentMethod == 'Tarjeta de Crédito') {
                    // Validar el formulario de la tarjeta usando la formKey
                    if (formKey.currentState!.validate()) {
                       // Si la validación del formulario de tarjeta pasa:
                       showDialog(
                         context: context,
                         builder: (context) => AlertDialog(
                           title: const Text('¡Pago exitoso!'),
                           content: Text('Tu compra ha sido realizada correctamente.\n\nDirección: ${_addressController.text}\nMétodo de pago: $_selectedPaymentMethod\nNúmero de tarjeta: $cardNumber'), // Puedes mostrar el número de tarjeta (solo para demostración)
                           actions: [
                             TextButton(
                               onPressed: () {
                                 cart.clear();
                                 Navigator.of(context).popUntil((route) => route.isFirst);
                               },
                               child: const Text('Aceptar'),
                             ),
                           ],
                         ),
                       );
                    } else {
                      // Si la validación del formulario de tarjeta falla:
                      ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text('Por favor completa correctamente los datos de la tarjeta.')),
                       );
                    }
                  } else {
                    // Lógica para otros métodos de pago (PayPal, Contra entrega)
                     showDialog(
                       context: context,
                       builder: (context) => AlertDialog(
                         title: const Text('¡Pago exitoso!'),
                         content: Text('Tu compra ha sido realizada correctamente.\n\nDirección: ${_addressController.text}\nMétodo de pago: $_selectedPaymentMethod'),
                         actions: [
                           TextButton(
                             onPressed: () {
                               cart.clear();
                               Navigator.of(context).popUntil((route) => route.isFirst);
                             },
                             child: const Text('Aceptar'),
                           ),
                         ],
                       ),
                     );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Pagar',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 