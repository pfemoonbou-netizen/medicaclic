import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:supabase_flutter/supabase_flutter.dart' as supa show User;
import '../config/supabase_config.dart';

class User {
  final String id;
  final String email;
  final String name;
  final String role;
  User({required this.id, required this.email, required this.name, this.role = 'utilisateur'});
  bool get isProvider => role == 'prestataire';
}

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider() {
    final session = supabase.auth.currentSession;
    if (session != null) _user = _mapUser(session.user);
    supabase.auth.onAuthStateChange.listen((data) {
      final authUser = data.session?.user;
      _user = authUser == null ? null : _mapUser(authUser);
      notifyListeners();
    });
  }

  User _mapUser(supa.User authUser) {
    return User(
      id: authUser.id,
      email: authUser.email ?? '',
      name: (authUser.userMetadata?['name'] as String?) ?? '',
      role: (authUser.userMetadata?['role'] as String?) ?? 'utilisateur',
    );
  }

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      if (email.isEmpty || password.isEmpty) {
        throw 'Veuillez remplir tous les champs';
      }
      final res = await supabase.auth.signInWithPassword(email: email, password: password);
      if (res.user == null) throw 'Connexion impossible';
      _user = _mapUser(res.user!);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e is AuthException ? e.message : e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signup(
    String name,
    String email,
    String password, {
    String role = 'utilisateur',
    String? providerCategoryId,
    String? providerSpecialty,
    String? providerPhone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      if (name.isEmpty || email.isEmpty || password.isEmpty) {
        throw 'Veuillez remplir tous les champs';
      }
      if (role == 'prestataire' && (providerCategoryId == null || providerSpecialty == null || providerSpecialty.isEmpty || providerPhone == null || providerPhone.isEmpty)) {
        throw 'Veuillez renseigner votre spécialité, catégorie et téléphone';
      }
      final res = await supabase.auth.signUp(email: email, password: password, data: {'name': name, 'role': role});
      if (res.user == null) throw 'Inscription impossible';
      if (role == 'prestataire') {
        await supabase.from('home_care_providers').insert({
          'user_id': res.user!.id,
          'category_id': providerCategoryId,
          'name': name,
          'specialty': providerSpecialty,
          'phone': providerPhone,
        });
      }
      _user = User(id: res.user!.id, email: email, name: name, role: role);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e is AuthException ? e.message : e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await supabase.auth.signOut();
    _user = null;
    _errorMessage = null;
    notifyListeners();
  }
}
