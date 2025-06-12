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
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  String _selectedPaymentMethod = 'credit_card';
  bool _isProcessing = false;

  // Variables para la tarjeta de crédito
  String cardNumber = '';
  String expiryDate = '';
  String cardHolderName = '';
  String cvvCode = '';
  bool isCvvFocused = false;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
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

  void _processPayment() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    // Simular procesamiento de pago
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return; // Check if the widget is still mounted
      setState(() => _isProcessing = false);
      
      // Mostrar diálogo de éxito
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('¡Pago Exitoso!'),
          content: const Text('Tu pedido ha sido procesado correctamente.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final cartItems = cart.items;
    final total = cart.totalAmount;

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
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Dirección de entrega',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa una dirección';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Método de pago
              DropdownButtonFormField<String>(
                value: _selectedPaymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Método de pago',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'credit_card',
                    child: Text('Tarjeta de crédito'),
                  ),
                  DropdownMenuItem(
                    value: 'debit_card',
                    child: Text('Tarjeta de débito'),
                  ),
                  DropdownMenuItem(
                    value: 'paypal',
                    child: Text('PayPal'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

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
                  formKey: _formKey,
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