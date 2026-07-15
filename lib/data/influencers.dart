import 'package:flutter/material.dart';

/// Données centralisées des comptes influenceurs / marques mis en avant.
/// Utilisées par la barre de stories, le fil de publications et la page profil.
class InfluencerInfo {
  final String username;
  final Color color;
  final String? avatar; // chemin asset ou null (fallback initiale)
  final String category;
  final String bio;
  final int posts;
  final int followers;
  final int following;
  final List<String> gridImages; // photos réelles pour la grille (peut être vide)
  final bool verified;
  const InfluencerInfo({
    required this.username,
    required this.color,
    this.avatar,
    required this.category,
    required this.bio,
    required this.posts,
    required this.followers,
    required this.following,
    this.gridImages = const [],
    this.verified = false,
  });
}

const Map<String, InfluencerInfo> kInfluencers = {
  'forma': InfluencerInfo(
    username: 'forma',
    color: Color(0xFF2E4636),
    avatar: 'assets/images/influencers/forma_logo.jpg',
    category: 'Marque · Complément alimentaire',
    bio: "Détox naturel 🌿 Perte de poids visible et durable. Bio & certifié. Plonge dans l'univers de Forma.",
    posts: 87,
    followers: 12400,
    following: 12,
    gridImages: ['assets/images/influencers/forma_pub2.jpg', 'assets/images/influencers/forma_pub1.jpg'],
    verified: true,
  ),
  'dr.sarah': InfluencerInfo(
    username: 'dr.sarah',
    color: Color(0xFFE57399),
    avatar: 'assets/images/influencers/influencer3.jpg',
    category: 'Santé · Gynécologie',
    bio: "Conseils grossesse & santé de la femme 💗 Prenez soin de vous et de bébé.",
    posts: 156,
    followers: 8900,
    following: 210,
    verified: true,
  ),
  'dr.karim': InfluencerInfo(
    username: 'dr.karim',
    color: Color(0xFF4C9BF5),
    avatar: 'assets/images/influencers/influencer2.jpg',
    category: 'Santé · Médecine générale',
    bio: "Astuces bien-être & prévention au quotidien 🩺 Bougez, mangez sain, dormez bien.",
    posts: 203,
    followers: 15200,
    following: 180,
    verified: true,
  ),
  'amine.h': InfluencerInfo(
    username: 'amine.h',
    color: Color(0xFF7C6BE0),
    avatar: 'assets/images/influencers/influencer1.jpg',
    category: 'Nutrition · Fitness',
    bio: "Coach nutrition 🥗 Recettes équilibrées et motivation quotidienne.",
    posts: 98,
    followers: 6700,
    following: 340,
    gridImages: ['assets/images/influencers/post_steak.jpg', 'assets/images/influencers/post_bowl.jpg'],
  ),
  'mama.care': InfluencerInfo(
    username: 'mama.care',
    color: Color(0xFF35B8A6),
    avatar: null,
    category: 'Maternité · Bébé',
    bio: "Tout pour maman & bébé 🤱 Portage, allaitement, sommeil.",
    posts: 74,
    followers: 4300,
    following: 120,
  ),
  'nadia.fit': InfluencerInfo(
    username: 'nadia.fit',
    color: Color(0xFFF2994A),
    avatar: null,
    category: 'Fitness · Bien-être',
    bio: "Remise en forme à la maison 💪 Programmes simples et efficaces.",
    posts: 130,
    followers: 9800,
    following: 260,
    gridImages: [
      'assets/images/influencers/post_plank.jpg',
      'assets/images/influencers/post_yoga.jpg',
      'assets/images/influencers/post_water.jpg',
    ],
  ),
  'bébé.plus': InfluencerInfo(
    username: 'bébé.plus',
    color: Color(0xFFEB5757),
    avatar: null,
    category: 'Puériculture',
    bio: "Conseils & produits pour le bien-être de bébé 👶",
    posts: 61,
    followers: 3500,
    following: 90,
  ),
  'california.gym': InfluencerInfo(
    username: 'california.gym',
    color: Color(0xFF1E4C8C),
    avatar: null,
    category: 'Salle de sport · Fitness',
    bio: "California Gym 💪 Musculation, cardio et coaching. Abonnements mensuels, trimestriels, semestriels et annuels.",
    posts: 45,
    followers: 7800,
    following: 30,
    gridImages: ['assets/images/influencers/gym_subscription.jpg', 'assets/images/influencers/gym_equipment.jpg'],
  ),
  'algiers.trail': InfluencerInfo(
    username: 'algiers.trail',
    color: Color(0xFF2F9E44),
    avatar: null,
    category: 'Événement sportif',
    bio: "Algiers Urban Trail 🏃 Course urbaine dans les rues d'Alger. Rejoins l'aventure !",
    posts: 12,
    followers: 2100,
    following: 8,
    gridImages: ['assets/images/influencers/algiers_trail.jpg'],
  ),
};

InfluencerInfo? influencerByName(String username) => kInfluencers[username];

String formatCount(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
  return '$n';
}
