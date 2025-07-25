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

📝 Estructura del Proyecto
ticket_app/
├── 📱 lib/                          # Código fuente principal
│   ├── main.dart                    # Punto de entrada de la aplicación
│   ├── firebase_options.dart        # Configuración de Firebase
│   ├── 📂 screens/                  # Pantallas de la aplicación
│   │   ├── main_navigator.dart      # Navegación principal
│   │   ├── home_screen.dart         # Pantalla de inicio
│   │   ├── products_screen.dart     # Lista de productos
│   │   ├── product_detail_screen.dart # Detalle de producto
│   │   ├── cart_screen.dart         # Carrito de compras
│   │   ├── payment_screen.dart      # Pantalla de pago
│   │   ├── payment_methods_screen.dart # Métodos de pago
│   │   ├── recibo_screen.dart       # Recibo de compra
│   │   ├── historial_compras_screen.dart # Historial de compras
│   │   ├── address_list_screen.dart # Gestión de direcciones
│   │   ├── profile_screen.dart      # Perfil de usuario
│   │   ├── edit_profile_screen.dart # Editar perfil
│   │   ├── notificaciones_screen.dart # Centro de notificaciones
│   │   ├── seller_register_screen.dart # Registro de vendedor
│   │   ├── seller_dashboard_screen.dart # Panel de vendedor
│   │   ├── sell_product_screen.dart # Vender producto
│   │   └── 📂 auth/                 # Autenticación
│   ├── 📂 services/                 # Servicios y lógica de negocio
│   │   ├── auth_service.dart        # Autenticación con Firebase
│   │   ├── product_service.dart     # Gestión de productos
│   │   ├── address_service.dart     # Gestión de direcciones
│   │   ├── comentario_service.dart  # Sistema de reseñas
│   │   ├── compra_service.dart      # Gestión de compras
│   │   ├── payment_method_service.dart # Métodos de pago
│   │   ├── notificacion_service.dart # Notificaciones
│   │   ├── seller_service.dart      # Servicios de vendedor
│   │   └── category_seed.dart       # Datos de categorías
│   ├── 📂 models/                   # Modelos de datos
│   │   ├── user.dart                # Modelo de usuario
│   │   ├── product.dart             # Modelo de producto
│   │   ├── cart_item.dart           # Elemento del carrito
│   │   ├── address.dart             # Modelo de dirección
│   │   ├── comentario.dart          # Modelo de comentario
│   │   ├── compra.dart              # Modelo de compra
│   │   ├── payment_method.dart      # Método de pago
│   │   ├── notificacion.dart        # Modelo de notificación
│   │   ├── seller.dart              # Modelo de vendedor
│   │   ├── category.dart            # Modelo de categoría
│   │   └── *.g.dart                 # Archivos generados
│   ├── 📂 providers/                # Gestión de estado
│   └── 📂 widgets/                  # Widgets reutilizables
├── 📂 assets/                       # Recursos estáticos
│   ├── 📂 images/                   # Imágenes de productos
│   ├── 📂 icon/                     # Íconos de la aplicación
│   ├── cities_latam.json            # Datos de ciudades
│   ├── states_latam.json            # Datos de estados
│   └── countries_latam.json         # Datos de países
├── 📂 android/                      # Configuración Android
├── 📂 ios/                          # Configuración iOS
├── 📂 web/                          # Configuración Web
├── 📂 test/                         # Pruebas unitarias
├── pubspec.yaml                     # Dependencias del proyecto
├── firebase.json                    # Configuración Firebase
├── .firebaserc                      # Configuración Firebase
├── storage.rules                    # Reglas de Firebase Storage
└── README.md                        # Documentación del proyecto


👤 Autor
Eloy Karin Rivadeneira Miller
