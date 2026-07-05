import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/supabase_config.dart';
import '../../utils/app_colors.dart';

/// Carte des pharmacies : localise l'utilisateur et affiche les pharmacies
/// les plus proches (données réelles depuis la table `pharmacies`).
class PharmacyMapScreen extends StatefulWidget {
  const PharmacyMapScreen({super.key});

  @override
  State<PharmacyMapScreen> createState() => _PharmacyMapScreenState();
}

class _Pharmacy {
  final String name;
  final String address;
  final String wilaya;
  final String? phone;
  final double lat;
  final double lng;
  final bool isGarde;
  double distanceMeters; // calculée par rapport à l'utilisateur

  _Pharmacy({
    required this.name,
    required this.address,
    required this.wilaya,
    required this.phone,
    required this.lat,
    required this.lng,
    required this.isGarde,
    this.distanceMeters = -1,
  });

  factory _Pharmacy.fromMap(Map<String, dynamic> m) => _Pharmacy(
        name: (m['name'] ?? '') as String,
        address: (m['address'] ?? '') as String,
        wilaya: (m['wilaya'] ?? '') as String,
        phone: m['phone'] as String?,
        lat: (m['lat'] as num).toDouble(),
        lng: (m['lng'] as num).toDouble(),
        isGarde: (m['is_garde'] ?? false) as bool,
      );

  String get distanceLabel {
    if (distanceMeters < 0) return '';
    if (distanceMeters < 1000) return '${distanceMeters.round()} m';
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }
}

class _PharmacyMapScreenState extends State<PharmacyMapScreen> {
  // Centre par défaut : Alger, si la localisation échoue.
  static const LatLng _algerCenter = LatLng(36.7538, 3.0588);

  final MapController _mapController = MapController();
  List<_Pharmacy> _pharmacies = [];
  LatLng? _userLocation;
  bool _loading = true;
  String? _locationNote;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await Future.wait([_loadPharmacies(), _getUserLocation()]);
    _computeDistances();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadPharmacies() async {
    try {
      final data = await supabase.from('pharmacies').select();
      _pharmacies = (data as List).map((e) => _Pharmacy.fromMap(e as Map<String, dynamic>)).toList();
    } catch (_) {
      _pharmacies = [];
    }
  }

  Future<void> _getUserLocation() async {
    try {
      final serviceOn = await Geolocator.isLocationServiceEnabled();
      if (!serviceOn) {
        _locationNote = 'Localisation désactivée — pharmacies d\'Alger affichées.';
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        _locationNote = 'Accès position refusé — pharmacies d\'Alger affichées.';
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      _userLocation = LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      _locationNote = 'Position indisponible — pharmacies d\'Alger affichées.';
    }
  }

  void _computeDistances() {
    final origin = _userLocation ?? _algerCenter;
    for (final p in _pharmacies) {
      p.distanceMeters = Geolocator.distanceBetween(origin.latitude, origin.longitude, p.lat, p.lng);
    }
    _pharmacies.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
  }

  void _focus(_Pharmacy p) {
    _mapController.move(LatLng(p.lat, p.lng), 15);
  }

  Future<void> _call(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final center = _userLocation ?? (_pharmacies.isNotEmpty ? LatLng(_pharmacies.first.lat, _pharmacies.first.lng) : _algerCenter);
    final nearest = _pharmacies.isNotEmpty ? _pharmacies.first : null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Pharmacies proches', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(initialCenter: center, initialZoom: 13),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.medicaclic.app',
                    ),
                    MarkerLayer(
                      markers: [
                        if (_userLocation != null)
                          Marker(
                            point: _userLocation!,
                            width: 40,
                            height: 40,
                            child: const _UserDot(),
                          ),
                        ..._pharmacies.map(
                          (p) => Marker(
                            point: LatLng(p.lat, p.lng),
                            width: 44,
                            height: 44,
                            child: GestureDetector(
                              onTap: () => _focus(p),
                              child: Icon(
                                Icons.local_pharmacy,
                                color: p.isGarde ? Colors.red : AppColors.primary,
                                size: 34,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (_locationNote != null)
                  Positioned(
                    top: 10,
                    left: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(_locationNote!, style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ),
                _bottomSheet(nearest),
              ],
            ),
      floatingActionButton: _userLocation == null
          ? null
          : FloatingActionButton(
              backgroundColor: AppColors.primary,
              onPressed: () => _mapController.move(_userLocation!, 15),
              child: const Icon(Icons.my_location, color: Colors.white),
            ),
    );
  }

  Widget _bottomSheet(_Pharmacy? nearest) {
    return DraggableScrollableSheet(
      initialChildSize: 0.32,
      minChildSize: 0.15,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12)],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 12),
              if (nearest != null) ...[
                const Text('📍 Pharmacie la plus proche', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _nearestCard(nearest),
                const SizedBox(height: 18),
              ],
              const Text('Toutes les pharmacies', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF101522))),
              const SizedBox(height: 8),
              ..._pharmacies.map(_pharmacyTile),
            ],
          ),
        );
      },
    );
  }

  Widget _nearestCard(_Pharmacy p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF18A589), Color(0xFF128273)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
              ),
              if (p.isGarde)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: const Text('De garde', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text('${p.address}, ${p.wilaya}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          Text('À ${p.distanceLabel}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _focus(p),
                  icon: const Icon(Icons.map_outlined, size: 18, color: Colors.white),
                  label: const Text('Voir', style: TextStyle(color: Colors.white)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _call(p.phone),
                  icon: const Icon(Icons.phone, size: 18, color: AppColors.primary),
                  label: const Text('Appeler', style: TextStyle(color: AppColors.primary)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pharmacyTile(_Pharmacy p) {
    return GestureDetector(
      onTap: () => _focus(p),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.local_pharmacy, color: p.isGarde ? Colors.red : AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF101522))),
                  const SizedBox(height: 2),
                  Text('${p.wilaya} • ${p.distanceLabel}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _call(p.phone),
              icon: const Icon(Icons.phone, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserDot extends StatelessWidget {
  const _UserDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.25),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ),
    );
  }
}
