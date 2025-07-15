import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/payment_method.dart';
import '../services/payment_method_service.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({Key? key}) : super(key: key);

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  late PaymentMethodService _service;
  List<PaymentMethod> _methods = [];
  bool _isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _service = PaymentMethodService();
    _loadMethods();
  }

  Future<void> _loadMethods() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() { _isLoading = true; _userId = user.uid; });
    final methods = await _service.getUserPaymentMethods(user.uid);
    setState(() {
      _methods = methods;
      _isLoading = false;
    });
  }

  Future<void> _showAddMethodForm() async {
    final result = await showModalBottomSheet<PaymentMethod>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: AddPaymentMethodForm(userId: _userId!),
      ),
    );
    if (result != null) _loadMethods();
  }

  void _deleteMethod(PaymentMethod method) async {
    await _service.deletePaymentMethod(method.id);
    _loadMethods();
  }

  void _setDefault(PaymentMethod method) async {
    await _service.setDefaultPaymentMethod(_userId!, method.id);
    _loadMethods();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Métodos de Pago')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _methods.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.credit_card, size: 80, color: Colors.orange.shade200),
                      const SizedBox(height: 16),
                      const Text(
                        'No tienes métodos de pago guardados.',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Agrega tu primer método de pago para facilitar tus compras.',
                        style: TextStyle(fontSize: 15, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _methods.length,
                  itemBuilder: (context, index) {
                    final method = _methods[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: ListTile(
                        leading: _getMethodLeading(method),
                        title: Text(_getMethodTitle(method)),
                        subtitle: Text(_getMethodSubtitle(method)),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'delete') _deleteMethod(method);
                            if (value == 'default') _setDefault(method);
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                            if (!method.isDefault)
                              const PopupMenuItem(value: 'default', child: Text('Marcar como predeterminado')),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMethodForm,
        icon: const Icon(Icons.add_card),
        label: const Text('Agregar método'),
      ),
    );
  }

  String _getMethodTitle(PaymentMethod method) {
    switch (method.type) {
      case 'credit_card':
        return 'Tarjeta de crédito';
      case 'paypal':
        return 'PayPal';
      case 'google_pay':
        return 'Google Pay';
      default:
        return 'Otro';
    }
  }

  Widget _getMethodLeading(PaymentMethod method) {
    switch (method.type) {
      case 'paypal':
        return Image.asset('assets/icon/paypal.png', width: 32, height: 32);
      case 'google_pay':
        return Image.asset('assets/icon/googlepay.png', width: 32, height: 32);
      case 'credit_card':
      default:
        return Icon(Icons.credit_card, color: method.isDefault ? Colors.orange : Colors.blueGrey, size: 32);
    }
  }

  String _getMethodSubtitle(PaymentMethod method) {
    switch (method.type) {
      case 'credit_card':
        return method.cardNumber != null && method.cardNumber!.length >= 4
            ? '**** **** **** ${method.cardNumber!.substring(method.cardNumber!.length - 4)}'
            : '';
      case 'paypal':
        return method.paypalEmail ?? '';
      case 'google_pay':
        return 'Google Pay vinculado';
      default:
        return '';
    }
  }
}

class AddPaymentMethodForm extends StatefulWidget {
  final String userId;
  const AddPaymentMethodForm({Key? key, required this.userId}) : super(key: key);

  @override
  State<AddPaymentMethodForm> createState() => _AddPaymentMethodFormState();
}

class _AddPaymentMethodFormState extends State<AddPaymentMethodForm> {
  final _formKey = GlobalKey<FormState>();
  String _type = 'credit_card';
  String? _cardHolder;
  String? _cardNumber;
  String? _expiryDate;
  String? _paypalEmail;
  bool _isDefault = false;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.2),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(18),
                            child: Icon(Icons.credit_card, size: 48, color: Colors.orange.shade700),
                          ),
                          const SizedBox(height: 12),
                          const Text('Nuevo método de pago', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Agrega o vincula un método para tus compras', style: TextStyle(fontSize: 14, color: Colors.grey)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Divider(height: 1, thickness: 1),
                    const SizedBox(height: 18),
                    DropdownButtonFormField<String>(
                      value: _type,
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
                        setState(() { _type = value!; });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Tipo de método',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.payment),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_type == 'credit_card') ...[
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Titular de la tarjeta',
                          hintText: 'Como aparece en la tarjeta',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        onChanged: (v) => _cardHolder = v,
                        validator: (v) => v == null || v.isEmpty ? 'Campo obligatorio' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Número de tarjeta',
                          hintText: 'XXXX XXXX XXXX XXXX',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.credit_card),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => _cardNumber = v,
                        validator: (v) => v == null || v.length < 12 ? 'Número inválido' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Fecha de expiración',
                          hintText: 'MM/AA',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.date_range),
                        ),
                        onChanged: (v) => _expiryDate = v,
                        validator: (v) => v == null || v.isEmpty ? 'Campo obligatorio' : null,
                      ),
                    ],
                    if (_type == 'paypal') ...[
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Correo de PayPal',
                          hintText: 'usuario@email.com',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.alternate_email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (v) => _paypalEmail = v,
                        validator: (v) => v == null || !v.contains('@') ? 'Correo inválido' : null,
                      ),
                    ],
                    if (_type == 'google_pay') ...[
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          children: [
                            Icon(Icons.account_balance_wallet, color: Colors.green, size: 28),
                            const SizedBox(width: 12),
                            const Expanded(child: Text('Google Pay se vinculará a tu cuenta (simulado).', style: TextStyle(fontSize: 15))),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: _isDefault,
                          onChanged: (v) => setState(() => _isDefault = v ?? false),
                        ),
                        Flexible(child: Text('Marcar como predeterminado', overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _save,
                        icon: _isSaving
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.save),
                        label: const Text('Guardar', style: TextStyle(fontSize: 17)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isSaving = true; });
    final method = PaymentMethod(
      id: '',
      userId: widget.userId,
      type: _type,
      cardHolder: _type == 'credit_card' ? _cardHolder : null,
      cardNumber: _type == 'credit_card' ? _cardNumber : null,
      expiryDate: _type == 'credit_card' ? _expiryDate : null,
      paypalEmail: _type == 'paypal' ? _paypalEmail : null,
      isDefault: _isDefault,
      createdAt: DateTime.now(),
    );
    await PaymentMethodService().addPaymentMethod(method);
    if (mounted) {
      Navigator.pop(context, method);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Método de pago guardado exitosamente')),
      );
    }
    setState(() { _isSaving = false; });
  }
} 