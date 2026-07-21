import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_care_theme.dart';
import '../../../providers/home_care_provider.dart';

class BookingSheet extends StatefulWidget {
  final CareProvider provider;
  const BookingSheet({super.key, required this.provider});

  @override
  State<BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<BookingSheet> {
  int _step = 0;
  bool _submitting = false;
  String? _submitError;
  static const _serviceTypes = ['Consultation', 'Urgence', 'Injection', 'Pansement', 'Prise de sang', 'Suivi'];
  static const _timeSlots = ['09:00', '11:00', '14:00', '16:00', '18:00', '20:00'];

  String _serviceType = 'Consultation';
  final _dateController = TextEditingController();
  String? _timeSlot;
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();

  static const _stepTitles = ['Type de soin', 'Coordonnées', 'Confirmation'];

  @override
  void dispose() {
    _dateController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool get _canContinue {
    if (_step == 0) return _dateController.text.trim().isNotEmpty && _timeSlot != null;
    if (_step == 1) return _addressController.text.trim().isNotEmpty;
    return true;
  }

  Future<void> _next() async {
    if (_step < 2) {
      setState(() => _step++);
      return;
    }
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      await context.read<HomeCareProvider>().createBooking(
            providerId: widget.provider.id,
            serviceType: _serviceType,
            bookingDate: _dateController.text.trim(),
            timeSlot: _timeSlot!,
            address: _addressController.text.trim(),
            note: _noteController.text.trim(),
          );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Réservation envoyée à ${widget.provider.name} pour le ${_dateController.text} à $_timeSlot.')),
      );
    } catch (e) {
      setState(() {
        _submitting = false;
        _submitError = e.toString();
      });
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.provider;
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(color: HomeCareTheme.card, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: HomeCareTheme.border, borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Réserver une visite', style: TextStyle(color: HomeCareTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('${_stepTitles[_step]} — Étape ${_step + 1}/3', style: const TextStyle(color: HomeCareTheme.textFaint, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.close, color: HomeCareTheme.textSecondary), onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: List.generate(3, (i) {
                    return Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                        height: 4,
                        decoration: BoxDecoration(color: i <= _step ? HomeCareTheme.accent : HomeCareTheme.border, borderRadius: BorderRadius.circular(2)),
                      ),
                    );
                  }),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: HomeCareTheme.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: HomeCareTheme.border)),
                      child: Row(
                        children: [
                          ClipOval(
                            child: Image.network(
                              p.photoUrl,
                              width: 52,
                              height: 52,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => CircleAvatar(radius: 26, backgroundColor: HomeCareTheme.accent.withValues(alpha: 0.15), child: Text(p.name.split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join(), style: const TextStyle(color: HomeCareTheme.accent, fontWeight: FontWeight.bold, fontSize: 12))),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name, style: const TextStyle(color: HomeCareTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                                Text(p.specialty, style: const TextStyle(color: HomeCareTheme.textFaint, fontSize: 11)),
                                Text('${p.etaRange} · ${p.address}', style: const TextStyle(color: HomeCareTheme.textFaint, fontSize: 11)),
                              ],
                            ),
                          ),
                          Text('${p.pricePerVisit}\nDA', style: const TextStyle(color: HomeCareTheme.accent, fontSize: 13, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_step == 0) ..._buildStepOne(),
                    if (_step == 1) ..._buildStepTwo(),
                    if (_step == 2) ..._buildStepThree(p),
                    if (_submitError != null) ...[
                      const SizedBox(height: 12),
                      Text(_submitError!, style: const TextStyle(color: HomeCareTheme.red, fontSize: 12)),
                    ],
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
                        child: OutlinedButton(
                          onPressed: _submitting ? null : _back,
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: HomeCareTheme.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)), padding: const EdgeInsets.symmetric(vertical: 14)),
                          child: Text(_step == 0 ? 'Annuler' : 'Précédent', style: const TextStyle(color: HomeCareTheme.textSecondary)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: (_canContinue && !_submitting) ? _next : null,
                          style: ElevatedButton.styleFrom(backgroundColor: HomeCareTheme.accent, disabledBackgroundColor: HomeCareTheme.border, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)), padding: const EdgeInsets.symmetric(vertical: 14)),
                          child: _submitting
                              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                              : Text(_step == 2 ? 'Confirmer' : 'Suivant →', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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

  List<Widget> _buildStepOne() {
    return [
      const Text('Type de service', style: TextStyle(color: HomeCareTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _serviceTypes.map((t) {
          final active = t == _serviceType;
          return GestureDetector(
            onTap: () => setState(() => _serviceType = t),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: active ? HomeCareTheme.accent.withValues(alpha: 0.15) : Colors.transparent, borderRadius: BorderRadius.circular(20), border: Border.all(color: active ? HomeCareTheme.accent : HomeCareTheme.border)),
              child: Text(t, style: TextStyle(color: active ? HomeCareTheme.accent : HomeCareTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 20),
      const Text('Date souhaitée', style: TextStyle(color: HomeCareTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      TextField(
        controller: _dateController,
        style: const TextStyle(color: HomeCareTheme.textPrimary),
        decoration: InputDecoration(
          hintText: 'ex: 20/01/2025',
          hintStyle: const TextStyle(color: HomeCareTheme.textFaint),
          prefixIcon: const Icon(Icons.calendar_today_outlined, color: HomeCareTheme.textFaint, size: 18),
          filled: true,
          fillColor: HomeCareTheme.background,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: HomeCareTheme.border)),
        ),
      ),
      const SizedBox(height: 20),
      const Text('Heure préférée', style: TextStyle(color: HomeCareTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _timeSlots.map((t) {
          final active = t == _timeSlot;
          return GestureDetector(
            onTap: () => setState(() => _timeSlot = t),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: active ? HomeCareTheme.accent : Colors.transparent, borderRadius: BorderRadius.circular(20), border: Border.all(color: active ? HomeCareTheme.accent : HomeCareTheme.border)),
              child: Text(t, style: TextStyle(color: active ? Colors.white : HomeCareTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          );
        }).toList(),
      ),
    ];
  }

  List<Widget> _buildStepTwo() {
    return [
      const Text('Adresse complète', style: TextStyle(color: HomeCareTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      TextField(
        controller: _addressController,
        maxLines: 2,
        style: const TextStyle(color: HomeCareTheme.textPrimary),
        decoration: InputDecoration(
          hintText: 'Quartier, rue, repère...',
          hintStyle: const TextStyle(color: HomeCareTheme.textFaint),
          prefixIcon: const Icon(Icons.location_on_outlined, color: HomeCareTheme.textFaint, size: 18),
          filled: true,
          fillColor: HomeCareTheme.background,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: HomeCareTheme.border)),
        ),
      ),
      const SizedBox(height: 20),
      const Text('Note pour le prestataire (optionnel)', style: TextStyle(color: HomeCareTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      TextField(
        controller: _noteController,
        maxLines: 3,
        style: const TextStyle(color: HomeCareTheme.textPrimary),
        decoration: InputDecoration(
          hintText: 'Précisez vos symptômes, étage, code d\'accès...',
          hintStyle: const TextStyle(color: HomeCareTheme.textFaint),
          filled: true,
          fillColor: HomeCareTheme.background,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: HomeCareTheme.border)),
        ),
      ),
    ];
  }

  List<Widget> _buildStepThree(CareProvider p) {
    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: HomeCareTheme.textFaint, fontSize: 13)),
              Flexible(child: Text(value, style: const TextStyle(color: HomeCareTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
            ],
          ),
        );
    return [
      const Text('Récapitulatif', style: TextStyle(color: HomeCareTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
      const SizedBox(height: 14),
      row('Prestataire', p.name),
      row('Service', _serviceType),
      row('Date', _dateController.text),
      row('Heure', _timeSlot ?? ''),
      row('Adresse', _addressController.text),
      const Divider(color: HomeCareTheme.border),
      row('Total estimé', '${p.pricePerVisit} DA'),
    ];
  }
}
