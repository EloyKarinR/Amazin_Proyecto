# Aplicación de Comercio Electronico - Proyecto de la Universidad

📦 Nombre del Proyecto
Amazin — Aplicación de Comercio Electrónico desarrollada en Flutter, con integración de Firebase y una experiencia profesional para usuarios y vendedores.

🚀 Descripción
Amazin es una aplicación móvil de e-commerce que permite a los usuarios explorar productos, gestionar direcciones, realizar compras, dejar reseñas y a los vendedores administrar su catálogo y ventas. Incluye funcionalidades modernas como notificaciones, pagos simulados y mapas interactivos.

🛠️ Tecnologías Utilizadas
- Flutter (Dart)
- Firebase (Firestore, Auth, Storage)
- Provider (State Management)
- Google Maps Flutter
- Geolocator
- flutter_local_notifications
- flutter_credit_card
- dropdown_search
- Git (Control de versiones)

✨ Características Principales
- Gestión de direcciones con selección dinámica de país, estado y ciudad.
- Catálogo de productos con imágenes y descripciones.
- Carrito de compras y flujo de pago simulado (tarjeta, PayPal, Google Pay).
- Historial de compras y seguimiento de pedidos con notificaciones locales.
- Sistema de reseñas con lógica de compra verificada y calificación en tiempo real.
- Panel de vendedor con estadísticas y edición de ubicación en mapa interactivo.
- Notificaciones in-app y locales.
- Interfaz moderna y responsiva con navegación intuitiva.

📸 Capturas de Pantalla


<img src="https://github.com/user-attachments/assets/c8048275-524d-453a-b96d-a46f80e34749" alt="cap1" width="350"/>
<img src="https://github.com/user-attachments/assets/7b118d94-11f4-4a0d-84ba-991179a25cf6" alt="cap2" width="350"/>
<img src="https://github.com/user-attachments/assets/cff314d5-2113-4649-9899-41e8e285a89a" alt="cap3" width="350"/>
<img src="https://github.com/user-attachments/assets/3db25541-dd78-49a9-aa77-9cee04883350" alt="cap4" width="350"/>
<img src="https://github.com/user-attachments/assets/de09e035-afc8-4967-a38c-1ed2425cb3e3" alt="cap5" width="350"/>
<img src="https://github.com/user-attachments/assets/649ebe02-a967-4fa6-b0f9-8891a6dd9935" alt="cap6" width="350"/>
<img src="https://github.com/user-attachments/assets/5fe191cd-59a5-445b-b5f5-8a198f91b482" alt="cap7" width="350"/>

# Estructura del Proyecto Amazin

```
📦 ticket_app
├── 📱 lib/
│   ├── main.dart
│   ├── firebase_options.dart
│   ├── 📂 screens/
│   │   ├── main_navigator.dart
│   │   ├── home_screen.dart
│   │   ├── products_screen.dart
│   │   ├── product_detail_screen.dart
│   │   ├── cart_screen.dart
│   │   ├── payment_screen.dart
│   │   ├── payment_methods_screen.dart
│   │   ├── recibo_screen.dart
│   │   ├── historial_compras_screen.dart
│   │   ├── address_list_screen.dart
│   │   ├── profile_screen.dart
│   │   ├── edit_profile_screen.dart
│   │   ├── notificaciones_screen.dart
│   │   ├── seller_register_screen.dart
│   │   ├── seller_dashboard_screen.dart
│   │   ├── sell_product_screen.dart
│   │   └── 📂 auth/
│   ├── 📂 services/
│   │   ├── auth_service.dart
│   │   ├── product_service.dart
│   │   ├── address_service.dart
│   │   ├── comentario_service.dart
│   │   ├── compra_service.dart
│   │   ├── payment_method_service.dart
│   │   ├── notificacion_service.dart
│   │   ├── seller_service.dart
│   │   └── category_seed.dart
│   ├── 📂 models/
│   │   ├── user.dart
│   │   ├── product.dart
│   │   ├── cart_item.dart
│   │   ├── address.dart
│   │   ├── comentario.dart
│   │   ├── compra.dart
│   │   ├── payment_method.dart
│   │   ├── notificacion.dart
│   │   ├── seller.dart
│   │   ├── category.dart
│   │   └── *.g.dart
│   ├── 📂 providers/
│   └── 📂 widgets/
├── 📂 assets/
│   ├── 📂 images/
│   ├── 📂 icon/
│   ├── cities_latam.json
│   ├── states_latam.json
│   └── countries_latam.json
├── 📂 android/
├── 📂 ios/
├── 📂 web/
├── 📂 test/
├── pubspec.yaml
├── firebase.json
├── .firebaserc
├── storage.rules
└── README.md
```

👤 Autor
Eloy Karin Rivadeneira Miller
