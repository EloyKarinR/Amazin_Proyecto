import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/main_navigator.dart';
import 'providers/cart_provider.dart';
import 'models/cart_item.dart'; // Importar CartItem para registrar el adaptador
import 'models/product.dart'; // Importar Product para registrar el adaptador

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Registrar adaptadores si no están registrados
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(CartItemAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(ProductAdapter());
  }

  runApp(const MyShopApp());
}

class MyShopApp extends StatelessWidget {
  const MyShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => CartProvider(),
      child: MaterialApp(
        title: 'Mi Tienda Online',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
          useMaterial3: true,
        ),
        home: const MainNavigator(),
      ),
    );
  }
}
