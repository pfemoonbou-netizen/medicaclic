import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_colors.dart';
import '../widgets/primary_button.dart';

class OrderTrackingPage extends StatefulWidget {
  const OrderTrackingPage({super.key});

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  static const _statusOrder = ['pending', 'confirmed', 'shipped', 'delivered'];

  String? _orderId;
  bool _loading = true;
  String? _error;
  RealtimeChannel? _channel;

  String _status = 'pending';
  String _storeName = 'Boutique';
  int _itemCount = 0;
  int _total = 0;
  DateTime? _updatedAt;

  bool get _isTerminalNegative => _status == 'cancelled' || _status == 'refunded';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_orderId == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      _orderId = args?.toString();
      _load();
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _load() async {
    final id = _orderId;
    if (id == null || id.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Commande introuvable.';
      });
      return;
    }
    try {
      final row = await Supabase.instance.client
          .from('orders')
          .select()
          .eq('id', id)
          .single();
      _applyRow(Map<String, dynamic>.from(row));
      _subscribe(id);
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Impossible de charger cette commande.';
        });
      }
    }
  }

  void _applyRow(Map<String, dynamic> row) {
    if (!mounted) return;
    final items = (row['items'] as List?) ?? const [];
    final firstItem = items.isNotEmpty ? Map<String, dynamic>.from(items.first as Map) : null;
    setState(() {
      _status     = (row['status'] as String?) ?? 'pending';
      _storeName  = (firstItem?['store_name'] as String?) ?? 'Boutique';
      _itemCount  = items.length;
      _total      = (row['total'] as num?)?.toInt() ?? 0;
      _updatedAt  = DateTime.tryParse(row['updated_at']?.toString() ?? '');
      _loading    = false;
      _error      = null;
    });
  }

  void _subscribe(String id) {
    _channel?.unsubscribe();
    _channel = Supabase.instance.client
        .channel('order-tracking-$id')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq, column: 'id', value: id),
          callback: (payload) =>
              _applyRow(Map<String, dynamic>.from(payload.newRecord)),
        )
        .subscribe();
  }

  String _shortId(String id) =>
      '#${id.length >= 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase()}';

  String _statusLabel(String s) => switch (s) {
        'pending'   => 'En attente',
        'confirmed' => 'Confirmée',
        'shipped'   => 'Expédiée',
        'delivered' => 'Livrée',
        'cancelled' => 'Annulée',
        'refunded'  => 'Remboursée',
        _           => s,
      };

  Color _statusColor(String s) => switch (s) {
        'delivered' => Colors.green,
        'cancelled' => AppColors.error,
        'refunded'  => AppColors.error,
        _           => AppColors.blue,
      };

  List<_TrackStep> get _steps {
    final idx = _statusOrder.indexOf(_status);
    return [
      const _TrackStep('Commande reçue', 'Votre commande a été enregistrée'),
      _TrackStep('Confirmée', '$_storeName prépare votre colis'),
      const _TrackStep('Expédiée', 'Colis pris en charge par le livreur'),
      _TrackStep(
          'Livrée',
          _status == 'delivered' && _updatedAt != null
              ? 'Colis remis le ${_fmtDate(_updatedAt!)}'
              : 'En route vers votre adresse'),
    ].asMap().entries.map((e) => e.value.copyWith(done: idx >= e.key)).toList();
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6FB),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.nearBlack, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Suivi commande',
            style: GoogleFonts.montserrat(
                color: AppColors.nearBlack,
                fontSize: 18,
                fontWeight: FontWeight.w900)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.blue))
          : _error != null
              ? Center(
                  child: Text(_error!,
                      style: GoogleFonts.montserrat(color: AppColors.gray)))
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Order header card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                        boxShadow: [
                          BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 16,
                              offset: Offset(0, 4))
                        ],
                      ),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Row(children: [
                          Text('Commande ${_shortId(_orderId ?? '')}',
                              style: GoogleFonts.montserrat(
                                  color: AppColors.nearBlack,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _statusColor(_status).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(_statusLabel(_status),
                                style: GoogleFonts.montserrat(
                                    color: _statusColor(_status),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ]),
                        const SizedBox(height: 8),
                        Text(
                            '$_storeName · $_itemCount article${_itemCount > 1 ? "s" : ""} · $_total DA',
                            style: GoogleFonts.montserrat(
                                color: AppColors.gray, fontSize: 12)),
                      ]),
                    ),
                    const SizedBox(height: 24),

                    if (_isTerminalNegative) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(children: [
                          const Icon(Icons.error_outline_rounded,
                              color: AppColors.error),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                                _status == 'cancelled'
                                    ? 'Cette commande a été annulée.'
                                    : 'Cette commande a été remboursée.',
                                style: GoogleFonts.montserrat(
                                    color: AppColors.error,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ]),
                      ),
                    ] else ...[
                      Text('Statut de livraison',
                          style: GoogleFonts.montserrat(
                              color: AppColors.nearBlack,
                              fontSize: 15,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 16),
                      ...List.generate(
                          _steps.length, (i) => _buildStep(_steps[i], i)),
                    ],

                    const SizedBox(height: 24),
                    if (_status == 'delivered')
                      PrimaryButton(
                        label: 'Laisser un avis',
                        onPressed: () => Navigator.pushNamed(
                          context,
                          '/order-feedback',
                          arguments: {
                            'orderId': _orderId,
                            'storeName': _storeName,
                            'orderLabel': 'Commande ${_shortId(_orderId ?? '')}',
                          },
                        ),
                      )
                    else if (!_isTerminalNegative)
                      PrimaryButton(
                        label: 'Contacter le vendeur',
                        onPressed: () => _showPhoneSheet(context),
                      ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => Navigator.pushNamed(context, '/help'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.lightGray),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(45)),
                        minimumSize: const Size(double.infinity, 52),
                      ),
                      child: Text('Signaler un problème',
                          style: GoogleFonts.montserrat(
                              color: AppColors.nearBlack,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
    );
  }

  void _showPhoneSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
                color: AppColors.lightGray,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          Text('Contacter $_storeName',
              style: GoogleFonts.montserrat(
                  color: AppColors.nearBlack,
                  fontSize: 15,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('Appel uniquement — disponible 9h–18h',
              style: GoogleFonts.montserrat(
                  color: AppColors.gray, fontSize: 12)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgGray,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.phone_outlined,
                    color: Colors.green, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Appeler la boutique',
                      style: GoogleFonts.montserrat(
                          color: AppColors.nearBlack,
                          fontSize: 13,
                          fontWeight: FontWeight.w700)),
                  Text('05 XX XX XX XX',
                      style: GoogleFonts.montserrat(
                          color: AppColors.gray, fontSize: 12)),
                ]),
              ),
              const Icon(Icons.arrow_forward_ios,
                  size: 14, color: AppColors.gray),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildStep(_TrackStep step, int index) {
    final isLast = index == _steps.length - 1;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              gradient: step.done
                  ? const LinearGradient(
                      colors: [AppColors.accent, AppColors.blue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight)
                  : null,
              color: step.done ? null : AppColors.lightGray,
              shape: BoxShape.circle,
            ),
            child: step.done
                ? const Icon(Icons.check_rounded, color: AppColors.nearBlack, size: 14)
                : null,
          ),
          if (!isLast)
            Container(
              width: 2,
              height: 40,
              decoration: BoxDecoration(
                gradient: step.done
                    ? const LinearGradient(
                        colors: [AppColors.accent, AppColors.blue],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter)
                    : null,
                color: step.done ? null : AppColors.lightGray,
              ),
            ),
        ]),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step.title,
                      style: GoogleFonts.montserrat(
                          color: step.done
                              ? AppColors.nearBlack
                              : AppColors.grayLight,
                          fontSize: 13,
                          fontWeight: step.done
                              ? FontWeight.w700
                              : FontWeight.w400)),
                  Text(step.sub,
                      style: GoogleFonts.montserrat(
                          color: AppColors.grayLight, fontSize: 11)),
                ]),
          ),
        ),
      ],
    );
  }
}

class _TrackStep {
  final String title;
  final String sub;
  final bool done;
  const _TrackStep(this.title, this.sub, [this.done = false]);

  _TrackStep copyWith({bool? done}) =>
      _TrackStep(title, sub, done ?? this.done);
}
