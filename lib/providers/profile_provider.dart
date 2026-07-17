import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../config/supabase_config.dart';
import 'home_care_provider.dart';

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

  CareProvider? providerInfo;
  Map<String, int> medicalCounts = {};
  List<UserPost> posts = [];
  List<FamilyMember> familyMembers = [];

  bool get isPro => role == 'prestataire' || role == 'vendeur';
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

      if (role == 'prestataire') {
        final rows = await supabase.from('home_care_providers').select().eq('user_id', uid).limit(1);
        if ((rows as List).isNotEmpty) providerInfo = CareProvider.fromMap(rows.first as Map<String, dynamic>);
      } else {
        providerInfo = null;
      }

      if (role != 'prestataire' && role != 'vendeur') {
        final records = await supabase.from('medical_records').select('category').eq('user_id', uid);
        medicalCounts = {};
        for (final row in (records as List)) {
          final cat = row['category'] as String;
          medicalCounts[cat] = (medicalCounts[cat] ?? 0) + 1;
        }

        final memberRows = await supabase.from('family_members').select().eq('user_id', uid).order('created_at');
        familyMembers = (memberRows as List).map((row) => FamilyMember.fromMap(row as Map<String, dynamic>)).toList();
      } else {
        familyMembers = [];
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

  Future<void> updateProfile({required String name, required String bio, XFile? photo}) async {
    String? newPhotoUrl;
    if (photo != null) newPhotoUrl = await _uploadImage(photo, 'profile');
    await supabase.from('profiles').update({
      'name': name,
      'bio': bio,
      if (newPhotoUrl != null) 'photo_url': newPhotoUrl,
    }).eq('id', userId);
    this.name = name;
    this.bio = bio;
    if (newPhotoUrl != null) photoUrl = newPhotoUrl;
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

  Future<void> becomePrestataire({required String categoryId, required String specialty, required String phone}) async {
    await supabase.from('profiles').update({'role': 'prestataire'}).eq('id', userId);
    await supabase.from('home_care_providers').insert({
      'user_id': userId,
      'category_id': categoryId,
      'name': name,
      'specialty': specialty,
      'phone': phone,
    });
    await load();
  }

  Future<void> becomeVendeur({required String shopName, required String shopPhone, required String shopBio}) async {
    await supabase.from('profiles').update({
      'role': 'vendeur',
      'shop_name': shopName,
      'shop_phone': shopPhone,
      'shop_bio': shopBio,
    }).eq('id', userId);
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

