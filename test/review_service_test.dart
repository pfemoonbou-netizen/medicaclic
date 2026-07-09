import 'package:flutter_test/flutter_test.dart';
import 'package:lincoo_flutter/services/review_service.dart';

void main() {
  group('ReviewService payloads', () {
    test('builds product review payload with rating, comment and photos', () {
      final payload = ReviewService.buildProductReviewPayload(
        buyerId: 'buyer-1',
        storeId: 'store-1',
        orderId: 'order-1',
        productId: 'product-1',
        productName: 'Robe été',
        rating: 5,
        comment: 'Excellent produit',
        photos: ['https://example.com/photo1.jpg'],
      );

      expect(payload['buyer_id'], 'buyer-1');
      expect(payload['product_id'], 'product-1');
      expect(payload['rating'], 5);
      expect(payload['comment'], 'Excellent produit');
      expect(payload['photos'], ['https://example.com/photo1.jpg']);
    });

    test('builds store review payload with seller rating and comment', () {
      final payload = ReviewService.buildStoreReviewPayload(
        buyerId: 'buyer-1',
        storeId: 'store-1',
        orderId: 'order-1',
        rating: 4,
        comment: 'Livraison rapide',
        photos: ['https://example.com/photo2.jpg'],
      );

      expect(payload['reviewer_id'], 'buyer-1');
      expect(payload['store_id'], 'store-1');
      expect(payload['rating'], 4);
      expect(payload['comment'], 'Livraison rapide');
      expect(payload['photos'], ['https://example.com/photo2.jpg']);
    });
  });
}
