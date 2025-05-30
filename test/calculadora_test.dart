import 'package:flutter_test/flutter_test.dart';

// Funcion a probar
int suma(int a, int b) {
  return a + b;
}

void main() {
  test('Suma de dos numeros', () {
    // Arrange
    int a = 2;
    int b = 3;

    // Act
    int resultado = suma(a, b);

    // Assert
    expect(resultado, 5);
  });

  test('Suma de numeros negativos', () {
    // Arrange
    int a = -2;
    int b = -3;

    // Act
    int resultado = suma(a, b);

    // Assert
    expect(resultado, -5);
  });

  test('Suma de un numero positivo y uno negativo', () {
    // Arrange
    int a = 5;
    int b = -3;

    // Act
    int resultado = suma(a, b);

    // Assert
    expect(resultado, 2);
  });
}