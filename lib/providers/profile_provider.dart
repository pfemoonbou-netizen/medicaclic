import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../config/supabase_config.dart';
import 'home_care_provider.dart';
import 'product_provider.dart';

class UserPost {
  final String id;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  const UserPost({required this.id, required this.content, this.imageUrl, required this.createdAt});

  factory UserPost.fromMap(Map<String, dynamic> map) => UserPost(
        id: map['id'] as String,
        content: map['content'] as String? ?? '',
        imageUrl: map['image_url'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}

class FamilyMember {
  final String id;
  final String name;
  final String relation;
  final double? weightKg;
  final double? heightCm;
  final String? bloodType;
  const FamilyMember({required this.id, required this.name, required this.relation, this.weightKg, this.heightCm, this.bloodType});

  factory FamilyMember.fromMap(Map<String, dynamic> map) => FamilyMember(
        id: map['id'] as String,
        name: map['name'] as String,
        relation: map['relation'] as String? ?? 'Autre',
        weightKg: (map['weight_kg'] as num?)?.toDouble(),
        heightCm: (map['height_cm'] as num?)?.toDouble(),
        bloodType: map['blood_type'] as String?,
      );
}

class ProfileProvider extends ChangeNotifier {
  bool isLoading = false;
  String? error;

  String name = '';
  String email = '';
  String role = 'utilisateur';
  String bio = '';
  String? photoUrl;
  String? bloodType;
  String? shopName;
  String? shopPhone;
  String? shopBio;
  double? weightKg;
  double? heightCm;
  bool isCreator = false;

  CareProvider? providerInfo;
  List<UserPost> posts = [];
  List<FamilyMember> familyMembers = [];
  List<Product> myProducts = [];
  List<ProductRequest> myRequests = [];

  bool get isPro => role == 'prestataire' || role == 'vendeur' || isCreator;
  String get userId => supabase.auth.currentUser!.id;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final uid = supabase.auth.currentUser?.id;
      if (uid == null) throw 'Non connecté';

      final profile = await supabase.from('profiles').select().eq('id', uid).single();
      name = profile['name'] as String? ?? '';
      email = profile['email'] as String? ?? '';
      role = profile['role'] as String? ?? 'utilisateur';
      bio = profile['bio'] as String? ?? '';
      photoUrl = profile['photo_url'] as String?;
      bloodType = profile['blood_type'] as String?;
      shopName = profile['shop_name'] as String?;
      shopPhone = profile['shop_phone'] as String?;
      shopBio = profile['shop_bio'] as String?;
      weightKg = (profile['weight_kg'] as num?)?.toDouble();
      heightCm = (profile['height_cm'] as num?)?.toDouble();
      isCreator = profile['is_creator'] as bool? ?? false;

      if (role == 'prestataire') {
        final rows = await supabase.from('home_care_providers').select().eq('user_id', uid).limit(1);
        if ((rows as List).isNotEmpty) providerInfo = CareProvider.fromMap(rows.first as Map<String, dynamic>);
      } else {
        providerInfo = null;
      }

      if (role != 'prestataire' && role != 'vendeur') {
        final memberRows = await supabase.from('family_members').select().eq('user_id', uid).order('created_at');
        familyMembers = (memberRows as List).map((row) => FamilyMember.fromMap(row as Map<String, dynamic>)).toList();
      } else {
        familyMembers = [];
      }

      if (role == 'vendeur') {
        final productRows = await supabase.from('products').select().eq('seller_id', uid).order('name');
        myProducts = (productRows as List).map((row) => Product.fromMap(row as Map<String, dynamic>)).toList();
        final requestRows = await supabase.from('product_requests').select().eq('seller_id', uid).order('created_at', ascending: false);
        myRequests = (requestRows as List).map((row) => ProductRequest.fromMap(row as Map<String, dynamic>)).toList();
      } else {
        myProducts = [];
        myRequests = [];
      }

      final postRows = await supabase.from('user_posts').select().eq('user_id', uid).order('created_at', ascending: false);
      posts = (postRows as List).map((row) => UserPost.fromMap(row as Map<String, dynamic>)).toList();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String> _uploadImage(XFile file, String prefix) async {
    final ext = file.path.split('.').last;
    final path = '$userId/${prefix}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final bytes = await file.readAsBytes();
    await supabase.storage.from('profile-photos').uploadBinary(path, bytes);
    return supabase.storage.from('profile-photos').getPublicUrl(path);
  }

  Future<void> updateProfile({
    required String name,
    required String bio,
    XFile? photo,
    String? shopName,
    String? shopPhone,
    String? shopBio,
  }) async {
    String? newPhotoUrl;
    if (photo != null) newPhotoUrl = await _uploadImage(photo, 'profile');
    await supabase.from('profiles').update({
      'name': name,
      'bio': bio,
      if (newPhotoUrl != null) 'photo_url': newPhotoUrl,
      if (shopName != null) 'shop_name': shopName,
      if (shopPhone != null) 'shop_phone': shopPhone,
      if (shopBio != null) 'shop_bio': shopBio,
    }).eq('id', userId);
    this.name = name;
    this.bio = bio;
    if (newPhotoUrl != null) photoUrl = newPhotoUrl;
    if (shopName != null) this.shopName = shopName;
    if (shopPhone != null) this.shopPhone = shopPhone;
    if (shopBio != null) this.shopBio = shopBio;
    notifyListeners();
  }

  Future<void> updateBloodType(String value) async {
    await supabase.from('profiles').update({'blood_type': value}).eq('id', userId);
    bloodType = value;
    notifyListeners();
  }

  Future<void> updateStats({double? weightKg, double? heightCm}) async {
    await supabase.from('profiles').update({
      'weight_kg': weightKg,
      'height_cm': heightCm,
    }).eq('id', userId);
    this.weightKg = weightKg;
    this.heightCm = heightCm;
    notifyListeners();
  }

  Future<void> addFamilyMember({required String name, required String relation, double? weightKg, double? heightCm, String? bloodType}) async {
    await supabase.from('family_members').insert({
      'user_id': userId,
      'name': name,
      'relation': relation,
      'weight_kg': weightKg,
      'height_cm': heightCm,
      'blood_type': bloodType,
    });
    await load();
  }

  Future<void> deleteFamilyMember(String id) async {
    await supabase.from('family_members').delete().eq('id', id);
    familyMembers.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  Future<void> becomeCreator() async {
    await supabase.from('profiles').update({'is_creator': true}).eq('id', userId);
    isCreator = true;
    notifyListeners();
  }

  int get pendingRequestsCount => myRequests.where((r) => r.status == 'pending').length;

  Future<void> addProduct({required String name, required String category, required String description, required double price, XFile? image}) async {
    String? imageUrl;
    if (image != null) imageUrl = await _uploadImage(image, 'product');
    await supabase.from('products').insert({
      'seller_id': userId,
      'seller': shopName ?? name,
      'phone': shopPhone ?? '',
      'name': name,
      'brand': shopName ?? '',
      'category': category,
      'description': description,
      'price': price,
      'image': imageUrl,
      'rating': 0,
      'review_count': 0,
    });
    await load();
  }

  Future<void> deleteProduct(String id) async {
    await supabase.from('products').delete().eq('id', id);
    myProducts.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  Future<void> respondToRequest(String id, {required bool accept}) async {
    await supabase.from('product_requests').update({'status': accept ? 'accepted' : 'declined'}).eq('id', id);
    await load();
  }

  Future<void> addPost({required String content, XFile? image}) async {
    String? imageUrl;
    if (image != null) imageUrl = await _uploadImage(image, 'post');
    await supabase.from('user_posts').insert({
      'user_id': userId,
      'content': content,
      'image_url': imageUrl,
    });
    await load();
  }

  Future<void> deletePost(String id) async {
    await supabase.from('user_posts').delete().eq('id', id);
    posts.removeWhere((p) => p.id == id);
    notifyListeners();
  }
}

