import 'package:flutter/material.dart';
import '../config/supabase_config.dart';

class ServiceCategory {
  final String id;
  final String name;
  final String subtitle;
  final int priceFrom;
  final IconData icon;
  final Color color;
  const ServiceCategory({required this.id, required this.name, required this.subtitle, required this.priceFrom, required this.icon, required this.color});

  factory ServiceCategory.fromMap(Map<String, dynamic> map) => ServiceCategory(
        id: map['id'] as String,
        name: map['name'] as String,
        subtitle: map['subtitle'] as String? ?? '',
        priceFrom: (map['price_from'] as num?)?.toInt() ?? 0,
        icon: _iconByName(map['icon_name'] as String?),
        color: _colorFromHex(map['color_hex'] as String?),
      );

  static IconData _iconByName(String? name) {
    switch (name) {
      case 'person_outline':
        return Icons.person_outline;
      case 'medical_services_outlined':
        return Icons.medical_services_outlined;
      case 'self_improvement_outlined':
        return Icons.self_improvement_outlined;
      case 'groups_outlined':
        return Icons.groups_outlined;
      case 'bloodtype_outlined':
        return Icons.bloodtype_outlined;
      case 'favorite_outline':
        return Icons.favorite_outline;
      default:
        return Icons.medical_services_outlined;
    }
  }

  static Color _colorFromHex(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF1AA88F);
    final cleaned = hex.replaceFirst('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }
}

class CareProvider {
  final String id;
  final String name;
  final String categoryId;
  final String specialty;
  final int pricePerVisit;
  final double rating;
  final int reviewCount;
  final double distanceKm;
  final String etaRange;
  final int yearsExperience;
  final List<String> tags;
  final bool available;
  final String phone;
  final String address;
  final String photoUrl;
  const CareProvider({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.specialty,
    required this.pricePerVisit,
    required this.rating,
    required this.reviewCount,
    required this.distanceKm,
    required this.etaRange,
    required this.yearsExperience,
    required this.tags,
    required this.available,
    required this.phone,
    required this.address,
    required this.photoUrl,
  });

  factory CareProvider.fromMap(Map<String, dynamic> map) => CareProvider(
        id: map['id'] as String,
        name: map['name'] as String,
        categoryId: map['category_id'] as String,
        specialty: map['specialty'] as String? ?? '',
        pricePerVisit: (map['price_per_visit'] as num?)?.toInt() ?? 0,
        rating: (map['rating'] as num?)?.toDouble() ?? 0,
        reviewCount: (map['review_count'] as num?)?.toInt() ?? 0,
        distanceKm: (map['distance_km'] as num?)?.toDouble() ?? 0,
        etaRange: map['eta_range'] as String? ?? '',
        yearsExperience: (map['years_experience'] as num?)?.toInt() ?? 0,
        tags: (map['tags'] as List?)?.map((t) => t.toString()).toList() ?? [],
        available: map['available'] as bool? ?? true,
        phone: map['phone'] as String? ?? '',
        address: map['address'] as String? ?? '',
        photoUrl: map['photo_url'] as String? ?? '',
      );
}

class HomeCareProvider extends ChangeNotifier {
  List<ServiceCategory> categories = [];
  List<CareProvider> providers = [];
  bool isLoading = false;
  String? error;

  HomeCareProvider() {
    fetchAll();
  }

  Future<void> fetchAll() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        supabase.from('home_care_categories').select(),
        supabase.from('home_care_providers').select().order('rating', ascending: false),
      ]);
      categories = (results[0] as List).map((row) => ServiceCategory.fromMap(row as Map<String, dynamic>)).toList();
      providers = (results[1] as List).map((row) => CareProvider.fromMap(row as Map<String, dynamic>)).toList();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  List<CareProvider> providersFor(String categoryId) => categoryId == 'tous' ? providers : providers.where((p) => p.categoryId == categoryId).toList();

  ServiceCategory categoryById(String id) => categories.firstWhere((c) => c.id == id);

  Future<void> createBooking({
    required String providerId,
    required String serviceType,
    required String bookingDate,
    required String timeSlot,
    required String address,
    String note = '',
  }) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw 'Vous devez être connecté pour réserver.';
    await supabase.from('home_care_bookings').insert({
      'user_id': userId,
      'provider_id': providerId,
      'service_type': serviceType,
      'booking_date': bookingDate,
      'time_slot': timeSlot,
      'address': address,
      'note': note,
    });
  }
}
