import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lincoo_flutter/screens/product_details_page.dart';

void main() {
  testWidgets('Product details page shows product information from route args', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  settings: const RouteSettings(
                    arguments: {
                      'id': 'test-product',
                      'name': 'Produit de test',
                      'description': 'Description de test',
                      'price': 1500.0,
                      'images': ['assets/images/product.jpg'],
                      'stores': {
                        'store_name': 'Boutique test',
                        'id': 'store-1',
                        'is_verified': true,
                      },
                    },
                  ),
                  builder: (_) => const ProductDetailsPage(),
                ),
              );
            },
            child: const Text('Open product'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open product'));
    await tester.pumpAndSettle();

    expect(find.text('Produit de test'), findsOneWidget);
  });

  testWidgets('Product details page lets users select fallback size variants', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  settings: const RouteSettings(
                    arguments: {
                      'id': 'variant-product',
                      'name': 'Produit avec tailles',
                      'description': 'Description',
                      'price': 2000.0,
                      'images': ['assets/images/product.jpg'],
                      'sizes': ['S', 'M', 'L'],
                      'stores': {
                        'store_name': 'Boutique test',
                        'id': 'store-1',
                        'is_verified': true,
                      },
                    },
                  ),
                  builder: (_) => const ProductDetailsPage(),
                ),
              );
            },
            child: const Text('Open fallback product'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open fallback product'));
    await tester.pumpAndSettle();

    expect(find.text('Taille'), findsOneWidget);
    final sizeFinder = find.text('M').first;
    await tester.ensureVisible(sizeFinder);
    await tester.tap(sizeFinder);
    await tester.pump();

    expect(find.text('M'), findsWidgets);
  });
}
