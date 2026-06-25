import 'package:flutter/material.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String? image;
  final double rating;
  final int reviewCount;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.image,
    required this.rating,
    this.reviewCount = 0,
  });
}

class ProductProvider extends ChangeNotifier {
  final List<Product> _products = [
    Product(
      id: '1',
      name: 'OBH Combi',
      description: 'Sirop contre la toux avec paracétamol',
      price: 9.99,
      image: '💊',
      rating: 4.0,
      reviewCount: 45,
    ),
    Product(
      id: '2',
      name: 'Panadol',
      description: 'Analgésique et antipyrétique efficace',
      price: 15.99,
      image: '💊',
      rating: 4.5,
      reviewCount: 120,
    ),
    Product(
      id: '3',
      name: 'Bodrex Herbal',
      description: 'Remède naturel pour le rhume',
      price: 7.99,
      image: '🌿',
      rating: 4.2,
      reviewCount: 78,
    ),
    Product(
      id: '4',
      name: 'Betadine',
      description: 'Antiseptique et désinfectant',
      price: 6.99,
      image: '🧴',
      rating: 4.3,
      reviewCount: 95,
    ),
    Product(
      id: '5',
      name: 'Bodrexin',
      description: 'Décongestionnant nasal',
      price: 7.99,
      image: '🌡️',
      rating: 4.1,
      reviewCount: 67,
    ),
  ];

  List<Product> get products => _products;

  Product? getProductById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }
}
