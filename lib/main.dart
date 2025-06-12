import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/main_navigator.dart';
import 'providers/cart_provider.dart';
import 'providers/auth_provider.dart';
import 'models/cart_item.dart'; // Importar CartItem para registrar el adaptador
import 'models/product.dart'; // Importar Product para registrar el adaptador
import 'screens/auth/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/auth/loading_screen.dart';

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

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyShopApp());
}

class MyShopApp extends StatelessWidget {
  const MyShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => CartProvider()),
        ChangeNotifierProvider(create: (ctx) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Mi Tienda Online',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
          useMaterial3: true,
        ),
        home: Consumer<AuthProvider>(
          builder: (ctx, auth, _) {
            // Mostrar pantalla de carga si se está verificando la autenticación inicial
            if (auth.isAuthenticating) {
              return const LoadingScreen();
            }

            // Si ya se verificó y hay un usuario autenticado, muestra MainNavigator
            if (auth.isAuthenticated) {
              return const MainNavigator();
            }
            
            // Si no hay usuario autenticado, muestra la pantalla de login
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
