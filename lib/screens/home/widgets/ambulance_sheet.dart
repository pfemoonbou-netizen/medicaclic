import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../utils/app_colors.dart';

const _kAmbulanceNumber = '14';
const _kDefaultLocation = LatLng(36.7538, 3.0588); // Alger, fallback si la localisation est indisponible

class AmbulanceSheet extends StatefulWidget {
  const AmbulanceSheet({super.key});

  @override
  State<AmbulanceSheet> createState() => _AmbulanceSheetState();
}

class _AmbulanceSheetState extends State<AmbulanceSheet> {
  LatLng? _userLocation;
  String? _address;
  bool _loading = true;
  String? _error;

  static const _nearbyAmbulances = [
    {'name': 'Protection Civile - Centre', 'distanceKm': 1.2, 'offset': LatLng(0.01, 0.008)},
    {'name': 'Ambulance Hôpital Mustapha', 'distanceKm': 2.4, 'offset': LatLng(-0.015, 0.012)},
  ];

  @override
  void initState() {
    super.initState();
    _resolveLocation();
  }

  Future<void> _resolveLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'Service de localisation désactivé';

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw 'Permission de localisation refusée';
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 8)),
      );
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _loading = false;
      });
      _resolveAddress(position.latitude, position.longitude);
    } catch (e) {
      setState(() {
        _userLocation = _kDefaultLocation;
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _resolveAddress(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return;
      final p = placemarks.first;
      final parts = [p.street, p.subLocality, p.locality].where((s) => s != null && s.trim().isNotEmpty).toList();
      if (mounted) setState(() => _address = parts.join(', '));
    } catch (_) {
      // La reverse-geocoding peut echouer (pas de reseau, service indisponible) :
      // on garde juste les coordonnees GPS dans ce cas.
    }
  }

  void _callAmbulance() {
    launchUrl(Uri(scheme: 'tel', path: _kAmbulanceNumber));
  }

  void _shareLocation() {
    final loc = _userLocation ?? _kDefaultLocation;
    final mapsUrl = 'https://maps.google.com/?q=${loc.latitude},${loc.longitude}';
    final text = StringBuffer('🚑 Ma position actuelle\n\n');
    if (_address != null && _address!.isNotEmpty) text.writeln('📍 $_address\n');
    text.writeln('Latitude : ${loc.latitude.toStringAsFixed(6)}');
    text.writeln('Longitude : ${loc.longitude.toStringAsFixed(6)}');
    text.writeln('\n$mapsUrl');
    SharePlus.instance.share(ShareParams(text: text.toString()));
  }

  @override
  Widget build(BuildContext context) {
    final center = _userLocation ?? _kDefaultLocation;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.12), shape: BoxShape.circle),
                      child: const Icon(Icons.emergency, color: AppColors.danger, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ambulance à proximité', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('Protection civile — 14', style: TextStyle(fontSize: 12, color: AppColors.lightGray)),
                        ],
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : ListView(
                        controller: scrollController,
                        padding: EdgeInsets.zero,
                        children: [
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline, size: 16, color: AppColors.danger),
                                    const SizedBox(width: 8),
                                    const Expanded(child: Text('Position précise indisponible — position approximative affichée (Alger).', style: TextStyle(fontSize: 11, color: AppColors.danger))),
                                  ],
                                ),
                              ),
                            ),
                          SizedBox(
                            height: 260,
                            child: ClipRRect(
                              borderRadius: BorderRadius.zero,
                              child: FlutterMap(
                                options: MapOptions(initialCenter: center, initialZoom: 13.5),
                                children: [
                                  TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.medicaclic.app'),
                                  MarkerLayer(
                                    markers: [
                                      Marker(point: center, width: 40, height: 40, child: const Icon(Icons.person_pin_circle, color: AppColors.primary, size: 36)),
                                      for (final amb in _nearbyAmbulances)
                                        Marker(
                                          point: LatLng(center.latitude + (amb['offset'] as LatLng).latitude, center.longitude + (amb['offset'] as LatLng).longitude),
                                          width: 36,
                                          height: 36,
                                          child: const Icon(Icons.local_hospital, color: AppColors.danger, size: 30),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Votre position actuelle', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.lightGray)),
                                  const SizedBox(height: 8),
                                  if (_address != null && _address!.isNotEmpty)
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('📍 ', style: TextStyle(fontSize: 14)),
                                        Expanded(child: Text(_address!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                                      ],
                                    ),
                                  const SizedBox(height: 6),
                                  Text('Latitude : ${center.latitude.toStringAsFixed(6)}', style: const TextStyle(fontSize: 12, color: AppColors.lightGray)),
                                  Text('Longitude : ${center.longitude.toStringAsFixed(6)}', style: const TextStyle(fontSize: 12, color: AppColors.lightGray)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Services à proximité', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 10),
                                ..._nearbyAmbulances.map((amb) => Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.local_hospital, color: AppColors.danger, size: 22),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(amb['name'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                                Text('${amb['distanceKm']} km', style: const TextStyle(fontSize: 11, color: AppColors.lightGray)),
                                              ],
                                            ),
                                          ),
                                          IconButton(icon: const Icon(Icons.call, color: AppColors.primary), onPressed: _callAmbulance),
                                        ],
                                      ),
                                    )),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _callAmbulance,
                          icon: const Icon(Icons.call, color: Colors.white),
                          label: const Text('Appeler le 14', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32))),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _shareLocation,
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: const BorderSide(color: AppColors.primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32))),
                          child: const Icon(Icons.share, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
