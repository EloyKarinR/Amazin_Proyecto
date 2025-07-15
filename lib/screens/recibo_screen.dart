import 'package:flutter/material.dart';
import '../models/address.dart';
import 'historial_compras_screen.dart';

class ReciboScreen extends StatelessWidget {
  final String receiptId;
  final String comercioNombre;
  final String? comercioContacto;
  final String clienteNombre;
  final String clienteEmail;
  final Address direccionEntrega;
  final List<Map<String, dynamic>> productos; // [{nombre, cantidad, precioUnitario, subtotal}]
  final double total;
  final String metodoPago;
  final DateTime fecha;

  const ReciboScreen({
    Key? key,
    required this.receiptId,
    required this.comercioNombre,
    this.comercioContacto,
    required this.clienteNombre,
    required this.clienteEmail,
    required this.direccionEntrega,
    required this.productos,
    required this.total,
    required this.metodoPago,
    required this.fecha,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Navegación automática después de 7 segundos
    Future.delayed(const Duration(seconds: 7), () {
      if (Navigator.canPop(context)) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HistorialComprasScreen()),
        );
      }
    });
    return Scaffold(
      appBar: AppBar(title: const Text('Recibo de compra')),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: SingleChildScrollView(
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long, size: 48, color: Colors.orange.shade700),
                        const SizedBox(height: 8),
                        Text(comercioNombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                        if (comercioContacto != null)
                          Text(comercioContacto!, style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 8),
                        Text('Recibo #: $receiptId', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                        Text('Fecha: ${_formatFecha(fecha)}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const Divider(height: 32),
                  const Text('Datos del cliente', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(clienteNombre),
                  Text(clienteEmail, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  const Text('Dirección de entrega', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(direccionEntrega.addressLine1 + (direccionEntrega.addressLine2 != null && direccionEntrega.addressLine2!.isNotEmpty ? ", " + direccionEntrega.addressLine2! : "")),
                  Text('${direccionEntrega.city}, ${direccionEntrega.state}, ${direccionEntrega.zipCode}'),
                  Text(direccionEntrega.country),
                  if (direccionEntrega.phone.isNotEmpty) Text('Tel: ${direccionEntrega.phone}'),
                  if (direccionEntrega.deliveryInstructions != null && direccionEntrega.deliveryInstructions!.isNotEmpty)
                    Text('Notas: ${direccionEntrega.deliveryInstructions}'),
                  const Divider(height: 32),
                  const Text('Productos', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...productos.map((p) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text('${p['nombre']} x${p['cantidad']}')),
                          Text(' ${(p['subtotal'] as double).toStringAsFixed(2)}'),
                        ],
                      )),
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(' ${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Método de pago: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Flexible(child: Text(metodoPago, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text('¡Gracias por tu compra!', style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
  }
} 