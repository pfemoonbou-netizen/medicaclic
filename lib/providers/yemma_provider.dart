import 'package:flutter/material.dart';
import '../config/supabase_config.dart';

class PainEntry {
  final String? id;
  final DateTime date;
  final String location;
  final String type;
  final String duration;
  final int severity;
  PainEntry({this.id, required this.date, required this.location, required this.type, required this.duration, required this.severity});

  factory PainEntry.fromMap(Map<String, dynamic> map) => PainEntry(
        id: map['id'] as String?,
        date: DateTime.parse(map['entry_date'] as String),
        location: map['location'] as String,
        type: map['type'] as String,
        duration: map['duration'] as String,
        severity: (map['severity'] as num).toInt(),
      );
}

class VaccineEntry {
  final String? id;
  final String name;
  final String ageLabel;
  final DateTime date;
  final bool done;
  final bool dueSoon;
  VaccineEntry({this.id, required this.name, required this.ageLabel, required this.date, required this.done, this.dueSoon = false});

  factory VaccineEntry.fromMap(Map<String, dynamic> map) => VaccineEntry(
        id: map['id'] as String?,
        name: map['name'] as String,
        ageLabel: map['age_label'] as String,
        date: DateTime.parse(map['due_date'] as String),
        done: map['done'] as bool? ?? false,
        dueSoon: map['due_soon'] as bool? ?? false,
      );
}

class CommunityPost {
  final String? id;
  final String author;
  final DateTime createdAt;
  final String question;
  final int likes;
  final int replies;
  CommunityPost({this.id, required this.author, required this.createdAt, required this.question, required this.likes, required this.replies});

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    return 'il y a ${diff.inDays}j';
  }

  factory CommunityPost.fromMap(Map<String, dynamic> map) => CommunityPost(
        id: map['id'] as String?,
        author: map['author_name'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        question: map['question'] as String,
        likes: (map['likes'] as num?)?.toInt() ?? 0,
        replies: (map['replies'] as num?)?.toInt() ?? 0,
      );
}

class YemmaProvider extends ChangeNotifier {
  bool isLoading = false;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // Évite le crash "used after being disposed" quand une requête réseau
  // se termine après la fermeture de l'écran Yemma.
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  List<PainEntry> _painEntries = [];
  final List<String> painFilters = ['Tout', 'Dos', 'Ventre', 'Tête', 'Jambes'];
  String _painFilter = 'Tout';

  String babyName = '';
  String babyAgeLabel = '';
  DateTime babyBirthDate = DateTime.now();
  String babyGender = 'Fille';
  double babyWeightKg = 0;
  double babyWeightDeltaKg = 0;
  double babyHeightCm = 0;
  double babyHeightDeltaCm = 0;
  String babyHeadCircumference = '';
  bool hasBabyProfile = false;

  List<VaccineEntry> vaccines = [];

  int pregnancyWeek = 0;
  String pregnancyTrimester = '';
  double babySizeCm = 0;
  double babyWeightKgEstimate = 0;
  String nextAppointmentTitle = '';
  String nextAppointmentDoctor = '';
  DateTime? nextAppointmentDate;
  bool hasPregnancyInfo = false;

  final List<String> allSymptoms = ['Nausées', 'Fatigue', 'Dos douloureux', 'Oedèmes', 'Brûlures'];
  final Set<String> _selectedSymptoms = {};

  List<CommunityPost> communityPosts = [];

  YemmaProvider() {
    fetchAll();
  }

  String? get _userId => supabase.auth.currentUser?.id;

  String get painFilter => _painFilter;
  void setPainFilter(String f) {
    _painFilter = f;
    notifyListeners();
  }

  List<PainEntry> get filteredPainEntries => _painFilter == 'Tout' ? _painEntries : _painEntries.where((e) => e.location == _painFilter).toList();

  int get vaccinesDone => vaccines.where((v) => v.done).length;

  Set<String> get selectedSymptoms => _selectedSymptoms;

  Future<void> fetchAll() async {
    final userId = _userId;
    if (userId == null) return;
    isLoading = true;
    notifyListeners();
    try {
      final today = DateTime.now().toIso8601String().split('T').first;
      final results = await Future.wait([
        supabase.from('pain_entries').select().eq('user_id', userId).order('entry_date', ascending: false),
        supabase.from('baby_profiles').select().eq('user_id', userId).maybeSingle(),
        supabase.from('vaccines').select().eq('user_id', userId).order('due_date'),
        supabase.from('pregnancy_info').select().eq('user_id', userId).maybeSingle(),
        supabase.from('daily_symptoms').select('symptom').eq('user_id', userId).eq('log_date', today),
        supabase.from('community_posts').select().order('created_at', ascending: false),
      ]);

      _painEntries = (results[0] as List).map((row) => PainEntry.fromMap(row as Map<String, dynamic>)).toList();

      final baby = results[1] as Map<String, dynamic>?;
      if (baby != null) {
        hasBabyProfile = true;
        babyName = baby['name'] as String;
        babyBirthDate = DateTime.parse(baby['birth_date'] as String);
        babyAgeLabel = _ageLabel(babyBirthDate);
        babyGender = baby['gender'] as String? ?? 'Fille';
        babyWeightKg = (baby['weight_kg'] as num?)?.toDouble() ?? 0;
        babyWeightDeltaKg = (baby['weight_delta_kg'] as num?)?.toDouble() ?? 0;
        babyHeightCm = (baby['height_cm'] as num?)?.toDouble() ?? 0;
        babyHeightDeltaCm = (baby['height_delta_cm'] as num?)?.toDouble() ?? 0;
        babyHeadCircumference = baby['head_circumference'] as String? ?? '';
      }

      vaccines = (results[2] as List).map((row) => VaccineEntry.fromMap(row as Map<String, dynamic>)).toList();

      final pregnancy = results[3] as Map<String, dynamic>?;
      if (pregnancy != null) {
        hasPregnancyInfo = true;
        pregnancyWeek = (pregnancy['week'] as num).toInt();
        pregnancyTrimester = pregnancy['trimester'] as String;
        babySizeCm = (pregnancy['baby_size_cm'] as num?)?.toDouble() ?? 0;
        babyWeightKgEstimate = (pregnancy['baby_weight_kg'] as num?)?.toDouble() ?? 0;
        nextAppointmentTitle = pregnancy['appointment_title'] as String? ?? '';
        nextAppointmentDoctor = pregnancy['appointment_doctor'] as String? ?? '';
        final apptDate = pregnancy['appointment_date'] as String?;
        nextAppointmentDate = apptDate == null ? null : DateTime.parse(apptDate);
      }

      _selectedSymptoms.clear();
      for (final row in results[4] as List) {
        _selectedSymptoms.add((row as Map<String, dynamic>)['symptom'] as String);
      }

      communityPosts = (results[5] as List).map((row) => CommunityPost.fromMap(row as Map<String, dynamic>)).toList();
    } catch (_) {
      // Garde les données déjà chargées si la requête échoue (ex: hors-ligne).
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String _ageLabel(DateTime birthDate) {
    final days = DateTime.now().difference(birthDate).inDays;
    final months = days ~/ 30;
    final remDays = days % 30;
    return '$months mois — $remDays jours';
  }

  Future<void> toggleSymptom(String symptom) async {
    if (_selectedSymptoms.contains(symptom)) {
      _selectedSymptoms.remove(symptom);
    } else {
      _selectedSymptoms.add(symptom);
    }
    notifyListeners();

    final userId = _userId;
    if (userId == null) return;
    final today = DateTime.now().toIso8601String().split('T').first;
    if (_selectedSymptoms.contains(symptom)) {
      await supabase.from('daily_symptoms').upsert({'user_id': userId, 'symptom': symptom, 'log_date': today});
    } else {
      await supabase.from('daily_symptoms').delete().eq('user_id', userId).eq('symptom', symptom).eq('log_date', today);
    }
  }

  Future<void> addPainEntry({required String location, required String type, required String duration, required int severity}) async {
    final userId = _userId;
    if (userId == null) return;
    await supabase.from('pain_entries').insert({'user_id': userId, 'location': location, 'type': type, 'duration': duration, 'severity': severity});
    await fetchAll();
  }

  Future<void> createBabyProfile({required String name, required DateTime birthDate, required String gender}) async {
    final userId = _userId;
    if (userId == null) throw 'Vous devez être connecté.';
    await supabase.from('baby_profiles').insert({
      'user_id': userId,
      'name': name,
      'birth_date': birthDate.toIso8601String().split('T').first,
      'gender': gender,
    });
    await fetchAll();
  }

  Future<void> createPregnancyInfo({required int week, required String trimester, double? babySizeCm, double? babyWeightKg}) async {
    final userId = _userId;
    if (userId == null) throw 'Vous devez être connecté.';
    await supabase.from('pregnancy_info').insert({
      'user_id': userId,
      'week': week,
      'trimester': trimester,
      'baby_size_cm': babySizeCm,
      'baby_weight_kg': babyWeightKg,
    });
    await fetchAll();
  }
}
