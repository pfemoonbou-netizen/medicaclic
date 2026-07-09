import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/delivery_models.dart';
import '../../services/delivery_service.dart';
import '../../services/user_session.dart';

class ShippingLabelsPage extends StatefulWidget {
  const ShippingLabelsPage({super.key});
  @override
  State<ShippingLabelsPage> createState() => _ShippingLabelsPageState();
}

class _ShippingLabelsPageState extends State<ShippingLabelsPage> {
  static const _bg    = Color(0xFF07080F);
  static const _card  = Color(0xFF0D0F1E);
  static const _bord  = Color(0xFF1C1F35);
  static const _acc   = Color(0xFF7C3AED);
  static const _green = Color(0xFF10E8B0);
  static const _gold  = Color(0xFFFFB800);
  static const _purp  = Color(0xFF9B6CF7);

  List<ShippingLabel> _labels = [];
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
    final list = await DeliveryService.instance.myLabels(_sellerId);
    if (mounted) setState(() { _labels = list; _loading = false; });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _bg,
    body: SafeArea(child: Column(children: [
      _topBar(),
      Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator(color: _acc, strokeWidth: 2))
          : RefreshIndicator(
              onRefresh: _load, color: _acc, backgroundColor: _card,
              child: _labels.isEmpty ? _empty() : _list(),
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
        Text('Étiquettes Colis', style: GoogleFonts.montserrat(
            color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
        Text('${_labels.length} étiquette(s)',
            style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 11)),
      ])),
      GestureDetector(
        onTap: _load,
        child: Container(padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(color: _bord, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 18)),
      ),
    ]),
  );

  Widget _empty() => ListView(children: [
    SizedBox(height: MediaQuery.of(context).size.height * 0.32),
    const Icon(Icons.label_off_rounded, color: Colors.white24, size: 52),
    const SizedBox(height: 12),
    Text('Aucune étiquette générée', textAlign: TextAlign.center,
        style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 14)),
    const SizedBox(height: 8),
    Text('Les étiquettes sont générées automatiquement\nlors de la confirmation des commandes',
        textAlign: TextAlign.center,
        style: GoogleFonts.montserrat(color: Colors.white24, fontSize: 12)),
  ]);

  Widget _list() => ListView.separated(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
    itemCount: _labels.length,
    separatorBuilder: (_, __) => const SizedBox(height: 12),
    itemBuilder: (_, i) => _labelCard(_labels[i]),
  );

  Widget _labelCard(ShippingLabel label) {
    final printed = label.printedAt != null;
    return Container(
      decoration: BoxDecoration(
        color: _card, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: printed ? _bord : _acc.withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        // ── QR + info ────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _qrPlaceholder(label.trackingNumber),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(label.trackingNumber, style: GoogleFonts.montserrat(
                    color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900,
                    letterSpacing: 1.2))),
                GestureDetector(
                  onTap: () => _copyTracking(label.trackingNumber),
                  child: const Icon(Icons.copy_rounded, color: Colors.white38, size: 16),
                ),
              ]),
              const SizedBox(height: 6),
              if (label.groupId != null)
                _infoRow('Groupe', label.groupId!.substring(0, 8).toUpperCase()),
              if (label.barcode != null) _infoRow('Barcode', label.barcode!),
              _infoRow('Créé le', _fmtDate(label.createdAt)),
              if (printed) _infoRow('Imprimé le', _fmtDate(label.printedAt!)),
            ])),
          ]),
        ),

        // ── Barcode visuel ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: _barcodeWidget(label.trackingNumber),
        ),

        // ── Status + actions ─────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _bord.withValues(alpha: 0.4),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: printed ? _green.withValues(alpha: 0.1) : _gold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: printed
                    ? _green.withValues(alpha: 0.3) : _gold.withValues(alpha: 0.3)),
              ),
              child: Text(printed ? '✓ Imprimée' : '⏳ Non imprimée',
                  style: GoogleFonts.montserrat(
                      color: printed ? _green : _gold,
                      fontSize: 10, fontWeight: FontWeight.w800)),
            ),
            const Spacer(),
            if (!printed)
              _actionBtn('🖨 Imprimer', _purp, () => _markPrinted(label)),
            const SizedBox(width: 8),
            _actionBtn('📋 Copier', _acc, () => _copyTracking(label.trackingNumber)),
          ]),
        ),
      ]),
    );
  }

  Widget _qrPlaceholder(String tracking) => Container(
    width: 72, height: 72,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Padding(
      padding: const EdgeInsets.all(4),
      child: CustomPaint(
        painter: _QrPatternPainter(tracking),
      ),
    ),
  );

  Widget _barcodeWidget(String tracking) => Container(
    height: 44,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
    ),
    child: CustomPaint(
      painter: _BarcodePainter(tracking),
      child: Align(alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Text(tracking, style: const TextStyle(
              color: Colors.black, fontSize: 8, letterSpacing: 1.5,
              fontWeight: FontWeight.w700)),
        ),
      ),
    ),
  );

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 3),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 72, child: Text(label, style: GoogleFonts.montserrat(
          color: Colors.white24, fontSize: 10))),
      Expanded(child: Text(value, style: GoogleFonts.montserrat(
          color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700),
          maxLines: 2, overflow: TextOverflow.ellipsis)),
    ]),
  );

  Widget _actionBtn(String label, Color color, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: GoogleFonts.montserrat(
          color: color, fontSize: 11, fontWeight: FontWeight.w800)),
    ),
  );

  Future<void> _markPrinted(ShippingLabel label) async {
    await DeliveryService.instance.markLabelPrinted(label.id);
    _snack('✅ Étiquette marquée comme imprimée');
    _load();
  }

  void _copyTracking(String tracking) {
    Clipboard.setData(ClipboardData(text: tracking));
    _snack('Numéro de suivi copié: $tracking');
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg, style: GoogleFonts.montserrat(fontSize: 12)),
        backgroundColor: _card, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12)));
}

class _QrPatternPainter extends CustomPainter {
  final String seed;
  const _QrPatternPainter(this.seed);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black;
    final cellSize = size.width / 7;
    final hash = seed.hashCode.abs();
    for (int r = 0; r < 7; r++) {
      for (int c = 0; c < 7; c++) {
        final idx = r * 7 + c;
        if (_isFinderPattern(r, c) || ((hash >> idx) & 1) == 1) {
          canvas.drawRect(Rect.fromLTWH(c * cellSize, r * cellSize, cellSize - 1, cellSize - 1), paint);
        }
      }
    }
  }

  bool _isFinderPattern(int r, int c) =>
      (r < 3 && c < 3) || (r < 3 && c > 3) || (r > 3 && c < 3);

  @override
  bool shouldRepaint(_QrPatternPainter old) => old.seed != seed;
}

class _BarcodePainter extends CustomPainter {
  final String seed;
  const _BarcodePainter(this.seed);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black;
    final barWidth = size.width / 60;
    final hash = seed.hashCode.abs();
    for (int i = 0; i < 60; i++) {
      if ((hash >> (i % 32)) & 1 == 1) {
        canvas.drawRect(Rect.fromLTWH(i * barWidth, 2, barWidth * 0.7, size.height - 14), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_BarcodePainter old) => old.seed != seed;
}
