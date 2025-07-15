import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> seedCategories() async {
  final categories = [
    {
      'id': 'electronica',
      'name': 'Electrónica',
      'imageUrl': 'https://cdn-icons-png.flaticon.com/512/1041/1041916.png',
      'description': 'Dispositivos electrónicos, gadgets, computadoras, celulares y más.'
    },
    {
      'id': 'moda-ropa',
      'name': 'Moda y Ropa',
      'imageUrl': 'https://cdn-icons-png.flaticon.com/512/892/892458.png',
      'description': 'Ropa, calzado, accesorios y moda para todas las edades.'
    },
    {
      'id': 'hogar-cocina',
      'name': 'Hogar y Cocina',
      'imageUrl': 'https://cdn-icons-png.flaticon.com/512/3075/3075977.png',
      'description': 'Artículos para el hogar, cocina, decoración y muebles.'
    },
    {
      'id': 'salud-belleza',
      'name': 'Salud y Belleza',
      'imageUrl': 'https://cdn-icons-png.flaticon.com/512/2921/2921822.png',
      'description': 'Productos de cuidado personal, belleza y salud.'
    },
    {
      'id': 'deportes-aire-libre',
      'name': 'Deportes y Aire Libre',
      'imageUrl': 'https://cdn-icons-png.flaticon.com/512/854/854894.png',
      'description': 'Artículos deportivos, fitness y actividades al aire libre.'
    },
    {
      'id': 'juguetes-ninos',
      'name': 'Juguetes y Niños',
      'imageUrl': 'https://cdn-icons-png.flaticon.com/512/3461/3461807.png',
      'description': 'Juguetes, juegos y productos para niños y bebés.'
    },
  ];

  final firestore = FirebaseFirestore.instance;
  for (final cat in categories) {
    await firestore.collection('categories').doc(cat['id']).set(cat);
    print('Categoría agregada: ${cat['name']}');
  }
  print('¡Todas las categorías han sido agregadas!');
} 