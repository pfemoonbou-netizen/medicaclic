import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/delivery_models.dart';
import '../../services/delivery_service.dart';
import '../../services/user_session.dart';

class PickupSchedulePage extends StatefulWidget {
  const PickupSchedulePage({super.key});
  @override
  State<PickupSchedulePage> createState() => _PickupSchedulePageState();
}

class _PickupSchedulePageState extends State<PickupSchedulePage> {
  static const _bg   = Color(0xFF07080F);
  static const _card = Color(0xFF0D0F1E);
  static const _bord = Color(0xFF1C1F35);
  static const _acc  = Color(0xFF7C3AED);
  static const _green= Color(0xFF10E8B0);
  static const _gold = Color(0xFFFFB800);
  static const _red  = Color(0xFFF04040);

  List<PickupRequest> _pickups = [];
  bool _loading = true;
  late String _sellerId;

  @override
  void initState() {
    super.initState();
    _sellerId = UserSession.instance.current.id;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await DeliveryService.instance.myPickups(_sellerId);
    if (mounted) setState(() { _pickups = list; _loading = false; });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _bg,
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _showScheduleSheet,
      backgroundColor: _acc,
      icon: const Icon(Icons.add_rounded, color: Colors.white),
      label: Text('Planifier', style: GoogleFonts.montserrat(
          color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
    ),
    body: SafeArea(child: Column(children: [
      _topBar(),
      Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator(color: _acc, strokeWidth: 2))
          : RefreshIndicator(
              onRefresh: _load, color: _acc, backgroundColor: _card,
              child: _pickups.isEmpty ? _empty() : _list(),
            )),
    ])),
  );

  Widget _topBar() => Container(
    color: _card,
    padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
    child: Row(children: [
      GestureDetector(onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 18)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Planning Ramassage', style: GoogleFonts.montserrat(
            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
        Text('${_pickups.length} ramassage(s) planifié(s)',
            style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 11)),
      ])),
    ]),
  );

  Widget _empty() => ListView(children: [
    SizedBox(height: MediaQuery.of(context).size.height * 0.3),
    const Icon(Icons.calendar_today_rounded, color: Colors.white24, size: 52),
    const SizedBox(height: 12),
    Text('Aucun ramassage planifié', textAlign: TextAlign.center,
        style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 14)),
    const SizedBox(height: 8),
    Text('Appuyez sur "Planifier" pour ajouter un créneau',
        textAlign: TextAlign.center,
        style: GoogleFonts.montserrat(color: Colors.white24, fontSize: 12)),
  ]);

  Widget _list() => ListView.separated(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
    itemCount: _pickups.length,
    separatorBuilder: (_, __) => const SizedBox(height: 10),
    itemBuilder: (_, i) => _pickupCard(_pickups[i]),
  );

  Widget _pickupCard(PickupRequest p) {
    final cfg = _statusCfg(p.status);
    return Container(
      decoration: BoxDecoration(
        color: _card, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (cfg['color'] as Color).withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: (cfg['color'] as Color).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(cfg['icon'] as IconData, color: cfg['color'] as Color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_fmtDate(p.pickupDate), style: GoogleFonts.montserrat(
                  color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
              Text('${p.pickupFrom} — ${p.pickupTo}',
                  style: GoogleFonts.montserrat(color: Colors.white54, fontSize: 12)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: (cfg['color'] as Color).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: (cfg['color'] as Color).withValues(alpha: 0.3)),
              ),
              child: Text(cfg['label'] as String, style: GoogleFonts.montserrat(
                  color: cfg['color'] as Color, fontSize: 10, fontWeight: FontWeight.w800)),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: Wrap(spacing: 6, runSpacing: 6, children: [
            _chip('📍 ${p.address}', Colors.white38),
            _chip('📦 ${p.packagesCount} colis', _acc),
            if (p.driverName != null) _chip('🚴 ${p.driverName}', _green),
          ]),
        ),
        if (p.status == PickupStatus.scheduled)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: GestureDetector(
              onTap: () => _cancel(p),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _red.withValues(alpha: 0.2)),
                ),
                child: Text('Annuler ce ramassage', textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(color: _red, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _chip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(7)),
    child: Text(label, style: GoogleFonts.montserrat(color: color, fontSize: 10)),
  );

  Future<void> _cancel(PickupRequest p) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      backgroundColor: _card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text('Annuler le ramassage ?', style: GoogleFonts.montserrat(
          color: Colors.white, fontWeight: FontWeight.w800)),
      content: Text('Ce ramassage sera annulé définitivement.',
          style: GoogleFonts.montserrat(color: Colors.white54, fontSize: 13)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false),
            child: Text('Non', style: GoogleFonts.montserrat(color: Colors.white54))),
        TextButton(onPressed: () => Navigator.pop(context, true),
            child: Text('Oui, annuler', style: GoogleFonts.montserrat(
                color: _red, fontWeight: FontWeight.w800))),
      ],
    ));
    if (ok == true) {
      await DeliveryService.instance.cancelPickup(p.id);
      _load();
    }
  }

  void _showScheduleSheet() {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    String fromTime = '09:00';
    String toTime   = '18:00';
    int packages    = 1;
    final addrCtrl  = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(builder: (ctx, setS) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20,
            20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: _bord, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('Planifier un ramassage', style: GoogleFonts.montserrat(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () async {
              final d = await showDatePicker(context: ctx,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)));
              if (d != null) setS(() => selectedDate = d);
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _bord)),
              child: Row(children: [
                const Icon(Icons.calendar_today_rounded, color: _acc, size: 18),
                const SizedBox(width: 10),
                Text(_fmtDate(selectedDate), style: GoogleFonts.montserrat(
                    color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _timeBtn(ctx, 'De', fromTime, (t) => setS(() => fromTime = t))),
            const SizedBox(width: 10),
            Expanded(child: _timeBtn(ctx, 'À', toTime, (t) => setS(() => toTime = t))),
          ]),
          const SizedBox(height: 10),
          TextField(
            controller: addrCtrl,
            style: GoogleFonts.montserrat(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Adresse de ramassage',
              hintStyle: GoogleFonts.montserrat(color: Colors.white24, fontSize: 12),
              filled: true, fillColor: _bg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _bord)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _bord)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _acc)),
            ),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Text('Nombre de colis:', style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 13)),
            const Spacer(),
            IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.white54),
                onPressed: () { if (packages > 1) setS(() => packages--); }),
            Text('$packages', style: GoogleFonts.montserrat(color: Colors.white, fontSize: 16,
                fontWeight: FontWeight.w800)),
            IconButton(icon: const Icon(Icons.add_circle_outline, color: _acc),
                onPressed: () => setS(() => packages++)),
          ]),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () async {
              if (addrCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              await DeliveryService.instance.schedulePickup(
                sellerId: _sellerId,
                date: selectedDate,
                fromTime: fromTime,
                toTime: toTime,
                address: addrCtrl.text.trim(),
                packagesCount: packages,
              );
              _load();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_acc, Color(0xFF9B6CF7)]),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Text('Confirmer le ramassage', textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(color: Colors.white, fontSize: 13,
                      fontWeight: FontWeight.w800)),
            ),
          ),
        ]),
      )),
    );
  }

  Widget _timeBtn(BuildContext ctx, String label, String value, ValueChanged<String> onPick) =>
    GestureDetector(
      onTap: () async {
        final t = await showTimePicker(context: ctx,
            initialTime: TimeOfDay(
              hour: int.parse(value.split(':')[0]),
              minute: int.parse(value.split(':')[1]),
            ));
        if (t != null) {
          onPick('${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _bord)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.access_time_rounded, color: Colors.white38, size: 16),
          const SizedBox(width: 6),
          Text('$label: $value', style: GoogleFonts.montserrat(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
      ),
    );

  Map<String, dynamic> _statusCfg(PickupStatus s) => {
    PickupStatus.scheduled:      {'icon': Icons.schedule_rounded,         'color': _gold,  'label': 'Planifié'},
    PickupStatus.confirmed:      {'icon': Icons.check_circle_outlined,    'color': _green, 'label': 'Confirmé'},
    PickupStatus.driverAssigned: {'icon': Icons.person_pin_circle_rounded,'color': _acc,   'label': 'Livreur assigné'},
    PickupStatus.enRoute:        {'icon': Icons.directions_bike_rounded,  'color': _acc,   'label': 'En route'},
    PickupStatus.completed:      {'icon': Icons.done_all_rounded,         'color': _green, 'label': 'Complété'},
    PickupStatus.failed:         {'icon': Icons.error_outline_rounded,    'color': _red,   'label': 'Échoué'},
    PickupStatus.cancelled:      {'icon': Icons.cancel_outlined,          'color': Colors.white38, 'label': 'Annulé'},
  }[s]!;

  String _fmtDate(DateTime d) =>
      '${_day(d.weekday)} ${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';

  String _day(int w) => const ['Lun','Mar','Mer','Jeu','Ven','Sam','Dim'][w - 1];
}
