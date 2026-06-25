import 'package:flutter/material.dart';

class Doctor {
  final String id;
  final String name;
  final String specialty;
  final double rating;
  final String location;
  final double distance;
  final String about;
  final String image;

  Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.rating,
    required this.location,
    required this.distance,
    required this.about,
    required this.image,
  });
}

class DoctorProvider extends ChangeNotifier {
  final List<Doctor> _doctors = [
    Doctor(
      id: '1',
      name: 'Dr. Marcus Horizon',
      specialty: 'Cardiologue',
      rating: 4.7,
      location: 'Alexandria, VA',
      distance: 0.8,
      about: 'Spécialiste en cardiologie avec 15 ans d\'expérience',
      image: '👨‍⚕️',
    ),
    Doctor(
      id: '2',
      name: 'Dr. Maria Dona',
      specialty: 'Généraliste',
      rating: 4.5,
      location: 'Alexandria, VA',
      distance: 1.2,
      about: 'Médecin généraliste diplômée',
      image: '👩‍⚕️',
    ),
    Doctor(
      id: '3',
      name: 'Dr. Stevi',
      specialty: 'Dentiste',
      rating: 4.3,
      location: 'Alexandria, VA',
      distance: 0.95,
      about: 'Dentiste avec expérience en orthodontie',
      image: '👨‍⚕️',
    ),
    Doctor(
      id: '4',
      name: 'Dr. Carly Carl',
      specialty: 'Pneumologue',
      rating: 4.6,
      location: 'Alexandria, VA',
      distance: 1.5,
      about: 'Spécialiste en maladies respiratoires',
      image: '👩‍⚕️',
    ),
    Doctor(
      id: '5',
      name: 'Dr. Miranda',
      specialty: 'Dermatologue',
      rating: 4.4,
      location: 'Alexandria, VA',
      distance: 1.1,
      about: 'Spécialiste en dermatologie et cosmétologie',
      image: '👩‍⚕️',
    ),
  ];

  List<Doctor> get doctors => _doctors;

  List<String> get specialties => [
    'Généraliste',
    'Cardiologue',
    'Dentiste',
    'Pneumologue',
    'Dermatologue',
  ];

  List<Doctor> getDoctorsBySpecialty(String specialty) {
    return _doctors.where((d) => d.specialty == specialty).toList();
  }

  Doctor? getDoctorById(String id) {
    try {
      return _doctors.firstWhere((d) => d.id == id);
    } catch (e) {
      return null;
    }
  }
}
