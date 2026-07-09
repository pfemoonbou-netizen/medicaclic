import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class ReviewService {
  static final SupabaseClient _client = Supabase.instance.client;

  static Map<String, dynamic> buildProductReviewPayload({
    required String buyerId,
    required String? storeId,
    required String? orderId,
    required String? productId,
    required String productName,
    required int rating,
    String? comment,
    List<String>? photos,
  }) {
    return {
      'buyer_id': buyerId,
      'store_id': storeId,
      'order_id': orderId,
      'product_id': productId,
      'product_name': productName,
      'rating': rating,
      'comment': comment?.trim().isNotEmpty == true ? comment!.trim() : null,
      'photos': photos ?? <String>[],
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  static Map<String, dynamic> buildStoreReviewPayload({
    required String buyerId,
    required String? storeId,
    required String? orderId,
    required int rating,
    String? comment,
    List<String>? photos,
  }) {
    return {
      'reviewer_id': buyerId,
      'store_id': storeId,
      'order_id': orderId,
      'rating': rating,
      'comment': comment?.trim().isNotEmpty == true ? comment!.trim() : null,
      'photos': photos ?? <String>[],
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  static Future<List<String>> uploadReviewPhotos(List<dynamic> files) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Utilisateur non connecté');
    }

    final urls = <String>[];
    for (final file in files) {
      try {
        Uint8List bytes;
        String fileName;
        if (file is XFile) {
          bytes = await file.readAsBytes();
          fileName = (file.name.isNotEmpty) ? file.name : '${DateTime.now().millisecondsSinceEpoch}.jpg';
        } else if (file is Uint8List) {
          bytes = file;
          fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        } else {
          final dynamic f = file;
          bytes = await f.readAsBytes();
          final pathStr = (f.path as String?) ?? '';
          final parts = pathStr.split(RegExp(r'[\\/]+'));
          fileName = parts.isNotEmpty && parts.last.isNotEmpty ? parts.last : '${DateTime.now().millisecondsSinceEpoch}.jpg';
        }

        final path = 'reviews/$userId/$fileName';
        try {
          await _client.storage.from('avatars').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
          );
          urls.add(_client.storage.from('avatars').getPublicUrl(path));
        } catch (_) {
          try {
            await _client.storage.from('images').uploadBinary(
              path,
              bytes,
              fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
            );
            urls.add(_client.storage.from('images').getPublicUrl(path));
          } catch (_) {
            // Ignore upload failure and keep the review without photos.
          }
        }
      } catch (_) {
        // ignore per-file errors
      }
    }
    return urls;
  }

  static Future<void> submitProductReview({
    required String? storeId,
    required String? orderId,
    required String? productId,
    required String productName,
    required int rating,
    String? comment,
    List<dynamic>? photos,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('Aucun utilisateur connecté');
    }

    final photoUrls = photos != null && photos.isNotEmpty ? await uploadReviewPhotos(photos) : <String>[];
    final payload = buildProductReviewPayload(
      buyerId: user.id,
      storeId: storeId,
      orderId: orderId,
      productId: productId,
      productName: productName,
      rating: rating,
      comment: comment,
      photos: photoUrls,
    );

    await _client.from('product_reviews').insert(payload);
  }

  static Future<void> submitStoreReview({
    required String? storeId,
    required String? orderId,
    required int rating,
    String? comment,
    List<dynamic>? photos,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('Aucun utilisateur connecté');
    }

    final photoUrls = photos != null && photos.isNotEmpty ? await uploadReviewPhotos(photos) : <String>[];
    final payload = buildStoreReviewPayload(
      buyerId: user.id,
      storeId: storeId,
      orderId: orderId,
      rating: rating,
      comment: comment,
      photos: photoUrls,
    );

    await _client.from('store_reviews').insert(payload);
  }
}
