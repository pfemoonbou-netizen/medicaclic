import 'package:flutter/material.dart';
import '../config/supabase_config.dart';

class Doctor {
  final String id;
  final String name;
  final String specialty;
  final double rating;
  final String location;
  final double distance;
  final String about;
  final String image;
  Doctor({required this.id, required this.name, required this.specialty, required this.rating, required this.location, required this.distance, required this.about, required this.image});

  factory Doctor.fromMap(Map<String, dynamic> map) => Doctor(
        id: map['id'] as String,
        name: map['name'] as String,
        specialty: map['specialty'] as String,
        rating: (map['rating'] as num).toDouble(),
        location: map['location'] as String? ?? '',
        distance: (map['distance'] as num?)?.toDouble() ?? 0,
        about: map['about'] as String? ?? '',
        image: map['image'] as String? ?? '',
      );
}

class DoctorProvider extends ChangeNotifier {
  List<Doctor> _doctors = [];
  bool _isLoading = false;
  String? _error;

  DoctorProvider() {
    fetchDoctors();
  }

  List<Doctor> get doctors => _doctors;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<String> get specialties => _doctors.map((d) => d.specialty).toSet().toList();

  Future<void> fetchDoctors() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final rows = await supabase.from('doctors').select().order('rating', ascending: false);
      _doctors = (rows as List).map((row) => Doctor.fromMap(row as Map<String, dynamic>)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Doctor> getDoctorsBySpecialty(String specialty) => _doctors.where((d) => d.specialty == specialty).toList();

  Doctor? getDoctorById(String id) {
    try {
      return _doctors.firstWhere((d) => d.id == id);
    } catch (e) {
      return null;
    }
  }
}
